library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library axi_FPGA_configuration_controller;
use axi_FPGA_configuration_controller.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity FPGA_configuration_controller is
	Generic
        (
        clock_period_ns             : integer := 10;
        CONFIG_CLK_FREQ_HZ          : integer := 20000000;
        CONFIG_DATA_WIDTH           : integer range 1 to 32 := 1;
        AES_SECURE_CONFIG           : integer := 0;
        CONFIG_DATA_IS_BIT_SWAPPED  : integer := 1;
        NUMBER_OF_FPGAS_IN_CHAIN    : integer := 1
        );
    Port
        (
        clk                         : in  STD_LOGIC;
        rst                         : in  STD_LOGIC;
        go                          : in  STD_LOGIC;
        abort                       : in  STD_LOGIC;
        done                        : out STD_LOGIC;
        running                     : out STD_LOGIC;
        error                       : out STD_LOGIC;
        aborted                     : out STD_LOGIC;
        abort_status                : out STD_LOGIC_VECTOR(31 downto 0);
        chain_ID_to_configure       : in  STD_LOGIC_VECTOR(4 downto 0);
        bitstream_length_bits       : in  STD_LOGIC_VECTOR(31 downto 0);
        data_in                     : in  STD_LOGIC_VECTOR(31 downto 0);
        data_in_valid               : in  STD_LOGIC;
        data_fifo_full              : out STD_LOGIC;
        data_fifo_almost_full       : out STD_LOGIC;
        data_fifo_empty             : out STD_LOGIC;
        total_bits_sent             : out STD_LOGIC_VECTOR(31 downto 0);
        CONFIG_CCLK                 : out STD_LOGIC;
        CONFIG_DATA                 : inout STD_LOGIC_VECTOR(31 downto 0);
        CONFIG_CSI_B                : out STD_LOGIC_VECTOR(NUMBER_OF_FPGAS_IN_CHAIN-1 downto 0);
        CONFIG_RDWR_B               : out STD_LOGIC;
        CONFIG_PROGB                : inout STD_LOGIC;
        CONFIG_INITB                : inout STD_LOGIC;
        CONFIG_DONE                 : inout STD_LOGIC
        );
end FPGA_configuration_controller;


architecture Behavioral of FPGA_configuration_controller is

-- Implement a function in VHDL to generate an intentional failure if the user chooses an invalid config data width 
function generate_data_width_error (WIDTH : integer) return boolean is
    variable ReturnBool: boolean;
    variable DATA_WIDTH_TEMP: integer;
    begin
        DATA_WIDTH_TEMP := WIDTH;
        case AES_SECURE_CONFIG is
            when 0 => 
                case DATA_WIDTH_TEMP is
                    when 1|8|16|32 =>
                        ReturnBool := TRUE;
                    when others =>
                        assert 0 = DATA_WIDTH_TEMP
                        report "** Invalid Generic value for 'CONFIG_DATA_WIDTH' (Can only be 1, 8, 16, or 32) **"
                        severity FAILURE;
                        ReturnBool := FALSE;
                end case;
            when others =>
                case DATA_WIDTH_TEMP is
                    when 1|8 =>
                        ReturnBool := TRUE;
                    when others =>
                        assert 0 = DATA_WIDTH_TEMP
                        report "** Invalid Generic value for 'CONFIG_DATA_WIDTH' (Can only be 1 or 8 when using secure AES bitstreams) **"
                        severity FAILURE;
                        ReturnBool := FALSE;
                end case;
        end case;
        return ReturnBool;
    end generate_data_width_error;

component clock_divider is
    Generic
		(
		ORIGINAL_CLK_PERIOD_PS : integer := 10000;
        Slow_Clock_Period_PS : integer := 20000
		);
	port
		(
		clk : in  STD_logic;
		rst : in  STD_logic;
		slow_clk : out std_logic;
		slow_rst : out std_logic
		);
end component;

