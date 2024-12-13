library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lcd_avalon_passthrough is
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
end entity lcd_avalon_passthrough;

architecture lcd_avalon_passthrough_arch of lcd_avalon_passthrough is
  --Tell system about the timed counter 
  component clock_divider
    port (
      --Basic signals 
      clk    : in std_logic;
      count  : in integer;
      enable : in boolean;
      --Output done signal
      done : out boolean
    );
  end component;
  --LCD Pin mappings
  component lcd_passthrough
    port (
      --Basic clock and reset input
      clk   : in std_logic;
      reset : in std_logic;
      --LCD Specific inputs
      write_register : in std_logic_vector(8 downto 0);
      --Write enable 
      output_register : out std_logic_vector(7 downto 0);
      rs              : out std_logic
    );
  end component;

  signal lcd_data_register : std_logic_vector (31 downto 0) := (others => '0');
  --Enable latch count constant
  constant LATCH_COUNT : integer   := 2500; --50 us in clock cycles
  signal latch_enable  : boolean   := false;
  signal latch_done    : boolean   := false;
  signal latch         : std_logic := '0';

begin
  lcd_output(9) <= latch;
  LCD : component lcd_passthrough
    port map(
      clk   => clk,
      reset => reset,
      --Register of data coming in from avalon
      write_register => lcd_data_register(8 downto 0),
      --Outputs 
      output_register => lcd_output(7 downto 0),
      rs              => lcd_output(8)
    );
    --Timer for latching enable pin
    latch_timer : clock_divider
    port map(
      clk    => clk,
      count  => LATCH_COUNT,
      enable => latch_enable,
      done   => latch_done
    );
    --Reading from the registers 
    avalon_register_read : process (clk)
    begin
      if (rising_edge(clk) and avs_read = '1') then
        case(avs_address) is
          when "00" => avs_readdata   <= lcd_data_register;
          when others => avs_readdata <= (others => '0');
        end case;
      end if;
    end process;
    --Writing timing control
    avalon_register_write : process (clk)
    begin
      if rising_edge(clk) then
        if avs_write = '1' then
          case(avs_address) is
            when "00" =>
            lcd_data_register <= avs_writedata(31 downto 0);
            latch_enable      <= true;
            latch             <= '1';
            when others => null;
          end case;
        elsif latch_done then
          latch        <= '0';
          latch_enable <= false;
        end if;
      end if;
    end process;
  end architecture lcd_avalon_passthrough_arch;