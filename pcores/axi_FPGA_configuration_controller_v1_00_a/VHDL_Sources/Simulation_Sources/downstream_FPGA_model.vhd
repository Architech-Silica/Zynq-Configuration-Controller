library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library axi_FPGA_configuration_controller;
use axi_FPGA_configuration_controller.all;


entity downstream_FPGA_model is
    Generic
        (
        FPGA_PART_NUMBER : string
        );
    Port
        (
        M               : in STD_LOGIC_VECTOR(2 downto 0);
        PROGRAM_B       : in STD_LOGIC;
        INIT_B          : inout STD_LOGIC;
        DONE            : inout STD_LOGIC;
        CCLK            : inout STD_LOGIC;
        PUDC_B          : in STD_LOGIC;
        EMCCLK          : in STD_LOGIC;
        CSI_B           : in STD_LOGIC;
        CSO_B           : out STD_LOGIC;
        DOUT            : out STD_LOGIC;
        RDWR_B          : in STD_LOGIC;
        D00_MOSI        : inout STD_LOGIC;
        D01_DIN         : inout STD_LOGIC;
        D               : inout STD_LOGIC_VECTOR(31 downto 0);
        A               : out STD_LOGIC_VECTOR(28 downto 0);
        FCS_B           : out STD_LOGIC;
        FOE_B           : out STD_LOGIC;
        FWE_B           : out STD_LOGIC;
        ADV_B           : out STD_LOGIC;
        RS              : out STD_LOGIC_VECTOR(1 downto 0)
        );
end downstream_FPGA_model;

architecture Behavioral of downstream_FPGA_model is

-- Type declarations
type main_fsm_type is ( reset, post_prog_init, wait_for_init, slave_select_map_receive_data, select_map_abort, slave_serial_receive_data, bus_width_detection,
                        wait_for_sync_word, startup, configured, error);
type parallel_data_shift_reg_type is array (1 downto 0) of std_logic_vector(7 downto 0);

-- BITSTREAM LENGTHS
constant BITSTREAM_LENGTH_SIM_TEST  : INTEGER := 20000; 
constant BITSTREAM_LENGTH_7A15T     : INTEGER := 17536096; 
constant BITSTREAM_LENGTH_7A35T     : INTEGER := 17536096; 
constant BITSTREAM_LENGTH_7A50T     : INTEGER := 17536096; 
constant BITSTREAM_LENGTH_7A75T     : INTEGER := 30606304; 
constant BITSTREAM_LENGTH_7A100T    : INTEGER := 30606304;
constant BITSTREAM_LENGTH_7A200T    : INTEGER := 77845216;
constant BITSTREAM_LENGTH_7K70T     : INTEGER := 24090592; 
constant BITSTREAM_LENGTH_7K160T    : INTEGER := 53540576; 
constant BITSTREAM_LENGTH_7K325T    : INTEGER := 91548896; 
constant BITSTREAM_LENGTH_7K355T    : INTEGER := 112414688;
constant BITSTREAM_LENGTH_7K410T    : INTEGER := 127023328;
constant BITSTREAM_LENGTH_7K420T    : INTEGER := 149880032;
constant BITSTREAM_LENGTH_7K480T    : INTEGER := 149880032;
constant BITSTREAM_LENGTH_7V585T    : INTEGER := 161398880;
constant BITSTREAM_LENGTH_7V2000T   : INTEGER := 447337216; 
constant BITSTREAM_LENGTH_7VX330T   : INTEGER := 111238240; 
constant BITSTREAM_LENGTH_7VX415T   : INTEGER := 137934560; 
constant BITSTREAM_LENGTH_7VX485T   : INTEGER := 162187488; 
constant BITSTREAM_LENGTH_7VX550T   : INTEGER := 229878496; 
constant BITSTREAM_LENGTH_7VX690T   : INTEGER := 229878496; 
constant BITSTREAM_LENGTH_7VX980T   : INTEGER := 282521312; 
constant BITSTREAM_LENGTH_7VX1140   : INTEGER := 385127680;
constant BITSTREAM_LENGTH_7VH580T   : INTEGER := 195663008; 
constant BITSTREAM_LENGTH_7VH870T   : INTEGER := 294006336;

