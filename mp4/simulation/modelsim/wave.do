onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /mp4_tb/f
add wave -noupdate /mp4_tb/f
add wave -noupdate /mp4_tb/f
add wave -noupdate /mp4_tb/f
add wave -noupdate /mp4_tb/dut/datapath/pc_out
add wave -noupdate -expand -subitemconfig {/mp4_tb/dut/datapath/IF_ID_i.ControlWord -expand /mp4_tb/dut/datapath/IF_ID_i.DataWord -expand} /mp4_tb/dut/datapath/IF_ID_i
add wave -noupdate -expand -subitemconfig {/mp4_tb/dut/datapath/IF_ID_o.ControlWord -expand /mp4_tb/dut/datapath/IF_ID_o.DataWord -expand} /mp4_tb/dut/datapath/IF_ID_o
add wave -noupdate -expand -subitemconfig {/mp4_tb/dut/datapath/ID_EX_o.ControlWord -expand /mp4_tb/dut/datapath/ID_EX_o.DataWord -expand} /mp4_tb/dut/datapath/ID_EX_o
add wave -noupdate /mp4_tb/dut/data_wdata_dp
add wave -noupdate -expand /mp4_tb/dut/data_cache/datapath/DM_cache/data
add wave -noupdate -expand -subitemconfig {/mp4_tb/dut/datapath/EX_MEM_o.ControlWord -expand /mp4_tb/dut/datapath/EX_MEM_o.DataWord -expand} /mp4_tb/dut/datapath/EX_MEM_o
add wave -noupdate -expand -subitemconfig {/mp4_tb/dut/datapath/MEM_WB_o.ControlWord -expand /mp4_tb/dut/datapath/MEM_WB_o.DataWord -expand} /mp4_tb/dut/datapath/MEM_WB_o
add wave -noupdate {/mp4_tb/dut/datapath/regfile/data[0]}
add wave -noupdate {/mp4_tb/dut/datapath/regfile/data[1]}
add wave -noupdate {/mp4_tb/dut/datapath/regfile/data[2]}
add wave -noupdate {/mp4_tb/dut/datapath/regfile/data[3]}
add wave -noupdate {/mp4_tb/dut/datapath/regfile/data[4]}
add wave -noupdate {/mp4_tb/dut/datapath/regfile/data[5]}
add wave -noupdate -expand -group regfile /mp4_tb/dut/datapath/regfile/clk
add wave -noupdate -expand -group regfile /mp4_tb/dut/datapath/regfile/rst
add wave -noupdate -expand -group regfile /mp4_tb/dut/datapath/regfile/load
add wave -noupdate -expand -group regfile /mp4_tb/dut/datapath/regfile/in
add wave -noupdate -expand -group regfile /mp4_tb/dut/datapath/regfile/src_a
add wave -noupdate -expand -group regfile /mp4_tb/dut/datapath/regfile/src_b
add wave -noupdate -expand -group regfile /mp4_tb/dut/datapath/regfile/dest
add wave -noupdate -expand -group regfile /mp4_tb/dut/datapath/regfile/reg_a
add wave -noupdate -expand -group regfile /mp4_tb/dut/datapath/regfile/reg_b
add wave -noupdate -expand -group ALU /mp4_tb/dut/datapath/ALU/aluop
add wave -noupdate -expand -group ALU /mp4_tb/dut/datapath/ALU/a
add wave -noupdate -expand -group ALU /mp4_tb/dut/datapath/ALU/b
add wave -noupdate -expand -group ALU /mp4_tb/dut/datapath/ALU/f
add wave -noupdate -expand -group FU /mp4_tb/dut/datapath/fu/dest_ex_mem
add wave -noupdate -expand -group FU /mp4_tb/dut/datapath/fu/dest_mem_wb
add wave -noupdate -expand -group FU /mp4_tb/dut/datapath/fu/src1
add wave -noupdate -expand -group FU /mp4_tb/dut/datapath/fu/src2
add wave -noupdate -expand -group FU /mp4_tb/dut/datapath/fu/data_ex_mem
add wave -noupdate -expand -group FU /mp4_tb/dut/datapath/fu/data_mem_wb
add wave -noupdate -expand -group FU /mp4_tb/dut/datapath/fu/data_mdr
add wave -noupdate -expand -group FU /mp4_tb/dut/datapath/fu/ld_regfile_ex_mem
add wave -noupdate -expand -group FU /mp4_tb/dut/datapath/fu/ld_regfile_mem_wb
add wave -noupdate -expand -group FU /mp4_tb/dut/datapath/fu/dmem_read
add wave -noupdate -expand -group FU /mp4_tb/dut/datapath/fu/alumux1_sel
add wave -noupdate -expand -group FU /mp4_tb/dut/datapath/fu/alumux2_sel
add wave -noupdate -expand -group FU /mp4_tb/dut/datapath/fu/cmpmux2_sel
add wave -noupdate -expand -group FU /mp4_tb/dut/datapath/fu/ex_mem_forwarding_out1
add wave -noupdate -expand -group FU /mp4_tb/dut/datapath/fu/mem_wb_forwarding_out1
add wave -noupdate -expand -group FU /mp4_tb/dut/datapath/fu/ex_mem_forwarding_out2
add wave -noupdate -expand -group FU /mp4_tb/dut/datapath/fu/mem_wb_forwarding_out2
add wave -noupdate -expand -group FU /mp4_tb/dut/datapath/fu/ex_mem_forwarding_cmp1out
add wave -noupdate -expand -group FU /mp4_tb/dut/datapath/fu/mem_wb_forwarding_cmp1out
add wave -noupdate -expand -group FU /mp4_tb/dut/datapath/fu/ex_mem_forwarding_cmp2out
add wave -noupdate -expand -group FU /mp4_tb/dut/datapath/fu/mem_wb_forwarding_cmp2out
add wave -noupdate -expand -group FU /mp4_tb/dut/datapath/fu/forwarding_load1
add wave -noupdate -expand -group FU /mp4_tb/dut/datapath/fu/forwarding_load2
add wave -noupdate -expand -group FU /mp4_tb/dut/datapath/fu/forwarding_cmp1_load
add wave -noupdate -expand -group FU /mp4_tb/dut/datapath/fu/forwarding_cmp2_load
add wave -noupdate -expand -group FU /mp4_tb/dut/datapath/fu/forwarding_mux1
add wave -noupdate -expand -group FU /mp4_tb/dut/datapath/fu/forwarding_mux2
add wave -noupdate -expand -group FU /mp4_tb/dut/datapath/fu/forwarding_cmp1mux
add wave -noupdate -expand -group FU /mp4_tb/dut/datapath/fu/forwarding_cmp2mux
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1405496 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 431
configure wave -valuecolwidth 119
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
configure wave -timelineunits ns
update
WaveRestoreZoom {1400381 ps} {1434367 ps}