component config_data_FIFO IS
    PORT
        (
        rst : IN STD_LOGIC;
        wr_clk : IN STD_LOGIC;
        rd_clk : IN STD_LOGIC;
        din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        wr_en : IN STD_LOGIC;
        rd_en : IN STD_LOGIC;
        dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        full : OUT STD_LOGIC;
        empty : OUT STD_LOGIC;
        prog_full : OUT STD_LOGIC
        );
END component;



constant clock_period_ps : integer := clock_period_ns * 1000;
constant configuration_clock_period_PS : integer := 40000;
constant configuration_clock_period_NS : integer := configuration_clock_period_PS / 1000;

subtype counter_type is integer range 0 to 64;

signal configuration_clk : std_logic;
signal configuration_rst : std_logic;
signal fifo_reset : std_logic;
signal counter : counter_type;
signal reset_counter : std_logic := '0';
signal enable_counter : std_logic := '0';
signal bitstream_size_counter : integer;
signal reset_bitstream_size_counter : std_logic := '0';
signal enable_bitstream_size_counter : std_logic := '0';
signal capture_abort_status_word : std_logic;
signal width_check_OK : boolean;
signal data_from_fifo : std_logic_vector(31 downto 0);
signal fifo_data_register : std_logic_vector(31 downto 0);
signal fifo_data_register_bitswapped : std_logic_vector(31 downto 0);
signal fifo_read_enable : std_logic;
signal data_fifo_empty_internal : std_logic;
signal generate_CCLK : std_logic;
signal abort_status_internal : std_logic_vector(31 downto 0);


type main_fsm_type is (reset, reset_fifo, idle, assert_progb, wait_for_initb, inital_delay, send_config_data, wait_for_data, startup_sequence, error_detected, send_abort_request, capture_abort_status, abort_complete, finished);
signal current_state, next_state : main_fsm_type := reset;


begin

-- Automated data width checking
width_check_OK <= generate_data_width_error(CONFIG_DATA_WIDTH);

CONFIG_CCLK <= configuration_clk;
total_bits_sent <= std_logic_vector(to_unsigned(bitstream_size_counter, 32));
data_fifo_empty <= data_fifo_empty_internal;

state_machine_update : process (configuration_clk)
begin
    if configuration_rst = '1' then
        current_state <= reset;
	elsif rising_edge(configuration_clk) then
        current_state <= next_state;
	end if;
end process;

counter_process : process (configuration_clk)
begin
    if rising_edge(configuration_clk) then
        if reset_counter = '1' then
            counter <= 0;
        elsif enable_counter = '1' then
            if counter < counter_type'HIGH then
                counter <= counter + 1;
            end if;
        end if;
    end if;
end process;

bitstream_size_counter_process : process (configuration_clk)
begin
    if rising_edge(configuration_clk) then
        if reset_bitstream_size_counter = '1' then
            bitstream_size_counter <= 0;
        elsif enable_bitstream_size_counter = '1' then
            bitstream_size_counter <= bitstream_size_counter + CONFIG_DATA_WIDTH;
        end if;
    end if;
end process;

SELECT_MAP_MODE : if (CONFIG_DATA_WIDTH > 1) generate
    abort_status_capture_process : process (configuration_clk, counter, capture_abort_status_word)
    begin
        if rising_edge(configuration_clk) then
            if configuration_rst = '1' then
                abort_status_internal <= (others => '0');
            else
                if capture_abort_status_word = '1' then 
                    case counter is
                        when 0 => abort_status_internal(7 downto 0) <= CONFIG_DATA(7 downto 0);
                        when 1 => abort_status_internal(15 downto 8) <= CONFIG_DATA(7 downto 0);
                        when 2 => abort_status_internal(23 downto 16) <= CONFIG_DATA(7 downto 0);
                        when 3 => abort_status_internal(31 downto 24) <= CONFIG_DATA(7 downto 0);
                        when others => NULL;
                    end case;
                end if;
            end if;
        end if;
    end process;
end generate SELECT_MAP_MODE;

