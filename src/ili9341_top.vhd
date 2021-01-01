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
        DEBUG_ILAS : boolean := false
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

begin

u_ili9341_ctrl : entity work.ili9341_ctrl
    generic map (
        SYSCLK_FREQ => 25_000_000
    )
    port map (
        sysclk_in   => SYSCLK,
        reset_in    => reset_in,
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


end architecture;
    
    
