transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/CP1/hdl {/home/sphan5/Pied-Piper/CP1/hdl/rv32i_mux_types.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/CP1/hdl {/home/sphan5/Pied-Piper/CP1/hdl/regfile.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/CP1/hdl {/home/sphan5/Pied-Piper/CP1/hdl/pc_reg.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/CP1/hdl {/home/sphan5/Pied-Piper/CP1/hdl/rv32i_types.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/CP1/hdl {/home/sphan5/Pied-Piper/CP1/hdl/pipeline_stage.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/CP1/hdl {/home/sphan5/Pied-Piper/CP1/hdl/datapath.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/CP1/hdl {/home/sphan5/Pied-Piper/CP1/hdl/control_rom.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/CP1/hdl {/home/sphan5/Pied-Piper/CP1/hdl/cmp.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/CP1/hdl {/home/sphan5/Pied-Piper/CP1/hdl/alu.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/CP1/hdl {/home/sphan5/Pied-Piper/CP1/hdl/mp4.sv}

vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/CP1/hvl {/home/sphan5/Pied-Piper/CP1/hvl/magic_dual_port.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/CP1/hvl {/home/sphan5/Pied-Piper/CP1/hvl/param_memory.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/CP1/hvl {/home/sphan5/Pied-Piper/CP1/hvl/rvfi_itf.sv}
vlog -vlog01compat -work work +incdir+/home/sphan5/Pied-Piper/CP1/hvl {/home/sphan5/Pied-Piper/CP1/hvl/rvfimon.v}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/CP1/hvl {/home/sphan5/Pied-Piper/CP1/hvl/shadow_memory.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/CP1/hvl {/home/sphan5/Pied-Piper/CP1/hvl/source_tb.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/CP1/hvl {/home/sphan5/Pied-Piper/CP1/hvl/tb_itf.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/CP1/hvl {/home/sphan5/Pied-Piper/CP1/hvl/top.sv}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L arriaii_hssi_ver -L arriaii_pcie_hip_ver -L arriaii_ver -L rtl_work -L work -voptargs="+acc"  mp4_tb

add wave *
view structure
view signals
run -all
