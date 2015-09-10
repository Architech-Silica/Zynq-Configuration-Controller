library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library axi_FPGA_configuration_controller;
use axi_FPGA_configuration_controller.FPGA_configuration_controller_pkg.all;

entity axi_FPGA_configuration_controller is
    generic
        (
        -- AXI Parameters
        C_S_AXI_ACLK_FREQ_HZ  : integer := 100_000_000;
        C_S_AXI_DATA_WIDTH : integer := 32;
        C_S_AXI_ADDR_WIDTH : integer := 8;  
        -- Config controller Parameters
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
        CONFIG_DATA                         : inout STD_LOGIC_VECTOR(CONFIG_DATA_WIDTH-1 downto 0);
        CONFIG_CSI_B                        : out STD_LOGIC_VECTOR(NUMBER_OF_FPGAS_IN_CHAIN-1 downto 0);
        CONFIG_RDWR_B                       : out STD_LOGIC;
        CONFIG_PROGB                        : inout STD_LOGIC;
        CONFIG_INITB                        : inout STD_LOGIC;
        CONFIG_DONE                         : inout STD_LOGIC
        );
end axi_FPGA_configuration_controller;


architecture Behavioral of axi_FPGA_configuration_controller is

component FPGA_configuration_controller is
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
end component;

-- Type declarations
type main_fsm_type is (reset, idle, read_transaction_in_progress, write_transaction_in_progress, complete);

-- Timing Constants
constant Clk_Period_NS : integer := 1000000000 / C_S_AXI_ACLK_FREQ_HZ;

-- Set the width of the software reset pulse in clock cycles here
constant SW_RESET_REG_VALUE : integer := 255;


-- Signal declarations
signal local_address : integer range 0 to 2**C_S_AXI_ADDR_WIDTH;
signal local_address_valid : std_logic;
signal bistream_data_register : std_logic_vector(31 downto 0);
signal control_register : std_logic_vector(31 downto 0);
signal status_register : std_logic_vector(31 downto 0);
signal abort_status_register : std_logic_vector(31 downto 0);
signal bitstream_length_register : std_logic_vector(31 downto 0);
signal bits_sent_register : std_logic_vector(31 downto 0);
signal chain_ID_register : std_logic_vector(31 downto 0);
signal software_reset_register : integer range 0 to SW_RESET_REG_VALUE+1 := 0;
signal bitstream_data_register_address_valid : std_logic;
signal control_register_address_valid : std_logic;
signal status_register_address_valid : std_logic;
signal abort_status_register_address_valid : std_logic;
signal bitstream_length_register_address_valid : std_logic;
signal bits_sent_register_address_valid : std_logic;
signal chain_ID_register_address_valid : std_logic;
signal software_reset_register_address_valid : std_logic;
signal combined_S_AXI_AWVALID_S_AXI_ARVALID : std_logic_vector(1 downto 0);
signal Local_Reset : std_logic;
signal current_state, next_state : main_fsm_type := reset;
signal write_enable_registers : std_logic;
signal send_read_data_to_AXI : std_logic;
signal software_reset : std_logic;

signal internal_CONFIG_DATA : std_logic_vector(31 downto 0);


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
signal data_fifo_empty             : STD_LOGIC;
signal total_bits_sent             : STD_LOGIC_VECTOR(31 downto 0);
           
begin

Local_Reset <= (not S_AXI_ARESETN) or software_reset;
combined_S_AXI_AWVALID_S_AXI_ARVALID <= S_AXI_AWVALID & S_AXI_ARVALID;

-- Generate a reset signal from the software_reset_register
software_reset <= '1' when software_reset_register < SW_RESET_REG_VALUE else '0';

-- Map registers to FPGA controller signals
go <= control_register(0);                     
abort <= control_register(1);                 
bitstream_length_bits <= bitstream_length_register;
chain_ID_to_configure <= chain_ID_register(4 downto 0);
data_in <= bistream_data_register;               
data_in_valid <= bitstream_data_register_address_valid;          
CONFIG_DATA <= internal_CONFIG_DATA(CONFIG_DATA_WIDTH-1 downto 0);



state_machine_update : process (S_AXI_ACLK)
begin
    if S_AXI_ACLK'event and S_AXI_ACLK = '1' then
        if Local_Reset = '1' then
            current_state <= reset;
        else
            current_state <= next_state;
        end if;
    end if;
end process;