-- MODE PIN CONSTANTS
constant MASTER_SERIAL_MODE     : STD_LOGIC_VECTOR(2 downto 0) := "LLL";
constant MASTER_SPI_MODE        : STD_LOGIC_VECTOR(2 downto 0) := "LLH";
constant MASTER_BPI_MODE        : STD_LOGIC_VECTOR(2 downto 0) := "LHL";
constant MASTER_SELECT_MAP_MODE : STD_LOGIC_VECTOR(2 downto 0) := "HLL";
constant JTAG_MODE              : STD_LOGIC_VECTOR(2 downto 0) := "HLH";
constant SLAVE_SELECT_MAP_MODE  : STD_LOGIC_VECTOR(2 downto 0) := "HHL";
constant SLAVE_SERIAL_MODE      : STD_LOGIC_VECTOR(2 downto 0) := "HHH";

-- Internal config clock
constant INTERNAL_CCLK_FREQ_HZ : integer := 100000000;
constant INTERNAL_CCLK_period_NS : integer := 1000000000 / INTERNAL_CCLK_FREQ_HZ;
constant INTERNAL_CCLK_period_PS : integer := INTERNAL_CCLK_period_NS * 1000;
constant INTERNAL_CCLK_period_time : time := 1 ns * INTERNAL_CCLK_period_NS;
constant INTERNAL_CLK_FREQ_HZ : integer := 131000000;  -- 131 MHz (An intentionally completely random frequency!)
constant INTERNAL_CLK_period_NS : integer := 1000000000 / INTERNAL_CLK_FREQ_HZ;
constant INTERNAL_CLK_period_PS : integer := INTERNAL_CLK_period_NS * 1000;
constant INTERNAL_CLK_period_time : time := 1 ns * INTERNAL_CLK_period_NS;


subtype counter_type is integer range 0 to 64;

signal current_state, next_state : main_fsm_type;
signal startup_counter : integer;
signal reset_startup_counter : std_logic := '0';
signal enable_startup_counter : std_logic := '0';
signal bitstream_size_counter : integer;
signal reset_bitstream_size_counter : std_logic := '0';
signal enable_bitstream_size_counter : std_logic := '0';
signal expected_bitstream_length : integer;
signal enable_bus_width_detection_unit : std_logic;
signal width_detection_complete : std_logic;
signal reset_width_detection : std_logic;
signal enable_sync_word_detection_unit : std_logic;
signal sync_word_detected : std_logic := '0';
signal detected_bus_width : integer range 0 to 32;
signal parallel_data_shift_reg : parallel_data_shift_reg_type;
signal parallel_data_shift_reg_concatenated : std_logic_vector(15 downto 0);
signal enable_clock_generation : std_logic;
signal serial_data_shift_reg : std_logic_vector(31 downto 0) := (others => '0');
signal serial_data_shift_reg_counter : integer range 0 to 31;
signal INTERNAL_CLK : std_logic;
signal INTERNAL_CCLK : std_logic;
signal counter : counter_type;
signal reset_counter : std_logic := '0';
signal enable_counter : std_logic := '0';


begin

