LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
USE IEEE.STD_LOGIC_TEXTIO.ALL;

LIBRARY STD;
USE STD.TEXTIO.ALL;

library axi_FPGA_configuration_controller;
use axi_FPGA_configuration_controller.all;


ENTITY axi_FPGA_configuration_controller_testbench IS
END axi_FPGA_configuration_controller_testbench;
 

ARCHITECTURE behaviour OF axi_FPGA_configuration_controller_testbench IS 

-- Component Declaration for the Unit Under Test (UUT)
component axi_FPGA_configuration_controller is
    generic
        (
        -- AXI Parameters
        C_S_AXI_ACLK_FREQ_HZ        : integer := 100_000_000;
        C_S_AXI_DATA_WIDTH          : integer := 32;
        C_S_AXI_ADDR_WIDTH          : integer := 8;  
        -- Servo Parameters
        CONFIG_CLK_FREQ_HZ          : integer := 20000000;
        CONFIG_DATA_WIDTH           : integer range 1 to 32 := 1;
        AES_SECURE_CONFIG           : integer := 0;
        CONFIG_DATA_IS_BIT_SWAPPED  : integer := 1;
        NUMBER_OF_FPGAS_IN_CHAIN    : integer := 1
          );
    port
        (
        S_AXI_ACLK                          : in  std_logic;
        S_AXI_ARESETN                       : in  std_logic;
        S_AXI_AWADDR                        : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
        S_AXI_AWVALID                       : in  std_logic;
        S_AXI_AWREADY                       : out std_logic;
        S_AXI_ARADDR                        : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
        S_AXI_ARVALID                       : in  std_logic;
        S_AXI_ARREADY                       : out std_logic;
        S_AXI_WDATA                         : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        S_AXI_WSTRB                         : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
        S_AXI_WVALID                        : in  std_logic;
        S_AXI_WREADY                        : out std_logic;
        S_AXI_RDATA                         : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        S_AXI_RRESP                         : out std_logic_vector(1 downto 0);
        S_AXI_RVALID                        : out std_logic;
        S_AXI_RREADY                        : in  std_logic;
        S_AXI_BRESP                         : out std_logic_vector(1 downto 0);
        S_AXI_BVALID                        : out std_logic;
        S_AXI_BREADY                        : in  std_logic;
        -- User Signals
        CONFIG_CCLK                         : out STD_LOGIC;
        CONFIG_DATA                         : inout STD_LOGIC_VECTOR(31 downto 0);
        CONFIG_CSI_B                        : out STD_LOGIC_VECTOR(NUMBER_OF_FPGAS_IN_CHAIN-1 downto 0);
        CONFIG_RDWR_B                       : out STD_LOGIC;
        CONFIG_PROGB                        : inout STD_LOGIC;
        CONFIG_INITB                        : inout STD_LOGIC;
        CONFIG_DONE                         : inout STD_LOGIC
        );
end component;

COMPONENT AXI_lite_master_transaction_model is
    Port
    (
    -- User signals
    go  : in std_logic;
    busy : out std_logic;
    done : out std_logic;
    rnw : in std_logic;
    address : in std_logic_vector(31 downto 0);
    write_data : in std_logic_vector(31 downto 0);
    read_data : out std_logic_vector(31 downto 0);
    --  AXI4 Signals
    --  AXI4 Clock / Reset
    m_axi_lite_aclk            : in  std_logic;
    m_axi_lite_aresetn         : in  std_logic;
    --  AXI4 Read Address Channel
    m_axi_lite_arready         : in  std_logic;
    m_axi_lite_arvalid         : out std_logic;
    m_axi_lite_araddr          : out std_logic_vector(31 downto 0);
    --  AXI4 Read Data Channel
    m_axi_lite_rready          : out std_logic;
    m_axi_lite_rvalid          : in  std_logic;
    m_axi_lite_rdata           : in  std_logic_vector(31 downto 0);
    m_axi_lite_rresp           : in  std_logic_vector(1 downto 0);
    -- AXI4 Write Address Channel
    m_axi_lite_awready         : in  std_logic;
    m_axi_lite_awvalid         : out std_logic;
    m_axi_lite_awaddr          : out std_logic_vector(31 downto 0);
    -- AXI4 Write Data Channel
    m_axi_lite_wready          : in  std_logic;
    m_axi_lite_wvalid          : out std_logic;
    m_axi_lite_wdata           : out std_logic_vector(31 downto 0);
    m_axi_lite_wstrb           : out std_logic_vector(3 downto 0);
    -- AXI4 Write Response Channel
    m_axi_lite_bready          : out std_logic;
    m_axi_lite_bvalid          : in  std_logic;
    m_axi_lite_bresp           : in  std_logic_vector(1 downto 0)
    );