state_machine_decisions : process (	current_state, combined_S_AXI_AWVALID_S_AXI_ARVALID, S_AXI_ARVALID, S_AXI_RREADY, S_AXI_AWVALID, S_AXI_WVALID, S_AXI_BREADY, local_address, local_address_valid)
begin
    S_AXI_ARREADY <= '0';
    S_AXI_RRESP <= "--";
    S_AXI_RVALID <= '0';
    S_AXI_WREADY <= '0';
    S_AXI_BRESP <= "--";
    S_AXI_BVALID <= '0';
    S_AXI_WREADY <= '0';
    S_AXI_AWREADY <= '0';
    write_enable_registers <= '0';
    send_read_data_to_AXI <= '0';
   
	case current_state is
		when reset =>
			next_state <= idle;

		when idle =>
			next_state <= idle;
			case combined_S_AXI_AWVALID_S_AXI_ARVALID is
				when "01" => next_state <= read_transaction_in_progress;
				when "10" => next_state <= write_transaction_in_progress;
				when others => NULL;
			end case;
		
		when read_transaction_in_progress =>
            next_state <= read_transaction_in_progress;
            S_AXI_ARREADY <= S_AXI_ARVALID;
            S_AXI_RVALID <= '1';
            S_AXI_RRESP <= "00";
            send_read_data_to_AXI <= '1';
            if S_AXI_RREADY = '1' then
                next_state <= complete;
            end if;

		when write_transaction_in_progress =>
            next_state <= write_transaction_in_progress;
			write_enable_registers <= '1';
            S_AXI_AWREADY <= S_AXI_AWVALID;
            S_AXI_WREADY <= S_AXI_WVALID;
            S_AXI_BRESP <= "00";
            S_AXI_BVALID <= '1';
			if S_AXI_BREADY = '1' then
			    next_state <= complete;
            end if;

		when complete => 
			case combined_S_AXI_AWVALID_S_AXI_ARVALID is
				when "00" => next_state <= idle;
				when others => next_state <= complete;
			end case;
		
		when others =>
			next_state <= reset;
	end case;
end process;

local_address_capture_register : process (S_AXI_ACLK)
begin
   if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
        if Local_Reset = '1' then
            local_address <= 0;
        else
            if local_address_valid = '1' then
                case (combined_S_AXI_AWVALID_S_AXI_ARVALID) is
                    when "10" => local_address <= to_integer(unsigned(S_AXI_AWADDR(C_S_AXI_ADDR_WIDTH-1 downto 0)));
                    when "01" => local_address <= to_integer(unsigned(S_AXI_ARADDR(C_S_AXI_ADDR_WIDTH-1 downto 0)));
                    when others => local_address <= local_address;
                end case;
            end if;
        end if;
   end if;
end process;
       
bistream_data_register_process : process (S_AXI_ACLK)
begin
    if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
        if Local_Reset = '1' then
            bistream_data_register <= (others => '0');
        else
            if (bitstream_data_register_address_valid = '1') then
                for i in 0 to 3 loop
                    if S_AXI_WSTRB(i) = '1' then
                        bistream_data_register((8*i)+7 downto (i*8)) <= S_AXI_WDATA((8*i)+7 downto (i*8));
                    end if;
                end loop;
            end if;
        end if;
    end if;
end process;



control_register_process : process (S_AXI_ACLK)
begin
    if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
        if Local_Reset = '1' then
            control_register <= (others => '0');
        else
            if (control_register_address_valid = '1') then
                for i in 0 to 3 loop
                    if S_AXI_WSTRB(i) = '1' then
                        control_register((8*i)+7 downto (i*8)) <= S_AXI_WDATA((8*i)+7 downto (i*8));
                    end if;
                end loop;
            end if;
        end if;
    end if;
end process;


status_register_process : process (S_AXI_ACLK)
begin
    if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
        if Local_Reset = '1' then
            status_register <= (others => '0');
        else
            for bit_index in 0 to 31 loop
                case bit_index is
                    when 0 => status_register(bit_index) <= done;
                    when 1 => status_register(bit_index) <= running;
                    when 2 => status_register(bit_index) <= error;
                    when 3 => status_register(bit_index) <= aborted;
                    when 4 => status_register(bit_index) <= data_fifo_full;
                    when 5 => status_register(bit_index) <= data_fifo_almost_full;
                    when 6 => status_register(bit_index) <= data_fifo_empty;
                    when others => status_register(bit_index) <= '0';
                end case;
            end loop;
        end if;
    end if;
end process;


abort_status_register_process : process (S_AXI_ACLK)
begin
    if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
        if Local_Reset = '1' then
            abort_status_register <= (others => '0');
        else
            abort_status_register <= abort_status;
        end if;
    end if;
end process;

bitstream_length_register_process : process (S_AXI_ACLK)
begin
    if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
        if Local_Reset = '1' then
            bitstream_length_register <= (others => '0');
        else
            if (bitstream_length_register_address_valid = '1') then
                for i in 0 to 3 loop
                    if S_AXI_WSTRB(i) = '1' then
                        bitstream_length_register((8*i)+7 downto (i*8)) <= S_AXI_WDATA((8*i)+7 downto (i*8));
                    end if;
                end loop;
            end if;
        end if;
    end if;
end process;