SERIAL_MODE : if (CONFIG_DATA_WIDTH = 1) generate
    abort_status_internal <= (others => '0');
end generate SERIAL_MODE;


fifo_data_register_registers : process (configuration_clk, configuration_rst)
begin
    if rising_edge(configuration_clk) then
        if configuration_rst = '1' then
            fifo_data_register <= (others => '0');
            fifo_data_register_bitswapped <= (others => '0');
        elsif fifo_read_enable = '1' then 
            case data_fifo_empty_internal is
                when '0' => 
                    fifo_data_register <= data_from_fifo;
                    for byte_index in 0 to 3 loop
                        for bit_index in 0 to 7 loop
                            fifo_data_register_bitswapped((byte_index*8)+bit_index) <= data_from_fifo(((3-byte_index)*8)+7-bit_index);
                        end loop;
                    end loop;
                when others => 
                    fifo_data_register <= (others => '0');
                    fifo_data_register_bitswapped <= (others => '0');
            end case;
        end if;
    end if;
end process;

state_machine_decisions : process ( current_state, counter, go, abort, counter, CONFIG_INITB, CONFIG_DONE, CONFIG_PROGB, fifo_data_register,
                                    fifo_data_register_bitswapped, chain_ID_to_configure, bitstream_length_bits, bitstream_size_counter,
                                    data_fifo_empty_internal
                                  )