end component;

COMPONENT downstream_FPGA_model is
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
end COMPONENT;


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


-- Type declarations # 1
type PCB_layout_type is (SLAVE_SELECT_MAP_LAYOUT, SLAVE_SERIAL_LAYOUT, PARALLEL_DAISY_CHAIN_LAYOUT);

-- Simulation Constants
constant NUMBER_OF_DOWNSTREAM_FPGAS     : integer range 1 to 32 := 1;
constant CONFIG_DATA_WIDTH              : integer range 1 to 32 := 32;
constant CONFIG_CLK_FREQ_HZ             : integer := 2000000;
constant PCB_LAYOUT                     : PCB_layout_type := SLAVE_SELECT_MAP_LAYOUT;
constant AES_SECURE_CONFIG              : integer := 0;
constant CONFIG_DATA_IS_BIT_SWAPPED     : integer := 1;

constant FPGA_PART_NUMBER               : string := "XC7A15T  ";  -- The value you put in here MUST be 9 characters in length.  Use trailing spaces!

-- Type declarations # 2
type MODE_PIN_SETTINGS_TYPE is array (0 to NUMBER_OF_DOWNSTREAM_FPGAS-1) of std_logic_vector(2 downto 0);


-- AXI WIDTHS
constant C_S_AXI_DATA_WIDTH : integer := 32;
constant C_S_AXI_ADDR_WIDTH : integer := 8;

-- AXI Clock & Reset stuff
constant C_S_AXI_ACLK_FREQ_HZ : integer := 100000000;
constant AXI_ACLK_period_NS : integer := 1000000000 / C_S_AXI_ACLK_FREQ_HZ;
constant AXI_ACLK_period_PS : integer := AXI_ACLK_period_NS * 1000;
constant AXI_ACLK_period_time : time := 1 ns * AXI_ACLK_period_NS;
constant GENERATE_AXI_RESET : boolean := TRUE;

-- Simulation Interval
constant simulation_interval : time := 50 us;
constant transaction_interval : time := 2 ns;
 
-- Receiver Clock
constant receiver_clk_period : time := 120 ns;
constant receiver_clk_period_ns : integer := receiver_clk_period / 1 ns;


-- Testbench signals
signal AXI_ACLK         : std_logic;
signal AXI_ARESETN      : std_logic;
signal AXI_AWADDR       : std_logic_vector(31 downto 0);
signal AXI_AWVALID      : std_logic;
signal AXI_AWREADY      : std_logic;
signal AXI_ARADDR       : std_logic_vector(31 downto 0);
signal AXI_ARVALID      : std_logic;
signal AXI_ARREADY      : std_logic;
signal AXI_WDATA        : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
signal AXI_WSTRB        : std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
signal AXI_WVALID       : std_logic;
signal AXI_WREADY       : std_logic;
signal AXI_RDATA        : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
signal AXI_RRESP        : std_logic_vector(1 downto 0);
signal AXI_RVALID       : std_logic;
signal AXI_RREADY       : std_logic;
signal AXI_BRESP        : std_logic_vector(1 downto 0);
signal AXI_BVALID       : std_logic;
signal AXI_BREADY       : std_logic;
signal CONFIG_CCLK      : STD_LOGIC;
signal CONFIG_DATA      : STD_LOGIC_VECTOR(31 downto 0);
signal CONFIG_CSI_B     : STD_LOGIC_VECTOR(NUMBER_OF_DOWNSTREAM_FPGAS-1 downto 0);
signal CONFIG_RDWR_B    : STD_LOGIC;
signal CONFIG_PROGB     : STD_LOGIC;
signal CONFIG_INITB     : STD_LOGIC;
signal CONFIG_DONE      : STD_LOGIC;
signal CONFIG_PUDC_B    : STD_LOGIC;

