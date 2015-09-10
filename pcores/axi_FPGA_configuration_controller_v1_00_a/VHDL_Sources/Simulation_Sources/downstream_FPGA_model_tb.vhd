library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
USE IEEE.NUMERIC_BIT.ALL;
USE IEEE.STD_LOGIC_TEXTIO.ALL;

LIBRARY STD;
USE STD.TEXTIO.ALL;

library axi_FPGA_configuration_controller;
use axi_FPGA_configuration_controller.FPGA_configuration_controller_pkg.all;

entity downstream_FPGA_model_tb is
end downstream_FPGA_model_tb;


architecture Behavioral of downstream_FPGA_model_tb is

-- MODE PIN CONSTANTS
constant MASTER_SERIAL_MODE     : STD_LOGIC_VECTOR(2 downto 0) := "LLL";
constant MASTER_SPI_MODE        : STD_LOGIC_VECTOR(2 downto 0) := "LLH";
constant MASTER_BPI_MODE        : STD_LOGIC_VECTOR(2 downto 0) := "LHL";
constant MASTER_SELECT_MAP_MODE : STD_LOGIC_VECTOR(2 downto 0) := "HLL";
constant JTAG_MODE              : STD_LOGIC_VECTOR(2 downto 0) := "HLH";
constant SLAVE_SELECT_MAP_MODE  : STD_LOGIC_VECTOR(2 downto 0) := "HHL";
constant SLAVE_SERIAL_MODE      : STD_LOGIC_VECTOR(2 downto 0) := "HHH";

-- Testbench control signals
signal sim_end : boolean := false;
signal cycle_count : integer := 0;

-- Simulation constants
constant MODE_PIN_SETTINGS : STD_LOGIC_VECTOR(2 downto 0) := SLAVE_SERIAL_MODE;
constant SELECT_MAP_DATA_WIDTH : integer range 1 to 32 := 32;
--constant FPGA_PART_NUMBER : string := "XC7A35T";
constant FPGA_PART_NUMBER : string := "SIM_TEST";
constant simulation_interval : time := 1 ms;
constant CCLK_FREQ_HZ : integer := 100000000;
constant CCLK_period_NS : integer := 1000000000 / CCLK_FREQ_HZ;
constant CCLK_period_PS : integer := CCLK_period_NS * 1000;
constant CCLK_period_time : time := 1 ns * CCLK_period_NS;

-- SIGNAL DECLARATIONS
signal M         : STD_LOGIC_VECTOR(2 downto 0);
signal PROGRAM_B : STD_LOGIC;
signal INIT_B    : STD_LOGIC;
signal DONE      : STD_LOGIC;
signal CCLK      : STD_LOGIC;
signal PUDC_B    : STD_LOGIC;
signal EMCCLK    : STD_LOGIC;
signal CSI_B     : STD_LOGIC;
signal CSO_B     : STD_LOGIC;
signal DOUT      : STD_LOGIC;
signal RDWR_B    : STD_LOGIC;
signal D00_MOSI  : STD_LOGIC;
signal D01_DIN   : STD_LOGIC;
signal D         : STD_LOGIC_VECTOR(31 downto 0);
signal A         : STD_LOGIC_VECTOR(28 downto 0);
signal FCS_B     : STD_LOGIC;
signal FOE_B     : STD_LOGIC;
signal FWE_B     : STD_LOGIC;
signal ADV_B     : STD_LOGIC;
signal RS        : STD_LOGIC_VECTOR(1 downto 0);
signal counter : integer;
signal reset_counter : std_logic := '0';
signal enable_counter : std_logic := '0';
signal read_next_bitstream_word : boolean := TRUE;
signal line_counter : integer := 1;

signal data_analysis_output : STD_LOGIC_VECTOR(31 downto 0);
signal data_analysis_detection_point : integer range 0 to 31;




-- COMPONENT DECLARATIONS
component downstream_FPGA_model is
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
end component;

-- PROCEDURE DECLARATIONS

begin

-- Pull Resistors
INIT_B <= 'H';
PROGRAM_B <= 'H';

-- Test Stuff
data_analysis_detection_point <= 0;


cclk_gen : process
begin
    while (not sim_end) loop
        case M is
            when SLAVE_SELECT_MAP_MODE | SLAVE_SERIAL_MODE => 
                CCLK <= '0';
                wait for CCLK_period_time / 2;
                CCLK <= '1';
                wait for CCLK_period_time / 2;
            when others => 
                CCLK <= 'Z';
                wait for CCLK_period_time;
        end case;
    end loop;
    wait;
end process cclk_gen;

counter_process : process (CCLK)
begin
    if CCLK'event and CCLK = '1' then
        if reset_counter = '1' then
            counter <= 0;
        elsif enable_counter = '1' then
            counter <= counter + 1;
        end if;
    end if;
