library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


entity ili9341_top is 
    generic(
        DEBUG_ILAS : boolean := false;
        
        SIM_DELAY_REDUCTION_FACTOR : integer := 1 -- for synthesis, no delay reduction
    );
    port(
        SYSCLK  : in std_logic;

        reset_in : in std_logic;
        
        -- ILI9341 control signals
        
        -- Control PMOD  JC
        -- CHECK PINOUTs AGAINST THE PCB!!!
        
        ili9341_CS_N        : out std_logic;
        ili9341_BLC         : out std_logic;
        ili9341_RESET_N     : out std_logic;
        ili9341_WR          : out std_logic;
        ili9341_RS          : out std_logic;
        ili9341_RD          : out std_logic;
        ili9341_VSYNC       : out std_logic;
        ili9341_FMARK       : in std_logic;
        
        
        -- Data PMOD JB
        -- CHECK PINOUTs AGAINST THE PCB!!!
        -- (technically these are I/O but we shouldn't need to read anything from the device)
        ili9341_DATA : out std_logic_vector(7 downto 0)
       
    );
    
end entity ili9341_top;

architecture Behavioral of ili9341_top is
--    constant FRAMEBUFFER_DEPTH : integer := 256 * 320;  -- padded Width * Height (81920)
    constant FRAMEBUFFER_DEPTH : integer := 240 * 320;  -- Image Width * Height (76800)
    
    constant FRAMEBUFFER_ADDR_W : integer := 17;
    
    constant BITS_PER_PIXEL : integer := 8;
    constant PIXELS_PER_WORD : integer := 1;
    constant FRAMEBUFFER_READ_SIZE : integer := BITS_PER_PIXEL * PIXELS_PER_WORD;

    signal framebuffer_clkb : std_logic;
    signal framebuffer_enb  : std_logic;
--    signal framebuffer_addra : std_logic_vector(FRAMEBUFFER_ADDR_W-1 downto 0);
    signal framebuffer_addrb : std_logic_vector(FRAMEBUFFER_ADDR_W-1 downto 0);
--    signal framebuffer_dia  : std_logic_vector(FRAMEBUFFER_READ_SIZE-1 downto 0);
    signal framebuffer_dob  : std_logic_vector(FRAMEBUFFER_READ_SIZE-1 downto 0);

    -- mixed language support requires component declarations
    component simple_dual_two_clock_bram is 
    generic(
        ADDR_W         : integer;
        DATA_W         : integer;
        DEPTH          : integer;
        USE_INIT_FILE  : std_logic;
	    INIT_FILE_NAME : string
    );
    port(
        clka   : in    std_logic;
        clkb   : in    std_logic;
        ena    : in    std_logic;
        enb    : in    std_logic;
        wea    : in    std_logic;
        addra  : in    std_logic_vector(ADDR_W-1 downto 0);
        addrb  : in    std_logic_vector(ADDR_W-1 downto 0);
        dia    : in    std_logic_vector(DATA_W-1 downto 0);
        dob    : out   std_logic_vector(DATA_W-1 downto 0)
    );
    end component simple_dual_two_clock_bram;
    
    
    
    
begin

u_ili9341_ctrl : entity work.ili9341_ctrl
    generic map (
        SYSCLK_FREQ => 25_000_000,
        SIM_DELAY_REDUCTION_FACTOR => SIM_DELAY_REDUCTION_FACTOR,   -- reduce the 120ms delay to 12us to reduce sim time
        FRAMEBUFFER_ADDR_W => FRAMEBUFFER_ADDR_W,
        FRAMEBUFFER_READ_SIZE => FRAMEBUFFER_READ_SIZE,
        FRAMEBUFFER_DEPTH => FRAMEBUFFER_DEPTH
    )
    port map (
        sysclk_in   => SYSCLK,
        reset_in    => reset_in,
        
        framebuffer_clkb_out    => framebuffer_clkb ,
        framebuffer_enb_out     => framebuffer_enb  ,
        framebuffer_addrb_out   => framebuffer_addrb,
        framebuffer_dob_in      => framebuffer_dob  ,
        
        ili9341_CS_N_OUT    => ili9341_CS_N   ,   
        ili9341_BLC_OUT     => ili9341_BLC    ,  
        ili9341_RESET_N_OUT => ili9341_RESET_N,
        ili9341_WR_OUT      => ili9341_WR     ,
        ili9341_RS_OUT      => ili9341_RS     ,     
        ili9341_RD_OUT      => ili9341_RD     ,     
        ili9341_VSYNC_OUT   => ili9341_VSYNC  ,  
        ili9341_FMARK_IN    => ili9341_FMARK  ,
        
        ili9341_DATA_OUT    => ili9341_DATA
        
        
    );
    -- system verilog for simpler file IO
    -- uses component declaration above to tell us what the port types are
u_framebuffer : simple_dual_two_clock_bram
    generic map (
        ADDR_W => FRAMEBUFFER_ADDR_W,
        DATA_W => FRAMEBUFFER_READ_SIZE,
        DEPTH => FRAMEBUFFER_DEPTH,
        USE_INIT_FILE => '1',
        INIT_FILE_NAME => "D:/Documents/vivado/ili9341_parallel_controller/resources/hex/KAT_iron_240x320.hex"
    )
    port map (
        clka => '0', 
        clkb => framebuffer_clkb,
        ena => '0',
        enb => framebuffer_enb,
        wea => '0', 
        addra => (others => '0'), 
        addrb => framebuffer_addrb, 
        dia => (others => '0'),
        dob => framebuffer_dob 
    );
    

end architecture;
    
    
