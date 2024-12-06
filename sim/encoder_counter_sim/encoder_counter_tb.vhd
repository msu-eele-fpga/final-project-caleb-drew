library ieee;
use ieee.std_logic_1164.all;
use work.print_pkg.all;
use work.assert_pkg.all;
use work.tb_pkg.all;

entity encoder_counter_tb is
end entity encoder_counter_tb;
architecture encoder_counter_tb_arch of encoder_counter_tb is

  component encoder_counter is
    port (
      clk    : in std_logic;
      rst    : in std_logic;
      input  : in std_logic_vector(1 downto 0); -- "AB" input wiring
      counts : out integer
    );
  end component;

  signal clk_tb    : std_logic := '0';
  signal rst_tb    : std_logic := '0';
  signal input_tb  : std_logic_vector(1 downto 0);
  signal counts_tb : integer := 0;

begin

  encoder_counter_inst : encoder_counter
  port map(
    clk    => clk_tb,
    rst    => rst_tb,
    input  => input_tb,
    counts => counts_tb
  );

  clk_tb <= not clk_tb after CLK_PERIOD / 2;

  testing : process is
  begin
    input_tb <= "00";
    wait_for_clock_edges(clk_tb, 100);
    input_tb <= "10";
    wait_for_clock_edges(clk_tb, 50);
    input_tb <= "11";
    wait_for_clock_edges(clk_tb, 50);
    input_tb <= "01";
    wait_for_clock_edges(clk_tb, 50);
    input_tb <= "00";
    wait_for_clock_edges(clk_tb, 50);
    input_tb <= "01";
    wait_for_clock_edges(clk_tb, 50);
    input_tb <= "11";
    wait_for_clock_edges(clk_tb, 50);
    std.env.finish;
  end process;
end architecture;