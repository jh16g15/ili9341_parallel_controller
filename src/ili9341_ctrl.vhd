----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 31.12.2020 19:00:33
-- Design Name: 
-- Module Name: ili9341_ctrl - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ili9341_ctrl is
generic (
    SYSCLK_FREQ             : integer := 25000000; -- 25 MHz 
    SIM_DELAY_REDUCTION_FACTOR : integer := 1;      -- 1 for disabled
    FRAMEBUFFER_ADDR_W      : integer := 17;
    FRAMEBUFFER_READ_SIZE   : integer := 8;
    FRAMEBUFFER_DEPTH       : integer := 76800
);
Port (
    
    sysclk_in               : in std_logic;  -- 25 MHz (40 ns) Write cycle (lowtime+hightime of WR strobe) 66ns (over 2 clock cycles)
    reset_in                : in std_logic;
    
    -- framebuffer read port
    framebuffer_read_clk_out    : out std_logic;
    framebuffer_read_en_out     : out std_logic := '0';
    framebuffer_read_addr_out   : out std_logic_vector(FRAMEBUFFER_ADDR_W-1 downto 0);
    framebuffer_read_data_in    : in  std_logic_vector(FRAMEBUFFER_READ_SIZE-1 downto 0);
    
    -- physical pins for ILI9341
    ili9341_CS_N_OUT        : out std_logic;    -- Active Low Chip Select
    ili9341_BLC_OUT         : out std_logic;    -- Backlight Control  (active high)
    ili9341_RESET_N_OUT     : out std_logic;    -- active low reset
    ili9341_WR_OUT          : out std_logic;    -- write strobe
    ili9341_RS_OUT          : out std_logic;    -- Command/Data select        
    ili9341_RD_OUT          : out std_logic;    -- read strobe
    ili9341_VSYNC_OUT       : out std_logic;    -- control framerate (if enabled)
    ili9341_FMARK_IN       : in std_logic;      -- receive pulse when frame writing complete (if enabled)
    ili9341_DATA_OUT : out std_logic_vector(7 downto 0) -- (technically these are I/O but we shouldn't need to read anything from the device)
);    
end ili9341_ctrl;

architecture Behavioral of ili9341_ctrl is

    type t_state is (HARDWARE_RESET, LEAVE_HW_RESET, LEAVE_SLEEP_MODE, WAIT_TO_EXIT_SLEEP_MODE, INIT, ACTIVE, IDLE, DATA_R, DATA_G, DATA_B, SEND_WORD_1, SEND_WORD_2 );
    
    signal state : t_state := HARDWARE_RESET;
    
    -- subroutine control 
    signal return_state : t_state;
--    signal send_cmd_or_data : std_logic;
    signal word_to_send : std_logic_vector(8+4-1 downto 0); -- cmd/data tacked on the top of the data byte
--    signal data_count_to_send : integer;
    
    -- number of pixels written in INIT_MEM
    constant INIT_NUM_PIXELS : integer := 0;
    constant INIT_MEM_ITEMS : integer := 2 + 8 + 7 + 1 + 3*INIT_NUM_PIXELS;
    
    type t_init_mem is array (0 to INIT_MEM_ITEMS-1) of std_logic_vector(11 downto 0); -- top char is command/data select
    
    constant ILI9341_INIT_MEM : t_init_mem := (
        
        -- exit sleep mode (2 words)
        x"C_28", -- CMD display OFF 
        x"C_11", -- CMD sleep mode EXIT
        
        -- add delay of 120 ms here
        
        -- init display (8 words)
        x"C_34",  -- CMD Tearing Effect Line OFF (TE/FMARK)
        x"C_38",  -- CMD IDLE mode OFF    
        x"C_13",  -- CMD Normal Display Mode ON
        x"C_20",  -- CMD Display Inversion OFF
        x"C_3A",  -- CMD COLMOD Pixel Format Set
        x"D_66",  -- DAT 16 Bits Per Pixel(0x55)  18 Bits per Pixel (0x66)
        x"C_36",  -- CMD Memory Access Control
        x"D_48",  -- DAT Column Address Order, BGR
        
        -- normally we would wipe the screen here (write all to black)    
               
        -- resume setup (7 words)
        x"C_B1",  -- CMD Frame Rate Control Normal
        x"D_00",  -- DAT 70Hz 
        x"D_1B",  -- DAT 70Hz
        x"C_B3",  -- CMD Frame Rate Control Partial
        x"D_00",  -- DAT 70Hz 
        x"D_1B",  -- DAT 70Hz
        x"C_29",  -- CMD Display ON 
        
        -- start memory write: (Originally clear screen, looping through all pixels 240x320 and setting to BLACK)
        x"C_2C"   -- CMD Memory Write 
        
    );
    

    -- time delays (sysclk-adaptive)
    constant SYSCLK_PERIOD_NS : integer := 1000000000 / SYSCLK_FREQ;   -- eg 40ns for 25MHz
    constant DELAY_10_US : integer := 10 * 1000 / SYSCLK_PERIOD_NS;
    constant DELAY_120_MS : integer := 120 * 1000000 / SYSCLK_PERIOD_NS / SIM_DELAY_REDUCTION_FACTOR;

    signal delay_counter : integer := 0;
    signal init_mem_counter : integer := 0;
    
    signal framebuffer_counter : integer := 0;
    
    -- 8 bits
    
    --  GGGRRRBB
    signal pixel_data : std_logic_vector(FRAMEBUFFER_READ_SIZE-1 downto 0);
    
    -- 16 bit colour RGB 5-6-5 
    
    -- or
    
    -- 18 bit colour RGB 6-6-6 
    signal red_data : std_logic_vector(7 downto 0);
    signal green_data : std_logic_vector(7 downto 0);
    signal blue_data : std_logic_vector(7 downto 0);
    
    attribute mark_debug : boolean;
    attribute mark_debug of state : signal is true;
--    attribute mark_debug of send_cmd_or_data : signal is true;
    attribute mark_debug of word_to_send : signal is true;
--    attribute mark_debug of data_count_to_send : signal is true;
    attribute mark_debug of delay_counter : signal is true;
    attribute mark_debug of init_mem_counter : signal is true;
    attribute mark_debug of framebuffer_counter : signal is true;
    
    attribute mark_debug of reset_in: signal is true;
    attribute mark_debug of framebuffer_read_en_out   : signal is true;
    attribute mark_debug of framebuffer_read_addr_out : signal is true;
    attribute mark_debug of framebuffer_read_data_in  : signal is true;
    
    
begin

-- send the clock out for the read side RAM port
framebuffer_read_clk_out <= sysclk_in;


framebuffer_read_addr_out <= std_logic_vector(to_unsigned(framebuffer_counter, FRAMEBUFFER_ADDR_W));


--OLD
-- simple colour conversion from 8 bit 3-3-2 GRB to 16 bit 5-6-5 RGB
-- create the missing LSBs with the MSB to get reasonable results 
--red_data <= pixel_data(4 downto 2)& pixel_data(4)& pixel_data(4); -- pad from 3 bits to 5
--green_data <= pixel_data(7 downto 5) & pixel_data(7) & pixel_data(7) & pixel_data(7);   -- pad from 3 bit to 6
--blue_data <= pixel_data(1 downto 0) & pixel_data(1) & pixel_data(1) & pixel_data(1);    -- pad from 2 bit to 5

--NEW
-- simple colour conversion from 8 bit 3-3-2 GRB to 18 bit 6-6-6 RGB (top 2 bits are 0 padded)
-- create the missing LSBs with the MSB to get reasonable results 
red_data    <= pixel_data(4 downto 2) & pixel_data(4) & pixel_data(4) & pixel_data(4) & b"00"; -- MSB pad from 3 bits to 6, then add b"00" for unused bits
green_data  <= pixel_data(7 downto 5) & pixel_data(7) & pixel_data(7) & pixel_data(7) & b"00";   -- MSB pad from 3 bit to 6, then add b"00" for unused bits
blue_data   <= pixel_data(1 downto 0) & pixel_data(1) & pixel_data(1) & pixel_data(1) & pixel_data(1) & b"00";    -- MSB pad from 2 bit to 6, then add b"00" for unused bits




p_state_machine : process(sysclk_in) is

begin
    if rising_edge(sysclk_in) then
        if reset_in = '1' then
            state <= HARDWARE_RESET;
            delay_counter <= 0;
            init_mem_counter <= 0;
            framebuffer_read_en_out <= '0'; -- disable reading from the framebuffer until we have initialised the display
        else
            case(state) is
                when HARDWARE_RESET => 
                    ili9341_BLC_OUT <= '0';     -- disable backlight 
                    ili9341_RESET_N_OUT <= '0';   -- assert active low reset
                    ili9341_CS_N_OUT <= '0';    -- assert active low Chip Select (we will just leave this asserted)
                    ili9341_WR_OUT <= '1';          -- put Write Strobe High
                    ili9341_RD_OUT <= '1';          -- put Read Strobe High
                    ili9341_RS_OUT <= '1';          -- put Data/Cmd High ('1' for Data, '0' for Command)
                    
                    ili9341_VSYNC_OUT <= '1';       -- set VSYNC to default
                    
                    init_mem_counter <= 0;      -- reset counter through init_mem
                    
                    if delay_counter = DELAY_10_US then
                        state <= LEAVE_HW_RESET;
                        delay_counter <= 0;
                    else    
                        delay_counter <= delay_counter + 1;
                    end if;
                
                when LEAVE_HW_RESET => 
                
                    ili9341_RESET_N_OUT <= '1';     -- deassert active low reset
                
                    -- now wait for us to come out of Reset
                    if delay_counter = DELAY_120_MS then
                        state <= LEAVE_SLEEP_MODE;
                        delay_counter <= 0;
                        init_mem_counter <= 0;
                        
                    else    
                        delay_counter <= delay_counter + 1;
                    end if;
                
                when LEAVE_SLEEP_MODE => 
                
                    -- send 2 commands to exit sleep mode
                    
                    state <= SEND_WORD_1;
                    
                    -- take this out of the memory
                    word_to_send <= ILI9341_INIT_MEM(init_mem_counter);
                    
                    -- increment ready for the next time
                    init_mem_counter <= init_mem_counter + 1;
                    
                    -- first pass
                    if init_mem_counter = 0 then
                        return_state <= LEAVE_SLEEP_MODE;
                    end if;
                    -- second (and final) pass
                    if init_mem_counter = 1 then 
                        return_state <= WAIT_TO_EXIT_SLEEP_MODE;
                    end if;
                    
                    
                    
                when WAIT_TO_EXIT_SLEEP_MODE => 
                    -- then wait to come out of sleep mode 
                    if delay_counter = DELAY_120_MS then
                        state <= INIT;
                        delay_counter <= 0;
                    else    
                        delay_counter <= delay_counter + 1;
                    end if;
                
                when INIT =>
                    -- send more commands to finish initialisation
                    
                    state <= SEND_WORD_1;
                    
                    -- take this out of the memory
                    word_to_send <= ILI9341_INIT_MEM(init_mem_counter);
                    
                    -- increment ready for the next time
                    init_mem_counter <= init_mem_counter + 1;
                    
                    
                    -- last pass
                    if init_mem_counter = INIT_MEM_ITEMS -1 then
                        return_state <= ACTIVE;   -- initialisation finshed
                        
                        framebuffer_read_en_out <= '1'; -- enable framebuffer read
                        
                        framebuffer_counter <= 0; -- setup read of first pixel
                        
                    else 
                        return_state <= INIT;   -- continue sending commands
                    end if;
                
                when ACTIVE => 
                
                    state <= DATA_R;
                    
                    -- wrap round
                    if framebuffer_counter = FRAMEBUFFER_DEPTH-1 then
                        framebuffer_counter <= 0;
                    else
                        framebuffer_counter <= framebuffer_counter + 1; -- increment address for next time
                    end if;
                    
                    
                    -- read pixel value from framebuffer, colour conversion happens combinationally above
                    -- We use 18-bit colour for now, as the transfers are a bit nicer
                    pixel_data <= framebuffer_read_data_in; 
                

                when DATA_R => 
                    state <= SEND_WORD_1;
                    word_to_send <= x"D" & red_data;
                    return_state <= DATA_G;
                when DATA_G =>
                    state <= SEND_WORD_1;
                    word_to_send <= x"D" & green_data;
                    return_state <= DATA_B;
                when DATA_B =>  
                    state <= SEND_WORD_1;
                    word_to_send <= x"D" & blue_data;
                    return_state <= ACTIVE;
                
                
                -- "subroutine" to send Command Words
                when SEND_WORD_1 =>
                    -- interpret top 4 bits as the type of word we are sending
                    case word_to_send(11 downto 8) is 
                        when x"C" =>  
                            ili9341_RS_OUT <= '0';              -- set bus to "command"
                        when x"D" => 
                            ili9341_RS_OUT <= '1';              -- set bus to "data"
                        when others =>          -- error condition
                            ili9341_RS_OUT <= '1';              -- set bus to "data"
                    end case;
                    
                    ili9341_DATA_OUT <= word_to_send(7 downto 0);   -- put the data word on the bus
                    ili9341_WR_OUT <= '0';              -- send WRITE Strobe low
                    
                    state <= SEND_WORD_2;                -- leave for 1 cycle
                    
                when SEND_WORD_2 =>
                
                    ili9341_WR_OUT <= '1';              -- rising edge of WRITE strobe to cue ili9341 to accept data
                    
                    state <= return_state;
                
                when others => 
                    state <= HARDWARE_RESET;
                    delay_counter <= 0;
                    init_mem_counter <= 0;
            end case;
        end if; 
    end if;
end process;



end Behavioral;