bits_sent_register_process : process (S_AXI_ACLK)
begin
    if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
        if Local_Reset = '1' then
            bits_sent_register <= (others => '0');
        else
            bits_sent_register <= total_bits_sent;
        end if;
    end if;
end process;

chain_ID_register_process : process (S_AXI_ACLK)
begin
    if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
        if Local_Reset = '1' then
            chain_ID_register <= (others => '0');
        else
            if (chain_ID_register_address_valid = '1') then
                for i in 0 to 3 loop
                    if S_AXI_WSTRB(i) = '1' then
                        chain_ID_register((8*i)+7 downto (i*8)) <= S_AXI_WDATA((8*i)+7 downto (i*8));
                    end if;
                end loop;
            end if;
        end if;
    end if;
end process;


software_reset_register_process : process (S_AXI_ACLK)
begin
    if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
        if S_AXI_ARESETN = '0' then
            software_reset_register <= 0;
        else
            if (software_reset_register_address_valid = '1') then
                if S_AXI_WSTRB(0) = '1' then
                    software_reset_register <= 0;
                end if;
            elsif software_reset_register < SW_RESET_REG_VALUE then
                software_reset_register <= software_reset_register + 1;
            end if;
        end if;
    end if;
end process;


address_range_analysis : process (local_address, write_enable_registers)
begin
    control_register_address_valid <= '0';           
    status_register_address_valid <= '0';            
    abort_status_register_address_valid <= '0';      
    bitstream_length_register_address_valid <= '0'; 
    bits_sent_register_address_valid <= '0';        
    chain_ID_register_address_valid <= '0';         
    software_reset_register_address_valid <= '0';   
    bitstream_data_register_address_valid <= '0';
    local_address_valid <= '1';
    
    if write_enable_registers = '1' then
        case (local_address) is
            when 0  =>      bitstream_data_register_address_valid <= '1';
            when 4  =>      control_register_address_valid <= '1';
            when 8  =>      status_register_address_valid <= '1';
            when 12 =>      abort_status_register_address_valid <= '1';
            when 16 =>      bitstream_length_register_address_valid <= '1';
            when 20 =>      bits_sent_register_address_valid <= '1';
            when 24 =>      chain_ID_register_address_valid <= '1';
            when 28 =>      software_reset_register_address_valid <= '1';
            when others =>  local_address_valid <= '0';
        end case;
    end if;
end process;

send_data_to_AXI_RDATA : process (  send_read_data_to_AXI, software_reset_register, local_address, local_address_valid, send_read_data_to_AXI, control_register,
                                    status_register, abort_status_register, bitstream_length_register, bits_sent_register, chain_ID_register )
begin
    S_AXI_RDATA <= (others => '0');
    if (local_address_valid = '1' and send_read_data_to_AXI = '1') then
        case (local_address) is
            when 0  => S_AXI_RDATA <= X"DA7ADA7A";           
            when 4  => S_AXI_RDATA <= control_register;           
            when 8  => S_AXI_RDATA <= status_register;            
            when 12 => S_AXI_RDATA <= abort_status_register;      
            when 16 => S_AXI_RDATA <= bitstream_length_register;  
            when 20 => S_AXI_RDATA <= bits_sent_register;         
            when 24 => S_AXI_RDATA <= chain_ID_register;          
            when 28 => S_AXI_RDATA <= std_logic_vector(to_unsigned(software_reset_register, 32));    
            when others => NULL;                  
        end case;
    end if;
end process;


-- Instantiate the FPGA configuration controller
FPGA_configuration_controller_instance : FPGA_configuration_controller
    GENERIC MAP
		(
        clock_period_ns => CLK_period_NS,
        CONFIG_CLK_FREQ_HZ => CONFIG_CLK_FREQ_HZ,
        CONFIG_DATA_WIDTH => CONFIG_DATA_WIDTH,
        AES_SECURE_CONFIG => AES_SECURE_CONFIG,
        CONFIG_DATA_IS_BIT_SWAPPED => CONFIG_DATA_IS_BIT_SWAPPED,
        NUMBER_OF_FPGAS_IN_CHAIN => NUMBER_OF_FPGAS_IN_CHAIN
 		)
	PORT MAP
		(
        clk => S_AXI_ACLK,
        rst => Local_Reset,
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
        data_fifo_empty => data_fifo_empty,
        total_bits_sent => total_bits_sent,
        CONFIG_CCLK => CONFIG_CCLK,
        CONFIG_DATA => internal_CONFIG_DATA,
        CONFIG_CSI_B => CONFIG_CSI_B,
        CONFIG_RDWR_B => CONFIG_RDWR_B,
        CONFIG_PROGB => CONFIG_PROGB,
        CONFIG_INITB => CONFIG_INITB,
        CONFIG_DONE => CONFIG_DONE
        );
        
end Behavioral;
