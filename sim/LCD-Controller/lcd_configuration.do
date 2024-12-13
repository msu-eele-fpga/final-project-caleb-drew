onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {Test Bench}
add wave -noupdate -color Gray70 -label Clock /lcd_tb/clk_tb
add wave -noupdate -color Gray50 -label Reset /lcd_tb/reset_tb
add wave -noupdate -divider {lcd controller registers}
add wave -noupdate -color Green -label {Input Register} /lcd_tb/dut_lcd_controller/write_register
add wave -noupdate -color {Cornflower Blue} -label DB7-DB0 /lcd_tb/dut_lcd_controller/output_register
add wave -noupdate -label {LCD RS Bit} /lcd_tb/dut_lcd_controller/rs
add wave -noupdate -divider {lcd conttroller flags}
add wave -noupdate -color Yellow -label {Ready Flag} /lcd_tb/dut_lcd_controller/ready_flag
add wave -noupdate -color Yellow -label {Busy Flag} /lcd_tb/dut_lcd_controller/busy_flag
add wave -noupdate -color Cyan -label {Latch Delay Enable} /lcd_tb/dut_lcd_controller/enable_latch_delay
add wave -noupdate -color Cyan -label {Latch Complete} /lcd_tb/dut_lcd_controller/done_latch
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {18250 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 303
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits sec
update
WaveRestoreZoom {0 ps} {185129 ps}