-- PCB signals
signal PCB_CSI_B        : STD_LOGIC_VECTOR(NUMBER_OF_DOWNSTREAM_FPGAS-1 downto 0);
signal PCB_CSO_B        : STD_LOGIC_VECTOR(NUMBER_OF_DOWNSTREAM_FPGAS-1 downto 0);
signal PCB_DOUT         : STD_LOGIC_VECTOR(NUMBER_OF_DOWNSTREAM_FPGAS-1 downto 0);
signal PCB_DIN          : STD_LOGIC_VECTOR(NUMBER_OF_DOWNSTREAM_FPGAS-1 downto 0);
signal PCB_MODE_PINS    : MODE_PIN_SETTINGS_TYPE;

-- Signals to control the AXI master model
signal go  : std_logic;
signal busy : std_logic;
signal done : std_logic;
signal rnw : std_logic;
signal address : std_logic_vector(31 downto 0);
signal write_data : std_logic_vector(31 downto 0);
signal read_data : std_logic_vector(31 downto 0);

-- Testbench control signals
signal sim_end : boolean := false;
signal cycle_count : integer := 0;


BEGIN

-- Pull-up Resistors
CONFIG_PROGB    <= 'H';
CONFIG_INITB    <= 'H';
CONFIG_DONE     <= 'H';
CONFIG_PUDC_B   <= 'H';


axi_clk_gen : process
begin
   while (not sim_end) loop
	  AXI_ACLK <= '0';
		 wait for AXI_ACLK_period_time / 2;
	  AXI_ACLK <= '1';
		 wait for AXI_ACLK_period_time / 2;
   end loop;
   wait;
end process axi_clk_gen;

axi_rst_gen : process
begin
    AXI_ARESETN <= '1';
    wait for AXI_ACLK_period_time * 20;
    if GENERATE_AXI_RESET = TRUE then
        AXI_ARESETN <= '0';
    end if;
    wait for AXI_ACLK_period_time * 5;
    AXI_ARESETN <= '1';
    wait;
end process axi_rst_gen;

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
variable local_done : BOOLEAN := FALSE;
variable temp : std_logic_vector(31 downto 0);
variable read_data : std_logic_vector(31 downto 0);

