library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


library axi_FPGA_configuration_controller;
use axi_FPGA_configuration_controller.all;

entity clock_divider is
    Generic
		(
		ORIGINAL_CLK_PERIOD_PS : integer := 10000;
        Slow_Clock_Period_PS : integer := 20000
		);
	port
		(
		clk : in std_logic;
		rst : in std_logic;
		slow_clk : out std_logic;
		slow_rst : out std_logic
		);
end clock_divider;

architecture Behavioral of clock_divider is

constant clock_divider_value : integer := ((Slow_Clock_Period_PS) / ORIGINAL_CLK_PERIOD_PS);
constant half_clock_divider_value : integer := clock_divider_value / 2;

signal clock_divider_counter : integer range 0 to clock_divider_value := 1;
signal slow_clk_internal : std_logic := '0';
signal slow_rst_internal_stage_1 : std_logic := '1';
signal slow_rst_internal_stage_2 : std_logic := '1';

begin

clock_divider : process (clk)
begin
	if clk'event and clk = '1' then
		if rst = '1' then
			clock_divider_counter <= 1;
			slow_clk_internal <= '0';
		elsif clock_divider_counter >= half_clock_divider_value then
			clock_divider_counter <= 1;
			slow_clk_internal <= not slow_clk_internal;
		else
			clock_divider_counter <= clock_divider_counter + 1;
		end if;	
	end if;
end process;

slow_clk <= slow_clk_internal;
slow_rst <= slow_rst_internal_stage_2 or slow_rst_internal_stage_1;


reset_pulse_extension : process (rst, slow_clk_internal)
begin
	if rst = '1' then
		slow_rst_internal_stage_1 <= '1';
		slow_rst_internal_stage_2 <= '1';
	elsif slow_clk_internal'event and slow_clk_internal = '1' then
		slow_rst_internal_stage_1 <= '0';
		slow_rst_internal_stage_2 <= slow_rst_internal_stage_1;
	end if;
end process;


end Behavioral;
