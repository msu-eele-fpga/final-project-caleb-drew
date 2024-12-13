
els
--ready_flag is active high

--If a new write is requested

--LCD is ready for the next write

--Disable ready flag
--Disable enable latch
--Set enable pin low
else
--do nothing waiting for latch to complete. 
end if;
else
--Really do nothing, the LCD isn't ready for another instruction 
end if;
elsif not enable_latch_delay then --TODO: Fix logic
--Set enable bit
latch <= '1';
elsif done_delay then
ready_flag   <= '1';
enable_delay <= false;
busy_flag    <= '0';
end if;

-------------------
proc_lcd_write : process (clk, reset, done_delay)
begin
  if reset = '1' then
    output_register <= "00000000";
    rs              <= '0';
    latch           <= '0';
    busy_flag       <= '0';
  elsif write_enable = '1' then
    if (ready_flag = '1' and done_latch) then
      if rising_edge(clk) then
        --Output LCD data
        rs              <= write_register(8);
        output_register <= write_register(7 downto 0);
        --Set flags
        ready_flag <= '0';
        busy_flag  <= '1';
        --Disable enable pin latch
        enable_latch_delay <= false;
        latch              <= '0';
        --Start write delay 
        enable_delay <= true;
      end if;
      --Already requires write_enable = 1
    elsif (ready_flag = '1' and enable_latch_delay = false) then
      enable_latch_delay <= true;

      --Already requires write_enable = 1
    elsif (done_delay) then
      --Done writing, ready to disable system
      --Reset flags
      busy_flag  <= '0';
      ready_flag <= '1';
    end if; --End of section requiring write_enable = 1
  end if; --If not write_enable = 1 then do nothing. 
end process;

--Old process
proc_lcd_write : process (clk, reset, ready_flag)
begin
  if reset = '1' then
    output_register <= "00000000";
    rs              <= '0';
    latch           <= '0';
    busy_flag       <= '0';
  elsif rising_edge(clk) then
    --ready_flag is active high
    if write_enable = '1' then
      if ready_flag = '1' then
        --If a new write is requested
        if done_latch then
          --LCD is ready for the next write
          rs              <= write_register(8);
          output_register <= write_register(7 downto 0);
          enable_delay    <= true;
          --Disable ready flag
          --Disable enable latch
          --Set enable pin low
          ready_flag         <= '0';
          busy_flag          <= '1';
          enable_latch_delay <= false;
          latch              <= '0';
        end if;
      else
        --do nothing waiting for latch to complete. 
      end if;
    else
      --Really do nothing, the LCD isn't ready for another instruction 
    end if;
  elsif not enable_latch_delay then --TODO: Fix logic
    enable_latch_delay <= true;
    --Set enable bit
    latch <= '1';
  elsif done_delay then
    ready_flag   <= '1';
    enable_delay <= false;
    busy_flag    <= '0';
  end if;
end process;