begin
    next_state <= reset;
    fifo_reset <= '0';
    reset_counter <= '0';
    enable_counter <= '0';
    reset_bitstream_size_counter <= '0';
    enable_bitstream_size_counter <= '0';
    fifo_read_enable <= '0';
    capture_abort_status_word <= '0';
    generate_CCLK <= '0';
    done <= '0';
    error <= '0';
    aborted <= '0';
    CONFIG_DATA <= (others => 'Z');
    CONFIG_CSI_B <= (others => '1');
    CONFIG_RDWR_B <= '0';
    CONFIG_PROGB <= 'Z';
    CONFIG_INITB <= 'Z';
    CONFIG_DONE <= 'Z';
    running <= '1';
    abort_status <= (others => '0');
    

	case current_state is
		when reset =>
            next_state <= reset_fifo;
			reset_bitstream_size_counter <= '1';
            reset_counter <= '1';
            running <= '0';

		when reset_fifo =>
            next_state <= reset_fifo;
			fifo_reset <= '1';
			reset_bitstream_size_counter <= '1';
            running <= '0';
            if counter > 10 then 
                next_state <= idle;
    			reset_counter <= '1';
            else
                enable_counter <= '1';
            end if;

		when idle =>
            next_state <= idle;
            running <= '0';
            if go = '1' then
                next_state <= assert_progb;
            end if;
            
		when assert_progb =>
            next_state <= wait_for_initb;
            CONFIG_PROGB <= '0';

		when wait_for_initb =>
            next_state <= wait_for_initb;
            if CONFIG_PROGB = '0' then
                next_state <= reset;
            elsif CONFIG_INITB /= '0' then
                enable_counter <= '1';
                if counter > 6 then
                    next_state <= send_config_data;
                    CONFIG_CSI_B(to_integer(unsigned(chain_ID_to_configure))) <= '0';
                    enable_counter <= '0';
                    reset_counter <= '1';
                end if;
            end if;

		when wait_for_data => 
		    next_state <= wait_for_data;
		    CONFIG_DATA <= (others => '0');
            if abort = '1' then
                next_state <= send_abort_request;
                reset_counter <= '1';
		    elsif data_fifo_empty_internal = '0' then
              fifo_read_enable <= '1';
		      next_state <= send_config_data;
            end if;
            
		when send_config_data =>
            next_state <= send_config_data;
            if CONFIG_PROGB = '0' then
                next_state <= reset;
            elsif CONFIG_INITB = '0' then
                next_state <= error_detected;
            elsif abort = '1' and CONFIG_DATA_WIDTH > 1 then
                next_state <= send_abort_request;
                reset_counter <= '1';
            else
                enable_bitstream_size_counter <= '1';
                case CONFIG_DATA_WIDTH is
                    when 1 => 
                        enable_counter <= '1';
                        case CONFIG_DATA_IS_BIT_SWAPPED is
                            when 0 => CONFIG_DATA(0) <= fifo_data_register(counter);
                            when 1 => CONFIG_DATA(0) <= fifo_data_register_bitswapped(counter);
                        end case;
                        if counter >= 31 then
                            reset_counter <= '1';
                            if data_fifo_empty_internal = '1' then
                                next_state <= error_detected;
                                reset_counter <= '1';
                            else
                                fifo_read_enable <= '1';
                            end if;
                        end if;
                        
                    when 8 => 
                        CONFIG_RDWR_B <= '0';            
                        CONFIG_CSI_B(to_integer(unsigned(chain_ID_to_configure))) <= '0';
                        enable_counter <= '1';
                        CONFIG_DATA <= (others => '0');
                        case CONFIG_DATA_IS_BIT_SWAPPED is
                            when 0 =>
                                case counter is
                                    when 0 => CONFIG_DATA(7 downto 0) <= fifo_data_register(31 downto 24);
                                    when 1 => CONFIG_DATA(7 downto 0) <= fifo_data_register(23 downto 16);
                                    when 2 => CONFIG_DATA(7 downto 0) <= fifo_data_register(15 downto 8);
                                    when 3 => CONFIG_DATA(7 downto 0) <= fifo_data_register(7 downto 0);
                                    when others => CONFIG_DATA <= (others => '-');
                                end case;
                            when others =>
                                case counter is
                                    when 0 => CONFIG_DATA(7 downto 0) <= fifo_data_register_bitswapped(31 downto 24);
                                    when 1 => CONFIG_DATA(7 downto 0) <= fifo_data_register_bitswapped(23 downto 16);
                                    when 2 => CONFIG_DATA(7 downto 0) <= fifo_data_register_bitswapped(15 downto 8);
                                    when 3 => CONFIG_DATA(7 downto 0) <= fifo_data_register_bitswapped(7 downto 0);
                                    when others => CONFIG_DATA <= (others => '-');
                                end case;
                        end case;
                        if counter >= 3 then 
                            reset_counter <= '1';
                            if data_fifo_empty_internal = '1' then
                                next_state <= wait_for_data;
                            else
                                fifo_read_enable <= '1';
                            end if;
                        end if;

                    when 16 => 
                        enable_counter <= '1';
                        CONFIG_RDWR_B <= '0';            
                        CONFIG_CSI_B(to_integer(unsigned(chain_ID_to_configure))) <= '0';
                        CONFIG_DATA <= (others => '0');
                        case CONFIG_DATA_IS_BIT_SWAPPED is
                            when 0 =>
                                case counter is
                                    when 0 => CONFIG_DATA(15 downto 0) <= fifo_data_register(31 downto 16);
                                    when 1 => CONFIG_DATA(15 downto 0) <= fifo_data_register(15 downto 0);
                                    when others => CONFIG_DATA <= (others => '-');
                                end case;
                            when 1 =>
                                case counter is
                                    when 0 => CONFIG_DATA(15 downto 0) <= fifo_data_register_bitswapped(31 downto 16);
                                    when 1 => CONFIG_DATA(15 downto 0) <= fifo_data_register_bitswapped(15 downto 0);
                                    when others => CONFIG_DATA <= (others => '-');
                                end case;
                        end case;
                        if counter >= 1 then 
                            reset_counter <= '1';
                            if data_fifo_empty_internal = '1' then
                                next_state <= wait_for_data;
                            else
                                fifo_read_enable <= '1';
                            end if;
                        end if;

                    when 32 => 
                        CONFIG_RDWR_B <= '0';            
                        CONFIG_CSI_B(to_integer(unsigned(chain_ID_to_configure))) <= '0';
                        if data_fifo_empty_internal = '1' then
                            next_state <= wait_for_data;
                        else
                            fifo_read_enable <= '1';
                        end if;
                        case CONFIG_DATA_IS_BIT_SWAPPED is
                            when 0 => CONFIG_DATA <= fifo_data_register;
                            when others => CONFIG_DATA <= fifo_data_register_bitswapped;
                        end case;

                    when others => 
                        next_state <= error_detected;
                end case;
                if (bitstream_size_counter > (to_integer(unsigned(bitstream_length_bits)))) then
                    reset_counter <= '1';
                    next_state <= startup_sequence;
                end if;
            end if;
    
        when startup_sequence => 
            next_state <= startup_sequence;
            enable_counter <= '1';
            CONFIG_CSI_B(to_integer(unsigned(chain_ID_to_configure))) <= '0';
            CONFIG_DATA <= (others => '0');
            if CONFIG_INITB = '0' then
                next_state <= error_detected;
            elsif counter >= 64 then
                reset_counter <= '1';
                next_state <= finished;
            end if;
                   
        when send_abort_request => 
            enable_counter <= '1';
            next_state <= send_abort_request;
            CONFIG_DATA <= (others => 'Z');
            case counter is 
                when 0 =>
                    CONFIG_RDWR_B <= '0';            
                    CONFIG_CSI_B(to_integer(unsigned(chain_ID_to_configure))) <= '0';
                when others =>
                    CONFIG_RDWR_B <= '1';            
                    CONFIG_CSI_B(to_integer(unsigned(chain_ID_to_configure))) <= '0';
                    next_state <= capture_abort_status;
                    reset_counter <= '1';
            end case;
            
        when capture_abort_status => 
            enable_counter <= '1';
            capture_abort_status_word <= '1';
            next_state <= capture_abort_status;
            CONFIG_DATA <= (others => 'Z');
            CONFIG_RDWR_B <= '1';            
            CONFIG_CSI_B(to_integer(unsigned(chain_ID_to_configure))) <= '0';
            if counter >= 3 then 
                reset_counter <= '1';
                enable_counter <= '0';
                next_state <= abort_complete;
            end if;
            
        when finished => 
            next_state <= finished;
            reset_counter <= '1';
 			reset_bitstream_size_counter <= '1';
            done <= '1';
            running <= '0';
            if go = '0' then
                next_state <= idle;
            end if;

        when abort_complete => 
            next_state <= abort_complete;
            reset_counter <= '1';
 			reset_bitstream_size_counter <= '1';
            aborted <= '1';
            abort_status <= abort_status_internal;
            running <= '0';
            if go = '0' and abort = '0' then
                next_state <= idle;
            end if;

        when error_detected => 
            next_state <= error_detected;
            enable_counter <= '1';
 			reset_bitstream_size_counter <= '1';
            done <= '1';
            error <= '1';
            CONFIG_INITB <= '0';
            if counter < 10 then
                CONFIG_PROGB <= '0';
            else 
                enable_counter <= '0';
                CONFIG_PROGB <= 'Z';
            end if;
            running <= '0';
            if go = '0' then
                next_state <= idle;
            end if;

		when others  =>
    		next_state <= reset;
            running <= '0';
	end case;
end process;


clock_divider_instance : clock_divider
	GENERIC MAP
		(
		ORIGINAL_CLK_PERIOD_PS => clock_period_ps,
        Slow_Clock_Period_PS => configuration_clock_period_PS
		)
	PORT MAP
		(
		clk => clk,
		rst => rst,
		slow_clk => configuration_clk,
		slow_rst => configuration_rst
		);


bitstream_FIFO : config_data_FIFO
    PORT MAP
        (
        rst => fifo_reset,
        wr_clk => clk,
        rd_clk => configuration_clk,
        din => data_in,
        wr_en => data_in_valid,
        rd_en => fifo_read_enable,
        dout => data_from_fifo,
        full => data_fifo_full,
        empty => data_fifo_empty_internal,
        prog_full => data_fifo_almost_full
        );

end Behavioral;