bitstream_length_process: process
begin
    case FPGA_PART_NUMBER is
        when "SIM_TEST "    => expected_bitstream_length <= BITSTREAM_LENGTH_SIM_TEST;
        when "XC7A15T  "    => expected_bitstream_length <= BITSTREAM_LENGTH_7A15T;
        when "XC7A35T  "    => expected_bitstream_length <= BITSTREAM_LENGTH_7A35T;   
        when "XC7A50T  "    => expected_bitstream_length <= BITSTREAM_LENGTH_7A50T;   
        when "XC7A75T  "    => expected_bitstream_length <= BITSTREAM_LENGTH_7A75T;   
        when "XC7A100T "    => expected_bitstream_length <= BITSTREAM_LENGTH_7A100T;  
        when "XC7A200T "    => expected_bitstream_length <= BITSTREAM_LENGTH_7A200T;  
        when "XC7K70T  "    => expected_bitstream_length <= BITSTREAM_LENGTH_7K70T;   
        when "XC7K160T "    => expected_bitstream_length <= BITSTREAM_LENGTH_7K160T;  
        when "XC7K325T "    => expected_bitstream_length <= BITSTREAM_LENGTH_7K325T;  
        when "XC7K355T "    => expected_bitstream_length <= BITSTREAM_LENGTH_7K355T;  
        when "XC7K410T "    => expected_bitstream_length <= BITSTREAM_LENGTH_7K410T;  
        when "XC7K420T "    => expected_bitstream_length <= BITSTREAM_LENGTH_7K420T;  
        when "XC7K480T "    => expected_bitstream_length <= BITSTREAM_LENGTH_7K480T;  
        when "XC7V585T "    => expected_bitstream_length <= BITSTREAM_LENGTH_7V585T;  
        when "XC7V2000T"    => expected_bitstream_length <= BITSTREAM_LENGTH_7V2000T; 
        when "XC7VX330T"    => expected_bitstream_length <= BITSTREAM_LENGTH_7VX330T; 
        when "XC7VX415T"    => expected_bitstream_length <= BITSTREAM_LENGTH_7VX415T; 
        when "XC7VX485T"    => expected_bitstream_length <= BITSTREAM_LENGTH_7VX485T; 
        when "XC7VX550T"    => expected_bitstream_length <= BITSTREAM_LENGTH_7VX550T; 
        when "XC7VX690T"    => expected_bitstream_length <= BITSTREAM_LENGTH_7VX690T; 
        when "XC7VX980T"    => expected_bitstream_length <= BITSTREAM_LENGTH_7VX980T; 
        when "XC7VX1140"    => expected_bitstream_length <= BITSTREAM_LENGTH_7VX1140; 
        when "XC7VH580T"    => expected_bitstream_length <= BITSTREAM_LENGTH_7VH580T; 
        when "XC7VH870T"    => expected_bitstream_length <= BITSTREAM_LENGTH_7VH870T;
        when others         => expected_bitstream_length <= 0;
    end case;
    wait;
end process;

cclk_mux : process (INTERNAL_CCLK)
begin
    CCLK <= 'Z';
    if enable_clock_generation = '1' then
        case M is
            when SLAVE_SELECT_MAP_MODE => CCLK <= 'Z';
            when SLAVE_SERIAL_MODE => CCLK <= 'Z';
            when others => CCLK <= INTERNAL_CCLK;
        end case;
    end if;
end process cclk_mux;


cclk_gen : process
begin
    loop
        INTERNAL_CCLK <= '0';
        wait for INTERNAL_CCLK_period_time / 2;
        INTERNAL_CCLK <= '1';
        wait for INTERNAL_CCLK_period_time / 2;
    end loop;
    wait;
end process cclk_gen;

internal_osc : process
begin
    loop
        INTERNAL_CLK <= '0';
        wait for INTERNAL_CLK_period_time / 2;
        INTERNAL_CLK <= '1';
        wait for INTERNAL_CLK_period_time / 2;
    end loop;
    wait;
end process internal_osc;

sync_word_detection_unit : process (CCLK, PROGRAM_B)
begin
    if PROGRAM_B = '0' then
        sync_word_detected <= '0';
    elsif rising_edge(CCLK) then
        if sync_word_detected = '0' and enable_sync_word_detection_unit = '1' then
            if serial_data_shift_reg = X"AA995566" then  -- Sync word
                sync_word_detected <= '1';
            end if;
        end if;
    end if;
end process;

counter_process : process (CCLK)
begin
    if rising_edge(CCLK) then
        if reset_counter = '1' then
            counter <= 0;
        elsif enable_counter = '1' then
            if counter < counter_type'HIGH then
                counter <= counter + 1;
            end if;
        end if;
    end if;
end process;

incoming_serial_data_shift_reg : process (CCLK, PROGRAM_B)
begin
    if PROGRAM_B = '0' then
        serial_data_shift_reg <= (others => '0');
    elsif rising_edge(CCLK) then
        case M is
            when SLAVE_SERIAL_MODE | MASTER_SERIAL_MODE =>
                for i in 30 downto 0 loop  
                    serial_data_shift_reg(i) <= serial_data_shift_reg(i+1);
                end loop;
                serial_data_shift_reg(31) <= D01_DIN;
            when SLAVE_SELECT_MAP_MODE | MASTER_SELECT_MAP_MODE=>
                if CSI_B = '0' then
                    case detected_bus_width is
                        when 32 =>
                            serial_data_shift_reg <= D;
                        when 16 =>
                            for bit_index in 31 downto 16 loop
                                serial_data_shift_reg(bit_index) <= serial_data_shift_reg(bit_index-16);
                            end loop;
                            for bit_index in 15 downto 0 loop
                                serial_data_shift_reg(bit_index) <= D(bit_index);
                            end loop;
                        when 8 =>
                                for bit_index in 31 downto 24 loop
                                    serial_data_shift_reg(bit_index) <= serial_data_shift_reg(bit_index-8);
                                end loop;
                                for bit_index in 23 downto 16 loop
                                    serial_data_shift_reg(bit_index) <= serial_data_shift_reg(bit_index-8);
                                end loop;
                                for bit_index in 15 downto 8 loop
                                    serial_data_shift_reg(bit_index) <= serial_data_shift_reg(bit_index-8);
                                end loop;
                                for bit_index in 7 downto 0 loop
                                    serial_data_shift_reg(bit_index) <= D(bit_index);
                                end loop;
                        when others => NULL;
                    end case;
                end if;
            when others => NULL;
        end case;
    end if;
