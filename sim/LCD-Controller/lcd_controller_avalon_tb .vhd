--Required packages
--Must be compiled with 2008 VHDL standard
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--class packages
use work.print_pkg.all;
use work.assert_pkg.all;

--Test bench package for delays
use work.tb_pkg.all;
entity lcd_avalon_tb is
end entity lcd_avalon_tb;

architecture testbench of lcd_avalon_tb is
  component lcd_avalon_interface is
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
  end component;
  --Basic signals 
  signal reset_tb     : std_logic := '1';
  signal clk_tb       : std_logic := '0';
  constant CLK_PERIOD : time      := 20 ns;

  --Interface signals
  --Inputs
  signal avs_write_tb     : std_logic                     := '0';
  signal avs_read_tb      : std_logic                     := '0';
  signal avs_address_tb   : std_logic_vector (1 downto 0) := (others => '0');
  signal avs_writedata_tb : std_logic_vector(31 downto 0) := (others => '0');

  --Outputs
  signal lcd_output_tb   : std_logic_vector(9 downto 0)  := (others => '0');
  signal avs_readdata_tb : std_logic_vector(31 downto 0) := (others => '0');
  ----------------------------------------------------------------------------------------
begin
  dut_lcd_avalon : component lcd_avalon_interface
    port map(
      --Basic inputs
      clk   => clk_tb,
      reset => reset_tb,
      --Avalon interface flags
      avs_read  => avs_read_tb,
      avs_write => avs_write_tb,
      --Avalon interface registers
      avs_address   => avs_address_tb,
      avs_readdata  => avs_readdata_tb,
      avs_writedata => avs_writedata_tb,
      --External IO
      --This combines the databits, RS, and Enable bits all into one output register
      lcd_output => lcd_output_tb
    );
    --Create clock
    clk_tb <= not clk_tb after CLK_PERIOD/2;

    stimuli_and_checker : process is
    begin
      reset_tb <= '1';
      wait_for_clock_edges(clk_tb, 5);
      reset_tb <= '0';
      print("Testing LCD timing for avalon bus");
      print("--Simulating a write operation of 0x0000000F to the LCD ie an ON command");
      avs_write_tb     <= '1';
      avs_address_tb   <= "01";
      avs_writedata_tb <= x"0000000F";
      wait_for_clock_edges(clk_tb, 1);
      avs_write_tb     <= '0';
      avs_writedata_tb <= x"00000000";
      avs_address_tb   <= "01";

      wait_for_clock_edges(clk_tb, 200000);
      print("Testing LCD timing for avalon bus");
      print("--Simulating a write operation of 0x0000000F to the LCD ie an ON command");
      avs_write_tb     <= '1';
      avs_address_tb   <= "01";
      avs_writedata_tb <= x"000000FF";
      wait_for_clock_edges(clk_tb, 1);
      avs_write_tb     <= '0';
      avs_writedata_tb <= x"00000000";
      avs_address_tb   <= "01";
      wait_for_clock_edges(clk_tb, 200000);
      reset_tb <= '1';
      --End testbench environment 
      std.env.finish;
    end process;
  end architecture;