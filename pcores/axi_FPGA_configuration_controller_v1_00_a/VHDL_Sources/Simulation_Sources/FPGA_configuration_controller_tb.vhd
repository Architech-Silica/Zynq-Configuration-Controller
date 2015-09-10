LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
USE IEEE.STD_LOGIC_TEXTIO.ALL;

LIBRARY STD;
USE STD.TEXTIO.ALL;

library axi_FPGA_configuration_controller;
use axi_FPGA_configuration_controller.all;


ENTITY FPGA_configuration_controller_testbench IS
END FPGA_configuration_controller_testbench;

ARCHITECTURE behaviour OF FPGA_configuration_controller_testbench IS


-- MODE PIN CONSTANTS
constant MASTER_SERIAL_MODE     : STD_LOGIC_VECTOR(2 downto 0) := "LLL";
constant MASTER_SPI_MODE        : STD_LOGIC_VECTOR(2 downto 0) := "LLH";
constant MASTER_BPI_MODE        : STD_LOGIC_VECTOR(2 downto 0) := "LHL";
constant MASTER_SELECT_MAP_MODE : STD_LOGIC_VECTOR(2 downto 0) := "HLL";
constant JTAG_MODE              : STD_LOGIC_VECTOR(2 downto 0) := "HLH";
constant SLAVE_SELECT_MAP_MODE  : STD_LOGIC_VECTOR(2 downto 0) := "HHL";
constant SLAVE_SERIAL_MODE      : STD_LOGIC_VECTOR(2 downto 0) := "HHH";


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


-- Simulation timing constants
constant simulation_interval : time := 30 us;
constant CLK_FREQ_HZ : integer := 100000000;
constant CLK_period_NS : integer := 1000000000 / CLK_FREQ_HZ;
constant CLK_period_PS : integer := CLK_period_NS * 1000;
constant CLK_period_time : time := 1 ns * CLK_period_NS;

-- Type declarations # 1
type PCB_layout_type is (SLAVE_SELECT_MAP_LAYOUT, SLAVE_SERIAL_LAYOUT, PARALLEL_DAISY_CHAIN_LAYOUT);

-- Simulation setup
constant PCB_LAYOUT                     : PCB_layout_type := SLAVE_SELECT_MAP_LAYOUT;
constant CONFIG_DATA_WIDTH              : integer range 1 to 32 := 8;
constant AES_SECURE_CONFIG              : integer := 0;
constant CONFIG_DATA_IS_BIT_SWAPPED     : integer := 1;
constant NUMBER_OF_DOWNSTREAM_FPGAS     : integer range 1 to 32 := 1;
constant CONFIG_CLK_FREQ_HZ             : integer := 33000000;
--constant FPGA_PART_NUMBER               : string := "XC7A35T";
constant FPGA_PART_NUMBER               : string := "SIM_TEST ";

-- Type declarations # 2
type MODE_PIN_SETTINGS_TYPE is array (0 to NUMBER_OF_DOWNSTREAM_FPGAS-1) of std_logic_vector(2 downto 0);


-- Component Declaration for the Unit Under Test (UUT)
COMPONENT FPGA_configuration_controller is
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
        total_bits_sent             : out STD_LOGIC_VECTOR(31 downto 0);
        CONFIG_CCLK                 : out STD_LOGIC;
        CONFIG_DATA                 : inout STD_LOGIC_VECTOR(31 downto 0);
        CONFIG_CSI_B                : out STD_LOGIC_VECTOR(NUMBER_OF_FPGAS_IN_CHAIN-1 downto 0);
        CONFIG_RDWR_B               : out STD_LOGIC;
        CONFIG_PROGB                : inout STD_LOGIC;
        CONFIG_INITB                : inout STD_LOGIC;
        CONFIG_DONE                 : inout STD_LOGIC
        );
end COMPONENT;

