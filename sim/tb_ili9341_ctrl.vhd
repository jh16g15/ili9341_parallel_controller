----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01.01.2021 17:15:37
-- Design Name: 
-- Module Name: tb_ili9341_ctrl - tb
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

entity tb_ili9341_ctrl is
--  Port ( );
end tb_ili9341_ctrl;

architecture tb of tb_ili9341_ctrl is

    constant CLK_PERIOD : time := 40 ns;    -- 25 MHz

    signal sysclk : std_logic := '0';
    signal reset : std_logic := '1';
    
    signal ili9341_CS_N        : std_logic;
    signal ili9341_BLC         : std_logic;
    signal ili9341_RESET_N     : std_logic;
    signal ili9341_WR          : std_logic;
    signal ili9341_RS          : std_logic;
    signal ili9341_RD          : std_logic;
    signal ili9341_VSYNC       : std_logic;
    signal ili9341_FMARK       : std_logic;
    
    signal ili9341_DATA_OUT     : std_logic_vector(7 downto 0);
    
begin

sysclk <= not sysclk after CLK_PERIOD/2;

reset <= '0' after CLK_PERIOD * 2;

u_ili9341_top : entity work.ili9341_top
generic map (
    SYSCLK_FREQ             => 25000000, -- 25 MHz  
    SIM_DELAY_REDUCTION_FACTOR => 10000   -- reduce the 120ms delay to 12us to reduce sim time
)
Port map (
    
    sysclk                  => sysclk,  -- 25 MHz (40 ns) Write cycle (lowtime+hightime of WR strobe) 66ns (over 2 clock cycles)
    reset_in                => reset,  
    
    -- unused Framebuffer Write port (for microblaze or other BRAM controller)
    framebuffer_w_clk_in          => '0',
    framebuffer_w_enable_in       => '0',
    framebuffer_w_write_enable_in => '0',
    framebuffer_w_addr_in         => (others => '0'),
    framebuffer_w_data_in         => (others => '0'),
                
    -- physical pins
    ili9341_CS_N       => ili9341_CS_N   ,  -- Active Low Chip Select
    ili9341_BLC        => ili9341_BLC    ,  -- Backlight Control  (active high)
    ili9341_RESET_N    => ili9341_RESET_N,  -- active low reset
    ili9341_WR         => ili9341_WR     ,  -- write strobe
    ili9341_RS         => ili9341_RS     ,  -- Command/Data select        
    ili9341_RD         => ili9341_RD     ,  -- read strobe
    ili9341_VSYNC      => ili9341_VSYNC ,  -- control framerate (if enabled)
    ili9341_FMARK      => ili9341_FMARK   ,  -- receive pulse when frame writing complete (if enabled)
    -- (technically these are I/O but we shouldn't need to read anything from the device)
    ili9341_DATA        => ili9341_DATA_OUT
);    



end tb;