begin
    address <= X"00000000";
    write_data <= X"00000000";
    rnw <= '0';
    go <= '0';
    
    -- Do some clever stuff to read the bitream and annotate it to make debugging easier.
    annotate_RBT_file;

    wait for simulation_interval;

    -- Align ourselves to a clock edge
    wait until rising_edge(AXI_ACLK);

	-- Try to Read outside the supported address range
	address <= X"30000088";
    rnw <= '1';
    go <= '1';
    wait for AXI_ACLK_period_time;
    wait until done = '1';
    read_data := AXI_RDATA;
    go <= '0';
    wait for AXI_ACLK_period_time;
    address <= X"00000000";
    wait for AXI_ACLK_period_time;
    wait for transaction_interval;

	-- Try to Write outside the supported address range
    address <= X"30000088";
    write_data <= std_logic_vector(to_unsigned(876543, 32));
    rnw <= '0';
    go <= '1';
    wait for AXI_ACLK_period_time;
    wait until done = '1';
    go <= '0';
    wait for AXI_ACLK_period_time;
    address <= X"00000000";
    write_data <= X"00000000";
    wait for AXI_ACLK_period_time;
    wait for transaction_interval;

	-- Read the status register
	address <= X"30000008";
    rnw <= '1';
    go <= '1';
    wait for AXI_ACLK_period_time;
    wait until done = '1';
    read_data := AXI_RDATA;
    go <= '0';
    wait for AXI_ACLK_period_time;
    address <= X"00000000";
    wait for AXI_ACLK_period_time;
    wait for transaction_interval;

	-- Read the abort status register
	address <= X"3000000C";
    rnw <= '1';
    go <= '1';
    wait for AXI_ACLK_period_time;
    wait until done = '1';
    read_data := AXI_RDATA;
    go <= '0';
    wait for AXI_ACLK_period_time;
    address <= X"00000000";
    wait for AXI_ACLK_period_time;
    wait for transaction_interval;

	-- Read the bits sent register
	address <= X"30000014";
    rnw <= '1';
    go <= '1';
    wait for AXI_ACLK_period_time;
    wait until done = '1';
    read_data := AXI_RDATA;
    go <= '0';
    wait for AXI_ACLK_period_time;
    address <= X"00000000";
    wait for AXI_ACLK_period_time;
    wait for transaction_interval;

	-- Write to the data register
	address <= X"30000000";
    write_data <= X"DEADBEEF";
    rnw <= '0';
    go <= '1';
    wait for AXI_ACLK_period_time;
    wait until done = '1';
    go <= '0';
    wait for AXI_ACLK_period_time;
    address <= X"00000000";
    write_data <= X"00000000";
    wait for AXI_ACLK_period_time;
    wait for transaction_interval;

	-- Read the data register (shouldn't work!)
	address <= X"30000000";
    rnw <= '1';
    go <= '1';
    wait for AXI_ACLK_period_time;
    wait until done = '1';
    read_data := AXI_RDATA;
    go <= '0';
    wait for AXI_ACLK_period_time;
    address <= X"00000000";
    wait for AXI_ACLK_period_time;
    wait for transaction_interval;

    wait for simulation_interval;

	-- Write to the software reset register
    address <= X"3000001C";
    write_data <= X"DEADBEEF";
    rnw <= '0';
    go <= '1';
    wait for AXI_ACLK_period_time;
    wait until done = '1';
    go <= '0';
    wait for AXI_ACLK_period_time;
    address <= X"00000000";
    write_data <= X"00000000";
    wait for AXI_ACLK_period_time;
    wait for transaction_interval;

    wait for simulation_interval;

    while end_of_bitstream = FALSE loop
        -- Read the status register
        address <= X"30000008";
        rnw <= '1';
        go <= '1';
        wait for AXI_ACLK_period_time;
        wait until done = '1';
        read_data := AXI_RDATA;
        go <= '0';
        wait for AXI_ACLK_period_time;
        address <= X"00000000";
        wait for AXI_ACLK_period_time;
        wait for transaction_interval;

        -- If CONFIG_DONE has already gone high, spin on the end of the bitstream rather than wasting your life.
        while read_data(0) = '1' and read_data(1) = '1' and end_of_bitstream = FALSE loop  -- Check that "done" and "running" are both high
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

        -- Start the controller only when we know that the data FIFO is nearly full
        if read_data(5) = '1' AND read_data(1) = '0' then  -- Bit 5 = "data_fifo_almost_full", Bit 1 = "running"
            -- Write to the bitstream length register
            address <= X"30000010";
            case FPGA_PART_NUMBER is
                when "SIM_TEST "     => write_data <= std_logic_vector(to_unsigned(BITSTREAM_LENGTH_SIM_TEST, 32));
                when "XC7A15T  "      => write_data <= std_logic_vector(to_unsigned(BITSTREAM_LENGTH_7A15T, 32));
                when "XC7A35T  "      => write_data <= std_logic_vector(to_unsigned(BITSTREAM_LENGTH_7A35T, 32));   
                when "XC7A50T  "      => write_data <= std_logic_vector(to_unsigned(BITSTREAM_LENGTH_7A50T, 32));   
                when "XC7A75T  "      => write_data <= std_logic_vector(to_unsigned(BITSTREAM_LENGTH_7A75T, 32));   
                when "XC7A100T "     => write_data <= std_logic_vector(to_unsigned(BITSTREAM_LENGTH_7A100T, 32)); 
                when "XC7A200T "     => write_data <= std_logic_vector(to_unsigned(BITSTREAM_LENGTH_7A200T, 32)); 
                when "XC7K70T  "      => write_data <= std_logic_vector(to_unsigned(BITSTREAM_LENGTH_7K70T, 32));   
                when "XC7K160T "     => write_data <= std_logic_vector(to_unsigned(BITSTREAM_LENGTH_7K160T, 32));  
                when "XC7K325T "     => write_data <= std_logic_vector(to_unsigned(BITSTREAM_LENGTH_7K325T, 32));  
                when "XC7K355T "     => write_data <= std_logic_vector(to_unsigned(BITSTREAM_LENGTH_7K355T, 32));  
                when "XC7K410T "     => write_data <= std_logic_vector(to_unsigned(BITSTREAM_LENGTH_7K410T, 32));  
                when "XC7K420T "     => write_data <= std_logic_vector(to_unsigned(BITSTREAM_LENGTH_7K420T, 32));  
                when "XC7K480T "     => write_data <= std_logic_vector(to_unsigned(BITSTREAM_LENGTH_7K480T, 32));  
                when "XC7V585T "     => write_data <= std_logic_vector(to_unsigned(BITSTREAM_LENGTH_7V585T, 32));  
                when "XC7V2000T"    => write_data <= std_logic_vector(to_unsigned(BITSTREAM_LENGTH_7V2000T, 32)); 
                when "XC7VX330T"    => write_data <= std_logic_vector(to_unsigned(BITSTREAM_LENGTH_7VX330T, 32)); 
                when "XC7VX415T"    => write_data <= std_logic_vector(to_unsigned(BITSTREAM_LENGTH_7VX415T, 32)); 
                when "XC7VX485T"    => write_data <= std_logic_vector(to_unsigned(BITSTREAM_LENGTH_7VX485T, 32)); 
                when "XC7VX550T"    => write_data <= std_logic_vector(to_unsigned(BITSTREAM_LENGTH_7VX550T, 32)); 
                when "XC7VX690T"    => write_data <= std_logic_vector(to_unsigned(BITSTREAM_LENGTH_7VX690T, 32)); 
                when "XC7VX980T"    => write_data <= std_logic_vector(to_unsigned(BITSTREAM_LENGTH_7VX980T, 32)); 
                when "XC7VX1140"    => write_data <= std_logic_vector(to_unsigned(BITSTREAM_LENGTH_7VX1140, 32)); 
                when "XC7VH580T"    => write_data <= std_logic_vector(to_unsigned(BITSTREAM_LENGTH_7VH580T, 32)); 
                when "XC7VH870T"    => write_data <= std_logic_vector(to_unsigned(BITSTREAM_LENGTH_7VH870T, 32));
                when others         => write_data <= std_logic_vector(to_unsigned(0, 32));
            end case;
            rnw <= '0';
            go <= '1';
            wait for AXI_ACLK_period_time;
            wait until done = '1';
            go <= '0';
            wait for AXI_ACLK_period_time;
            address <= X"00000000";
            write_data <= X"00000000";
            wait for AXI_ACLK_period_time;
            wait for transaction_interval;
            
            -- Read the control register
            address <= X"30000004";
            rnw <= '1';
            go <= '1';
            wait for AXI_ACLK_period_time;
            wait until done = '1';
            read_data := AXI_RDATA;
            go <= '0';
            wait for AXI_ACLK_period_time;
            address <= X"00000000";
            wait for AXI_ACLK_period_time;
            wait for transaction_interval;
            
            temp := read_data;
            temp := temp OR X"00000001";  -- Mask the "Go" bit (bit 0) to pull it high
            
            -- Write to the control register
            address <= X"30000004";
            write_data <= temp;
            rnw <= '0';
            go <= '1';
            wait for AXI_ACLK_period_time;
            wait until done = '1';
            go <= '0';
            wait for AXI_ACLK_period_time;
            address <= X"00000000";
            write_data <= X"00000000";
            wait for AXI_ACLK_period_time;
            wait for transaction_interval;
        end if;
    
        -- Test the abort functionality (comment this out if not required)
        -- This should be ignored in slave serial mode, because aborts are not permitted
        if line_counter > 500 then
--            abort <= '1';
        end if;

        if (bitsteam_line_is_valid_data = TRUE) then 
            -- Read the status register
            address <= X"30000008";
            rnw <= '1';
            go <= '1';
            wait for AXI_ACLK_period_time;
            wait until done = '1';
            read_data := AXI_RDATA;
            go <= '0';
            wait for AXI_ACLK_period_time;
            address <= X"00000000";
            wait for AXI_ACLK_period_time;
--            wait for transaction_interval;

            if read_data(4) = '0' then  -- Bit 4 of the status register is the "Data FIFO full" bit
                line_counter := line_counter + 1;

                -- Write to the data register
                address <= X"30000000";
                write_data <= data_from_bitstream_file;
                rnw <= '0';
                go <= '1';
                wait for AXI_ACLK_period_time;
                wait until done = '1';
                go <= '0';
                wait for AXI_ACLK_period_time;
                address <= X"00000000";
                write_data <= X"00000000";
                wait for AXI_ACLK_period_time;
                wait for transaction_interval;
            else
                wait for AXI_ACLK_period_time;
            end if;
        else
            line_counter := line_counter + 1;
        end if;
    end loop;

    local_done := FALSE;
    
    while local_done = FALSE loop
        -- Read the status register
        address <= X"30000008";
        rnw <= '1';
        go <= '1';
        wait for AXI_ACLK_period_time;
        wait until done = '1';
        read_data := AXI_RDATA;
        go <= '0';
        wait for AXI_ACLK_period_time;
        address <= X"00000000";
        wait for AXI_ACLK_period_time;
        wait for transaction_interval;
    
        case read_data(0) is
            when '0' => local_done := FALSE; 
            when '1' => local_done := TRUE;
            when others => NULL;
        end case;
    end loop;
    
    -- Read the control register
    address <= X"30000004";
    rnw <= '1';
    go <= '1';
    wait for AXI_ACLK_period_time;
    wait until done = '1';
    read_data := AXI_RDATA;
    go <= '0';
    wait for AXI_ACLK_period_time;
    address <= X"00000000";
    wait for AXI_ACLK_period_time;
    wait for transaction_interval;

    temp := read_data;
    temp := temp AND X"FFFFFFFE";  --Mask the "Go" bit (bit 0) to pull it low

    -- Write to the control register
    address <= X"30000000";
    write_data <= temp;
    rnw <= '0';
    go <= '1';
    wait for AXI_ACLK_period_time;
    wait until done = '1';
    go <= '0';
    wait for AXI_ACLK_period_time;
    address <= X"00000000";
    write_data <= X"00000000";
    wait for AXI_ACLK_period_time;
    wait for transaction_interval;
	
	-- End of Stimuli.  Give some time to finish up.
    wait for simulation_interval * 2;

    sim_end <= true;
    wait;
end process;


UUT : axi_FPGA_configuration_controller
    GENERIC MAP
		(
        C_S_AXI_ACLK_FREQ_HZ => C_S_AXI_ACLK_FREQ_HZ,
        C_S_AXI_DATA_WIDTH => C_S_AXI_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH => C_S_AXI_ADDR_WIDTH,  
        CONFIG_CLK_FREQ_HZ => CONFIG_CLK_FREQ_HZ,
        CONFIG_DATA_WIDTH => CONFIG_DATA_WIDTH,
        AES_SECURE_CONFIG => AES_SECURE_CONFIG,
        CONFIG_DATA_IS_BIT_SWAPPED => CONFIG_DATA_IS_BIT_SWAPPED,
        NUMBER_OF_FPGAS_IN_CHAIN => NUMBER_OF_DOWNSTREAM_FPGAS
 		)
	PORT MAP
		(
        CONFIG_CCLK   => CONFIG_CCLK,
        CONFIG_DATA   => CONFIG_DATA,
        CONFIG_CSI_B  => CONFIG_CSI_B,
        CONFIG_RDWR_B => CONFIG_RDWR_B,
        CONFIG_PROGB  => CONFIG_PROGB,
        CONFIG_INITB  => CONFIG_INITB,
        CONFIG_DONE   => CONFIG_DONE,
        S_AXI_ACLK => AXI_ACLK,
        S_AXI_ARESETN => AXI_ARESETN,
        S_AXI_AWADDR => AXI_AWADDR(C_S_AXI_ADDR_WIDTH-1 downto 0),
        S_AXI_AWVALID => AXI_AWVALID,
        S_AXI_WDATA => AXI_WDATA,
        S_AXI_WSTRB => AXI_WSTRB,
        S_AXI_WVALID => AXI_WVALID,
        S_AXI_BREADY => AXI_BREADY,
        S_AXI_ARADDR => AXI_ARADDR(C_S_AXI_ADDR_WIDTH-1 downto 0),
        S_AXI_ARVALID => AXI_ARVALID,
        S_AXI_RREADY => AXI_RREADY,
        S_AXI_ARREADY => AXI_ARREADY,
        S_AXI_RDATA => AXI_RDATA,
        S_AXI_RRESP => AXI_RRESP,
        S_AXI_RVALID => AXI_RVALID,
        S_AXI_WREADY => AXI_WREADY,
        S_AXI_BRESP => AXI_BRESP,
        S_AXI_BVALID => AXI_BVALID,
        S_AXI_AWREADY => AXI_AWREADY
		);

AXI_MASTER_MODEL : AXI_lite_master_transaction_model
	PORT MAP
		(
		go => go,
        busy => busy,
        done => done,
        rnw => rnw,
        address => address,
        write_data => write_data,
        read_data => read_data,
        m_axi_lite_aclk => AXI_ACLK,
        m_axi_lite_aresetn => AXI_ARESETN,
        m_axi_lite_arready => AXI_ARREADY,
        m_axi_lite_arvalid => AXI_ARVALID,
        m_axi_lite_araddr => AXI_ARADDR,
        m_axi_lite_rready => AXI_RREADY,
        m_axi_lite_rvalid => AXI_RVALID,
        m_axi_lite_rdata => AXI_RDATA,
        m_axi_lite_rresp => AXI_RRESP,
        m_axi_lite_awready => AXI_AWREADY,
        m_axi_lite_awvalid => AXI_AWVALID,
        m_axi_lite_awaddr => AXI_AWADDR,
        m_axi_lite_wready => AXI_WREADY,
        m_axi_lite_wvalid => AXI_WVALID,
        m_axi_lite_wdata => AXI_WDATA,
        m_axi_lite_wstrb => AXI_WSTRB,
        m_axi_lite_bready => AXI_BREADY,
        m_axi_lite_bvalid => AXI_BVALID,
        m_axi_lite_bresp => AXI_BRESP
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