COMPONENT downstream_FPGA_model is
    Generic
        (
        FPGA_PART_NUMBER : string := "wibble"
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
end COMPONENT;

-- Testbench signals
signal clk                         : STD_LOGIC;
signal rst                         : STD_LOGIC;
signal go                          : STD_LOGIC;
signal abort                       : STD_LOGIC;
signal done                        : STD_LOGIC;
signal running                     : STD_LOGIC;
signal error                       : STD_LOGIC;
signal aborted                     : STD_LOGIC;
signal abort_status                : STD_LOGIC_VECTOR(31 downto 0);
signal chain_ID_to_configure       : STD_LOGIC_VECTOR(4 downto 0);
signal bitstream_length_bits       : STD_LOGIC_VECTOR(31 downto 0);
signal data_in                     : STD_LOGIC_VECTOR(31 downto 0);
signal data_in_valid               : STD_LOGIC;
signal data_fifo_full              : STD_LOGIC;
signal data_fifo_almost_full       : STD_LOGIC;
signal total_bits_sent             : STD_LOGIC_VECTOR(31 downto 0);
signal CONFIG_CCLK                  : STD_LOGIC;
signal CONFIG_DATA                 : STD_LOGIC_VECTOR(31 downto 0);
signal CONFIG_CSI_B                : STD_LOGIC_VECTOR(NUMBER_OF_DOWNSTREAM_FPGAS-1 downto 0);
signal CONFIG_RDWR_B               : STD_LOGIC;
signal CONFIG_PROGB                : STD_LOGIC;
signal CONFIG_INITB                : STD_LOGIC;
signal CONFIG_DONE                 : STD_LOGIC;
signal CONFIG_PUDC_B               : STD_LOGIC;

-- PCB signals
signal PCB_CSI_B                    : STD_LOGIC_VECTOR(NUMBER_OF_DOWNSTREAM_FPGAS-1 downto 0);
signal PCB_CSO_B                    : STD_LOGIC_VECTOR(NUMBER_OF_DOWNSTREAM_FPGAS-1 downto 0);
signal PCB_DOUT                     : STD_LOGIC_VECTOR(NUMBER_OF_DOWNSTREAM_FPGAS-1 downto 0);
signal PCB_DIN                      : STD_LOGIC_VECTOR(NUMBER_OF_DOWNSTREAM_FPGAS-1 downto 0);
signal PCB_MODE_PINS                : MODE_PIN_SETTINGS_TYPE;


-- Testbench control signals
signal sim_end : boolean := false;
signal cycle_count : integer := 0;


BEGIN

-- Pull Resistors
CONFIG_PROGB    <= 'H';
CONFIG_INITB    <= 'H';
CONFIG_DONE     <= 'H';
CONFIG_PUDC_B   <= 'H';


clk_gen : process
begin
   while (not sim_end) loop
	  clk <= '0';
		 wait for clk_period_time / 2;
	  clk <= '1';
		 wait for clk_period_time / 2;
   end loop;
   wait;
end process clk_gen;

rst_gen : process
begin
    rst <= '0';
    wait for clk_period_time * 20;
    rst <= '1';
    wait for clk_period_time * 5;
    rst <= '0';
    wait;
end process rst_gen;


PCB_wiring : process (CONFIG_DATA, CONFIG_CSI_B)
begin
    case PCB_LAYOUT is
        when SLAVE_SERIAL_LAYOUT =>
            PCB_DIN(0) <= CONFIG_DATA(0);
            if NUMBER_OF_DOWNSTREAM_FPGAS > 1 then 
                for i in 1 to NUMBER_OF_DOWNSTREAM_FPGAS-1 loop
                    PCB_DIN(i) <= PCB_DOUT(i-1);
                end loop;
            end if;
            for i in 0 to NUMBER_OF_DOWNSTREAM_FPGAS-1 loop
                PCB_MODE_PINS(i) <= SLAVE_SERIAL_MODE;
            end loop;
            PCB_CSI_B <= (others => 'H'); 

        when SLAVE_SELECT_MAP_LAYOUT => 
            for i in 0 to NUMBER_OF_DOWNSTREAM_FPGAS-1 loop
                PCB_MODE_PINS(i) <= SLAVE_SELECT_MAP_MODE;
            end loop;
            PCB_DIN(0) <= 'L';
            PCB_CSI_B <= CONFIG_CSI_B; 

        when PARALLEL_DAISY_CHAIN_LAYOUT =>
            PCB_CSI_B(0) <= CONFIG_CSI_B(0);
            for i in 1 to NUMBER_OF_DOWNSTREAM_FPGAS-1 loop
                PCB_CSI_B(i) <= CONFIG_CSI_B(i-1);
            end loop;

        when others =>         
            for i in 0 to NUMBER_OF_DOWNSTREAM_FPGAS-1 loop
                PCB_MODE_PINS(i) <= JTAG_MODE;
            end loop;
    end case;
end process PCB_wiring;


stimuli : process
procedure read_bitstream_file_proc (line_to_read : integer; data_from_bitstream_file : inout std_logic_vector(31 downto 0); end_of_bitstream : inout boolean; bitsteam_line_is_valid_data : inout boolean) is
    constant bitstream_filename : string := "C:\customer\artix7_completely_full_device__June_2015\project_1\project_1.runs\impl_1\chip_filler.rbt";
    file bitstream_file_pointer : TEXT open read_mode is bitstream_filename;
    variable bitstream_file_line : LINE;
    variable bitstream_line_string : STRING (1 to 32);
    variable bitstream_line_integer : integer;
    variable line_is_a_data_value : boolean;
    variable char : character;
    variable bistream_word_index : integer := 0;
    variable line_counter : integer := 0;
    begin
    file_close(bitstream_file_pointer);
    file_open(bitstream_file_pointer, bitstream_filename, READ_MODE);
    
    while (line_counter < line_to_read) loop
        if (ENDFILE(bitstream_file_pointer)) then
            FILE_CLOSE(bitstream_file_pointer);
            end_of_bitstream := TRUE;
            exit;        
        end if;
        READLINE (bitstream_file_pointer, bitstream_file_line);
        line_counter := line_counter + 1;
    end loop;
    
    line_is_a_data_value := TRUE;
    if (bitstream_file_line'LENGTH = 33) then
        -- Only read from the line if it is longer than 32 characters (line length of 33)
        READ (bitstream_file_line, bitstream_line_string); --read in the line from the file & store as string array
        for character_index in 1 to 32 loop       
                char := bitstream_line_string(character_index);
                case char is
                     when '0' => NULL;
                     when '1' => NULL;
                     when others =>
                        line_is_a_data_value := FALSE;
                end case;
        end loop;
    else
        -- In the case that the input line is shorter than 32 characters, read it char by char
        line_is_a_data_value := FALSE;
        for character_index in 1 to 32 loop
            if (bitstream_file_line'LENGTH > 0) then
                READ (bitstream_file_line, char);
                bitstream_line_string(character_index) := char;
            else
                bitstream_line_string(character_index) := ' ';
            end if;
        end loop;
    end if;
    
--   report "String from bitstream_file is --> " & bitstream_line_string;
    
    if (line_is_a_data_value = TRUE) then
        report "Line from bitstream IS a data value --> " & bitstream_line_string;
        for character_index in 1 to 32 loop       
            char := bitstream_line_string(character_index);
            case char is
                 when '0' => data_from_bitstream_file(character_index-1) := '0';
                 when '1' => data_from_bitstream_file(character_index-1) := '1';
                 when others => data_from_bitstream_file(character_index-1) := '-';  -- CONSIDER INSERTING AN ERROR CONDITION HERE!!!
            end case;
        end loop;
        bitsteam_line_is_valid_data := TRUE;
    else
        report "Line from bitstream IS NOT a data value --> " & bitstream_line_string;
    end if;
    
    FILE_CLOSE(bitstream_file_pointer);
end procedure read_bitstream_file_proc;
procedure annotate_RBT_file is
    constant bitstream_filename : string := "C:\customer\artix7_completely_full_device__June_2015\project_1\project_1.runs\impl_1\chip_filler.rbt";
    constant annotated_bitstream_filename : string := "C:\Users\griffinr\Desktop\annotated_bitstream.txt";
    file bitstream_file_pointer : TEXT open read_mode is bitstream_filename;
    file annotated_bitstream_file_pointer : TEXT open write_mode is annotated_bitstream_filename;
    variable bitstream_file_line : LINE;
    variable bitstream_line_string : STRING (1 to 32);
    variable annotated_bitstream_file_line : LINE;
    variable annotated_bitstream_line_string : STRING (1 to 32);
    variable data_from_bitstream_file : std_logic_vector(31 downto 0);
    variable bitswapped_data_from_bitstream_file : std_logic_vector(31 downto 0);
    variable char : character;
    begin
    file_close(bitstream_file_pointer);
    file_open(bitstream_file_pointer, bitstream_filename, READ_MODE);
    file_close(annotated_bitstream_file_pointer);
    file_open(annotated_bitstream_file_pointer, annotated_bitstream_filename, WRITE_MODE);
    
    while (not (ENDFILE(bitstream_file_pointer))) loop
        READLINE (bitstream_file_pointer, bitstream_file_line);
        if (bitstream_file_line'LENGTH = 33) then
            READ (bitstream_file_line, bitstream_line_string); --read in the line from the file & store as string array
            for character_index in 1 to 32 loop       
                char := bitstream_line_string(character_index);
                case char is
                     when '0' => data_from_bitstream_file(character_index-1) := '0';
                     when '1' => data_from_bitstream_file(character_index-1) := '1';
                     when others => data_from_bitstream_file(character_index-1) := '-';
                end case;
            end loop;
            for byte_index in 0 to 3 loop
                for bit_index in 0 to 7 loop
                    bitswapped_data_from_bitstream_file((byte_index*8)+bit_index) := data_from_bitstream_file(((3-byte_index)*8)+7-bit_index);
                end loop;
            end loop;
            WRITE (annotated_bitstream_file_line, data_from_bitstream_file);
            WRITE (annotated_bitstream_file_line, string'("  (0x"));
            HWRITE (annotated_bitstream_file_line, data_from_bitstream_file);
            WRITE (annotated_bitstream_file_line, string'(")  (B/S = 0x"));
            HWRITE (annotated_bitstream_file_line, bitswapped_data_from_bitstream_file);
            WRITE (annotated_bitstream_file_line, string'(")"));
            WRITELINE (annotated_bitstream_file_pointer, annotated_bitstream_file_line);
        else
            -- In the case that the input line is shorter than 32 characters, read it char by char
            for character_index in 1 to 32 loop
                if (bitstream_file_line'LENGTH > 0) then
                    READ (bitstream_file_line, char);
                    bitstream_line_string(character_index) := char;
                end if;
            end loop;
            WRITE (annotated_bitstream_file_line, bitstream_line_string);
            WRITELINE (annotated_bitstream_file_pointer, annotated_bitstream_file_line);
        end if;
    end loop;
    FILE_CLOSE(bitstream_file_pointer);
end procedure annotate_RBT_file;
-- Local variables for the stimuli process
variable line_counter : integer := 1;
variable data_from_bitstream_file : std_logic_vector(31 downto 0);
variable end_of_bitstream : boolean := FALSE;
variable bitsteam_line_is_valid_data : boolean := FALSE;
variable text_line : LINE;
begin
    go                      <= '0';
    abort                   <= '0';
    data_in                 <= (others => '0');
    data_in_valid           <= '0';
    bitstream_length_bits   <= std_logic_vector(to_unsigned(BITSTREAM_LENGTH_SIM_TEST, bitstream_length_bits'LENGTH));
    chain_ID_to_configure   <= (others => '0');

    -- Do some clever stuff to read the bitream and annotate it to make debugging easier.
    annotate_RBT_file;

    wait for simulation_interval;

    -- Align ourselves to a clock edge
    wait until rising_edge(clk);

	-- Try to write some data to the configuration controller
    data_in <= X"DEADBEEF";
    data_in_valid <= '1';
    wait for clk_period_time;
    data_in_valid <= '0';
    
    wait for simulation_interval;

    while end_of_bitstream = FALSE loop
        -- If CONFIG_DONE has already gone high, spin on the end of the bitstream rather than wasting your life.
        while done = '1' and running = '1' and end_of_bitstream = FALSE loop
            line_counter := line_counter + 50000;
            read_bitstream_file_proc(line_counter, data_from_bitstream_file, end_of_bitstream, bitsteam_line_is_valid_data);
        end loop;
        bitsteam_line_is_valid_data := FALSE;
        read_bitstream_file_proc(line_counter, data_from_bitstream_file, end_of_bitstream, bitsteam_line_is_valid_data);
        deallocate(text_line);
        write(text_line, string'("[Line number = "));
        write(text_line, line_counter);
        write(text_line, string'("] -- data_from_bitstream_file = 0x"));
        hwrite(text_line, data_from_bitstream_file);
        case data_from_bitstream_file is
            when X"AA995566" => 
                write (text_line, string'("  <-- SYNC WORD"));
            when X"000000BB" => 
                write (text_line, string'("  <-- BUS WIDTH DETECTION "));
            when others => NULL;
        end case;
        report text_line.all;

        if data_fifo_almost_full = '1' and running = '0' then
            go <= '1';
        end if;
    
        -- Test the abort functionality (comment this out if not required)
        -- This should be ignored in slave serial mode, because aborts are not permitted
        if line_counter > 500 then
--            abort <= '1';
        end if;

        if (bitsteam_line_is_valid_data = TRUE) then 
            if data_fifo_full = '0' then
                line_counter := line_counter + 1;
                data_in <= data_from_bitstream_file;
                wait for clk_period_time * 10;
                for delay in 0 to (line_counter*5) loop
                    wait for clk_period_time;
                end loop;
                data_in_valid <= '1';
                wait for clk_period_time;
                data_in_valid <= '0';
            else
                wait for clk_period_time;
            end if;
        else
            line_counter := line_counter + 1;
        end if;
    end loop;

    while done = '0' loop
        wait for clk_period_time;
    end loop;
    
    go <= '0';
    
    wait for simulation_interval;
    wait;
end process;





UUT : FPGA_configuration_controller
    GENERIC MAP
		(
        clock_period_ns => CLK_period_NS,
        CONFIG_CLK_FREQ_HZ => CONFIG_CLK_FREQ_HZ,
        CONFIG_DATA_WIDTH => CONFIG_DATA_WIDTH,
        AES_SECURE_CONFIG => AES_SECURE_CONFIG,
        CONFIG_DATA_IS_BIT_SWAPPED => CONFIG_DATA_IS_BIT_SWAPPED,
        NUMBER_OF_FPGAS_IN_CHAIN => NUMBER_OF_DOWNSTREAM_FPGAS
 		)
	PORT MAP
		(
        clk => clk,
        rst => rst,
        go => go,
        abort => abort,
        done => done,
        running => running,
        error => error,
        aborted => aborted,
        abort_status => abort_status,
        chain_ID_to_configure => chain_ID_to_configure,
        bitstream_length_bits => bitstream_length_bits,
        data_in => data_in,
        data_in_valid => data_in_valid,
        data_fifo_full => data_fifo_full,
        data_fifo_almost_full => data_fifo_almost_full,
        total_bits_sent => total_bits_sent,
        CONFIG_CCLK => CONFIG_CCLK,
        CONFIG_DATA => CONFIG_DATA,
        CONFIG_CSI_B => CONFIG_CSI_B,
        CONFIG_RDWR_B => CONFIG_RDWR_B,
        CONFIG_PROGB => CONFIG_PROGB,
        CONFIG_INITB => CONFIG_INITB,
        CONFIG_DONE => CONFIG_DONE
        );

-- Instantiate the downstream FPGAs 
downsteam_FPGAs : for CHAIN_ID in 0 to NUMBER_OF_DOWNSTREAM_FPGAS-1 generate
    downstream_FPGA : downstream_FPGA_model
        GENERIC MAP
            (
            FPGA_PART_NUMBER => FPGA_PART_NUMBER
            )
        PORT MAP
            (
            M               => PCB_MODE_PINS(CHAIN_ID),
            PROGRAM_B       => CONFIG_PROGB,
            INIT_B          => CONFIG_INITB,
            DONE            => CONFIG_DONE,
            CCLK            => CONFIG_CCLK,
            PUDC_B          => CONFIG_PUDC_B,
            EMCCLK          => '0',
            CSI_B           => PCB_CSI_B(CHAIN_ID),
            CSO_B           => PCB_CSO_B(CHAIN_ID),
            DOUT            => PCB_DOUT(CHAIN_ID),
            RDWR_B          => CONFIG_RDWR_B,
            D00_MOSI        => CONFIG_DATA(0),
            D01_DIN         => PCB_DIN(CHAIN_ID),
            D               => CONFIG_DATA,
            A               => open,
            FCS_B           => open,
            FOE_B           => open,
            FWE_B           => open,
            ADV_B           => open,
            RS              => open
            );
end generate downsteam_FPGAs;

END;