end process;

incoming_serial_data_shift_reg_counter : process (CCLK, PROGRAM_B)
begin
    if PROGRAM_B = '0' then
        serial_data_shift_reg_counter <= 0;
    elsif rising_edge(CCLK) then
        if (serial_data_shift_reg = X"000000BB" and enable_bus_width_detection_unit = '1') then
            serial_data_shift_reg_counter <= 0;
        else
            if (serial_data_shift_reg_counter = 31) then 
                serial_data_shift_reg_counter <= 0;
            else
                serial_data_shift_reg_counter <= serial_data_shift_reg_counter + 1;
            end if;
        end if;
    end if;
end process;


bus_width_detection_unit : process (CCLK, parallel_data_shift_reg, parallel_data_shift_reg_concatenated)
begin
    parallel_data_shift_reg_concatenated <= parallel_data_shift_reg(1) & parallel_data_shift_reg(0);
    if reset_width_detection = '1' then
        case M is 
            when SLAVE_SERIAL_MODE | MASTER_SERIAL_MODE =>
                detected_bus_width <= 1;
                width_detection_complete <= '0';
            when others =>
                detected_bus_width <= 0;
                width_detection_complete <= '0';
        end case;
        parallel_data_shift_reg <= (others => (others => '0'));
    elsif rising_edge(CCLK) then
        if CSI_B = '0' then
            parallel_data_shift_reg(1) <= parallel_data_shift_reg(0);
            parallel_data_shift_reg(0) <= D(7 downto 0);
            if enable_bus_width_detection_unit = '1' and width_detection_complete = '0' then
                case parallel_data_shift_reg_concatenated is
                    when X"BB11" =>
                        detected_bus_width <= 8;                    
                        width_detection_complete <= '1'; 
                    when X"BB22" =>
                        detected_bus_width <= 16;                    
                        width_detection_complete <= '1'; 
                    when X"BB44" =>
                        detected_bus_width <= 32;                    
                        width_detection_complete <= '1'; 
                    when others => NULL;
                end case;
            end if;
        end if;
    end if;
end process;

state_machine_update : process (INTERNAL_CLK)
begin
    if rising_edge(INTERNAL_CLK) then
        if PROGRAM_B = '0' then
            current_state <= reset;
        else
            current_state <= next_state;
        end if;
    end if;
end process;

startup_counter_process : process (CCLK, reset_startup_counter)
begin
    if reset_startup_counter = '1' then
        startup_counter <= 0;
    elsif rising_edge(CCLK) then
        if enable_startup_counter = '1' then
            startup_counter <= startup_counter + 1;
        end if;
    end if;
end process;


bitstream_size_counter_process : process (CCLK)
begin
    if reset_bitstream_size_counter = '1' then
        bitstream_size_counter <= 0;
    elsif rising_edge(CCLK) then
        if enable_bitstream_size_counter = '1' then
            bitstream_size_counter <= bitstream_size_counter + detected_bus_width;
        end if;
    end if;
end process;


state_machine_decisions : process ( current_state, startup_counter, bitstream_size_counter, expected_bitstream_length, M,
                                    PROGRAM_B, INIT_B, DONE, PUDC_B, CSI_B, RDWR_B, D00_MOSI, D01_DIN, D, sync_word_detected,
                                    width_detection_complete, detected_bus_width, serial_data_shift_reg, counter
                                    )