end process;

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
    M                       <= MODE_PIN_SETTINGS;
    PROGRAM_B               <= '1';
    INIT_B                  <= 'Z';
    DONE                    <= 'Z';
    PUDC_B                  <= '1';
    EMCCLK                  <= '0';
    CSI_B                   <= '1';
    RDWR_B                  <= '0';
    D00_MOSI                <= 'Z';
    D01_DIN                 <= 'Z';
    D                       <= (others => 'Z');
    wait for 100 us;

    PROGRAM_B <= '0';  
    wait for 2 ms;
    PROGRAM_B <= '1';  
    
    while INIT_B = '0' loop
        wait until rising_edge(CCLK);
    end loop;


    wait for 100 us;

    annotate_RBT_file;

    while end_of_bitstream = FALSE loop
        -- If DONE has already gone high, spin on the end of the bitstream rather than wasting your life.
        while DONE /= '0' and end_of_bitstream = FALSE loop
            line_counter := line_counter + 10000;
            read_bitstream_file_proc(line_counter, data_from_bitstream_file, end_of_bitstream, bitsteam_line_is_valid_data);
        end loop;
        bitsteam_line_is_valid_data := FALSE;
        read_bitstream_file_proc(line_counter, data_from_bitstream_file, end_of_bitstream, bitsteam_line_is_valid_data);
        line_counter := line_counter + 1;
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
    
        -- THIS IS A TEMPORARY FUDGE TO MAKE SURE WE'RE TRANSMITTING THE DATA IN THE CORRECT BIT ORDER
--        data_from_bitstream_file := X"AAAAAAAA";
--        bitsteam_line_is_valid_data := TRUE;
        
        
        if (bitsteam_line_is_valid_data = TRUE) then 
            case M is
                when SLAVE_SERIAL_MODE | MASTER_SERIAL_MODE => 
                        -- Serial Configuration mode
                        for bit_index in 31 downto 0 loop
                            wait until rising_edge(CCLK);
                            case data_from_bitstream_file(bit_index) is
                                 when '0' => D01_DIN <= '0';
                                 when '1' => D01_DIN <= '1';
                                 when others => D01_DIN <= '-';
                            end case;
                        end loop;
    
                when SLAVE_SELECT_MAP_MODE | MASTER_SELECT_MAP_MODE =>
                    case SELECT_MAP_DATA_WIDTH is
                        when 32 =>
                            wait until rising_edge(CCLK);
                            for byte_index in 0 to 3 loop
                                for bit_index in 0 to 7 loop
                                    D((byte_index*8)+bit_index) <= data_from_bitstream_file(((3-byte_index)*8)+7-bit_index);
                                end loop;
                            end loop;
                        when 16 =>
                            wait until rising_edge(CCLK);
                            for byte_index in 0 to 1 loop
                                for bit_index in 0 to 7 loop
                                    D((byte_index*8)+bit_index) <= data_from_bitstream_file(((1-byte_index)*8)+7-bit_index);
                                end loop;
                            end loop;
                            wait until rising_edge(CCLK);
                            for byte_index in 0 to 1 loop
                                for bit_index in 0 to 7 loop
                                    D((byte_index*8)+bit_index) <= data_from_bitstream_file(((3-byte_index)*8)+7-bit_index);
                                end loop;
                            end loop;
                        when 8 =>
                            for byte_index in 0 to 3 loop
                                wait until rising_edge(CCLK);
                                for bit_index in 0 to 7 loop
                                    D(bit_index) <= data_from_bitstream_file((byte_index*8)+7-bit_index);
                                end loop;
                            end loop;
                        when others => NULL;
                    end case;
                when others => NULL;
            end case;
        else
            D00_MOSI <= '0';
            D01_DIN <= '0';
            D <= (others => '0');
            wait until rising_edge(CCLK);
        end if;
    end loop;
    wait for simulation_interval;
    wait;
end process;



downstream_FPGA : downstream_FPGA_model
    GENERIC MAP
        (
        FPGA_PART_NUMBER => FPGA_PART_NUMBER
        )
    PORT MAP
        (
        M               => M,
        PROGRAM_B       => PROGRAM_B,
        INIT_B          => INIT_B,
        DONE            => DONE,
        CCLK            => CCLK,
        PUDC_B          => PUDC_B,
        EMCCLK          => EMCCLK,
        CSI_B           => CSI_B,
        CSO_B           => CSO_B,
        DOUT            => DOUT,
        RDWR_B          => RDWR_B,
        D00_MOSI        => D00_MOSI,
        D01_DIN         => D01_DIN,
        D               => D,
        A               => A,
        FCS_B           => FCS_B,
        FOE_B           => FOE_B,
        FWE_B           => FWE_B,
        ADV_B           => ADV_B,
        RS              => RS
        );

end Behavioral;
