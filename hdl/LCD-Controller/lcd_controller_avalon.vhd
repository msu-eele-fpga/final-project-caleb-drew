library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lcd_avalon_interface is
  port (
    --Basic inputs
    clk   : in std_logic;
    reset : in std_logic;
    --Avalon interface flags
    avs_read  : in std_logic;
    avs_write : in std_logic;
    --Avalon interface registers
    avs_address   : in std_logic_vector(1 downto 0);
    avs_readdata  : out std_logic_vector(31 downto 0);
    avs_writedata : in std_logic_vector(31 downto 0);
    --External IO
    --This combines the databits, RS, and Enable bits all into one output register
    lcd_output : out std_logic_vector(9 downto 0)
  );
end entity lcd_avalon_interface;

architecture lcd_avalon_interface_arch of lcd_avalon_interface is
  component lcd_controller
    generic (
      --Needed for timed counter to create data only when ready on the LCD
      CLK_PERIOD : time := 20 ns
    );
    port (
      --Basic clock and reset input
      clk   : in std_logic;
      reset : in std_logic;
      --LCD Specific inputs
      write_register : in std_logic_vector(8 downto 0);
      --Write enable 
      write_enable    : in std_logic;
      output_register : out std_logic_vector(7 downto 0);
      rs              : out std_logic;
      latch           : out std_logic;
      busy_flag       : out std_logic
    );
  end component;
  --Registers needed:
  --1. write register
  --2. Read of busy flag
  --
  signal lcd_data_register  : std_logic_vector (31 downto 0) := (others => '0');
  signal busy_flag_register : std_logic_vector(31 downto 0)  := (others => '0');

  --Internal write enable signal
  signal write_enable : std_logic := '0';
  --Internal signal to track when the system is ready to write again
  signal internal_busy_flag : std_logic;

begin
  --Map busy flag
  busy_flag_register(0) <= internal_busy_flag;
  --Create LCD component
  LCD : component lcd_controller
    port map(
      clk   => clk,
      reset => reset,
      --Register of data coming in from avalon
      write_register => lcd_data_register(8 downto 0),
      --Write control logic 
      write_enable => write_enable,
      --Outputs 
      output_register => lcd_output(7 downto 0),
      rs              => lcd_output(8),
      latch           => lcd_output(9),
      busy_flag       => internal_busy_flag
    );
    --Reading from the registers 
    avalon_register_read : process (clk)
    begin
      if (rising_edge(clk) and avs_read = '1') then
        case(avs_address) is
          when "00" => avs_readdata   <= busy_flag_register;
          when "01" => avs_readdata   <= lcd_data_register;
          when others => avs_readdata <= (others => '0');
        end case;
      end if;
    end process;
    --Writing timing control
    avalon_register_write : process (clk, internal_busy_flag)
    begin
      if (avs_write = '1' and internal_busy_flag <= '0') then
        write_enable                               <= '1';
        if rising_edge(clk) then
          case(avs_address) is
            when "00" => null;
            when "01" =>
            lcd_data_register <= avs_writedata(31 downto 0);
            when others => null;
          end case;
        end if;
      elsif (internal_busy_flag = '0' and avs_write = '0' and write_enable = '1') then
        write_enable <= '0';
      else
      end if;
    end process;
  end architecture lcd_avalon_interface_arch;