begin
    INIT_B <= 'Z';
    DONE <= 'H';
    CCLK <= 'Z';
    CSO_B <= 'H';
    DOUT <= 'Z';
    D00_MOSI <= 'Z';
    D01_DIN <= 'Z';
    D <= (others => 'Z');
    A <= (others => 'Z');
    FCS_B <= 'Z';
    FOE_B <= 'Z';
    FWE_B <= 'Z';
    ADV_B <= 'Z';
    RS <= (others => 'Z');
    reset_startup_counter <= '0';
    enable_startup_counter <= '0';
    reset_bitstream_size_counter <= '0';
    enable_bitstream_size_counter <= '0';
    enable_bus_width_detection_unit <= '0';
    enable_sync_word_detection_unit <= '0';
    reset_width_detection <= '0';
    enable_clock_generation <= '1';
    reset_counter <= '0';
    enable_counter <= '0';

    case current_state is
        when reset =>
            next_state <= post_prog_init;
            enable_clock_generation <= '0';
            reset_bitstream_size_counter <= '1';
            reset_startup_counter <= '1';
            reset_width_detection <= '1';
            DONE <= '0';
            reset_counter <= '1';

        when post_prog_init =>
            next_state <= wait_for_init;
            enable_clock_generation <= '0';
            INIT_B <= '0';
            DONE <= '0';

        when wait_for_init =>
            DONE <= '0';
            next_state <= wait_for_init;
            enable_clock_generation <= '0';
            if INIT_B = '1' or INIT_B = 'H' then
                case M is
                    when SLAVE_SELECT_MAP_MODE | MASTER_SELECT_MAP_MODE => 
                        next_state <= bus_width_detection;
                    when SLAVE_SERIAL_MODE | MASTER_SERIAL_MODE => 
                        next_state <= wait_for_sync_word;
                    when others =>
                        next_state <= error;
                end case;
            end if;

        when bus_width_detection => 
            DONE <= '0';
            enable_bitstream_size_counter <= '1';
            next_state <= bus_width_detection;
            enable_bus_width_detection_unit <= '1';
            if RDWR_B = '1' then
                next_state <= select_map_abort;
            elsif detected_bus_width > 0 then 
                next_state <= wait_for_sync_word;
            end if;
            
        when wait_for_sync_word => 
            DONE <= '0';
            next_state <= wait_for_sync_word;
            enable_bus_width_detection_unit <= '1';
            enable_sync_word_detection_unit <= '1';
            if RDWR_B = '1' then
                next_state <= select_map_abort;
            elsif sync_word_detected = '1' then
                case detected_bus_width is
                    when 1 => next_state <= slave_serial_receive_data;
                    when 8 | 16 | 32 => next_state <= slave_select_map_receive_data; 
                    when others => NULL;
                end case;
            elsif CSI_B = '0' then
                enable_bitstream_size_counter <= '1';
            end if;
                    
        when slave_serial_receive_data =>
            next_state <= slave_serial_receive_data;
            DONE <= '0';
            enable_bitstream_size_counter <= '1';
            if expected_bitstream_length = 0 then 
                next_state <= error;
            elsif bitstream_size_counter > expected_bitstream_length then
                next_state <= startup;
            end if;

        when slave_select_map_receive_data => 
            next_state <= slave_select_map_receive_data;
            DONE <= '0';
            if CSI_B = '0' then
                enable_bitstream_size_counter <= '1';
                if RDWR_B = '1' then
                    next_state <= select_map_abort;
                end if;
            end if;
            if expected_bitstream_length = 0 then 
                next_state <= error;
            elsif bitstream_size_counter > expected_bitstream_length then
                next_state <= startup;
            end if;

        when select_map_abort =>                    
            next_state <= select_map_abort; 
            if counter < 4 then
                enable_counter <= '1';
            end if;
            case counter is
                when 0 => D <= (others => 'Z');
                when 1 => D <= X"000000" & '1' & sync_word_detected & "00" & "0000";
                when 2 | 3 | 4 => D <= X"000000" & '1' & sync_word_detected & "01" & "0000";
                when others => D <= (others => 'Z');
            end case;

        when startup => 
            next_state <= startup;
            enable_startup_counter <= '1';
            DONE <= '0';
            if startup_counter >= 20 then
                next_state <= configured;
            end if;
       
        when configured => 
            next_state <= configured;
            
        when error => 
            DONE <= '0';
            INIT_B <= '0';
            next_state <= error;
            -- This state is intentionally designed to be an oubliette.
            -- If we ever end up here then we need to identify it because there's no hope left in the world!
            
        when others =>
            next_state <= error;
    end case;
end process;


end Behavioral;
