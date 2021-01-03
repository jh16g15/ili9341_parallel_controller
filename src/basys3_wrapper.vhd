----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01.01.2021 17:51:55
-- Design Name: 
-- Module Name: basys3_wrapper - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity basys3_wrapper is
    Port ( 
        -- 100MHz oscillator
        CLK : in std_logic;
        -- basic IO
        SW  : in std_logic_vector(15 downto 0);
        LED : out std_logic_vector(15 downto 0);
        BTN : in std_logic_vector(4 downto 0);
        
        -- Display uses PMODs B (Data) and C (Control) on the Basys 3
        JB : out std_logic_vector(7 downto 0);
        JC : inout std_logic_vector(7 downto 0)
        
    );
end basys3_wrapper;

architecture Behavioral of basys3_wrapper is
    signal sys_reset : std_logic;
    signal ext_reset : std_logic;
    signal locked : std_logic;
    signal sysclk : std_logic;
    
    signal ili9341_CS_N        : std_logic;
    signal ili9341_BLC         : std_logic;
    signal ili9341_RESET_N     : std_logic;
    signal ili9341_WR          : std_logic;
    signal ili9341_RS          : std_logic;
    signal ili9341_RD          : std_logic;
    signal ili9341_VSYNC       : std_logic;
    signal ili9341_FMARK       : std_logic;
        
    signal ili9341_DATA        : std_logic_vector(7 downto 0);
    
    component clk_wiz_0 
    port (   
 
        clk_out25  : out std_logic;
        reset      : in  std_logic ;      
        locked     : out std_logic ;      
        
        clk_in1    : in  std_logic   
    );
    end component;
    
begin

    ext_reset <= BTN(4);
    
    sys_reset <= ext_reset or (not locked);

    -- set PMOD B to 8-bit DATA bus
    JB <= ili9341_DATA;
    
    -- control outputs
    JC(0) <= ili9341_CS_N;
    JC(1) <= SW(0); -- ili9341_BLC; -- temporary until we figure out how to use
    JC(2) <= ili9341_RESET_N;
    JC(3) <= ili9341_WR;
    JC(4) <= ili9341_RS;
    JC(5) <= ili9341_RD;
    JC(6) <= ili9341_VSYNC;
    -- control inputs
    ili9341_FMARK <= JC(7);
    

u_clk_wiz : clk_wiz_0  
	port map(    
        clk_out25  => sysclk,
        
        reset      => ext_reset,     
        locked     => locked,     
        clk_in1    => CLK 
    );

u_ili9341_top : entity work.ili9341_top
    generic map (
        SYSCLK_FREQ => 25000000,
        DEBUG_ILAS => false
    )
    port map (
        -- for framebuffer read port and ILI9341
        sysclk          => sysclk,
        reset_in        => sys_reset,
        
        -- unused Framebuffer Write port (for microblaze or other BRAM controller)
        framebuffer_w_clk_in          => '0',
        framebuffer_w_enable_in       => '0',
        framebuffer_w_write_enable_in => '0',
        framebuffer_w_addr_in         => (others => '0'),
        framebuffer_w_data_in         => (others => '0'),
        
        ili9341_CS_N    => ili9341_CS_N   ,   
        ili9341_BLC     => ili9341_BLC    ,  
        ili9341_RESET_N => ili9341_RESET_N,
        ili9341_WR      => ili9341_WR     ,
        ili9341_RS      => ili9341_RS     ,     
        ili9341_RD      => ili9341_RD     ,     
        ili9341_VSYNC   => ili9341_VSYNC  ,  
        ili9341_FMARK   => ili9341_FMARK  ,
        
        ili9341_DATA    => ili9341_DATA
        
    );
    


end Behavioral;
