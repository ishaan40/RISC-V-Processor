transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/mp4/hdl {/home/sphan5/Pied-Piper/mp4/hdl/cacheline_adaptor.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/mp4/hdl/given_cache {/home/sphan5/Pied-Piper/mp4/hdl/given_cache/line_adapter.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/mp4/hdl/given_cache {/home/sphan5/Pied-Piper/mp4/hdl/given_cache/data_array.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/mp4/hdl/given_cache {/home/sphan5/Pied-Piper/mp4/hdl/given_cache/cache_datapath.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/mp4/hdl/given_cache {/home/sphan5/Pied-Piper/mp4/hdl/given_cache/cache_control.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/mp4/hdl/given_cache {/home/sphan5/Pied-Piper/mp4/hdl/given_cache/array.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/mp4/hdl {/home/sphan5/Pied-Piper/mp4/hdl/rv32i_mux_types.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/mp4/hdl {/home/sphan5/Pied-Piper/mp4/hdl/regfile.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/mp4/hdl {/home/sphan5/Pied-Piper/mp4/hdl/pc_reg.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/mp4/hdl/given_cache {/home/sphan5/Pied-Piper/mp4/hdl/given_cache/cache.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/mp4/hdl {/home/sphan5/Pied-Piper/mp4/hdl/rv32i_types.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/mp4/hdl {/home/sphan5/Pied-Piper/mp4/hdl/forwarding_unit.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/mp4/hdl {/home/sphan5/Pied-Piper/mp4/hdl/hazard_detection.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/mp4/hdl {/home/sphan5/Pied-Piper/mp4/hdl/arbiter.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/mp4/hdl {/home/sphan5/Pied-Piper/mp4/hdl/pipeline_stage.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/mp4/hdl {/home/sphan5/Pied-Piper/mp4/hdl/datapath.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/mp4/hdl {/home/sphan5/Pied-Piper/mp4/hdl/control_rom.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/mp4/hdl {/home/sphan5/Pied-Piper/mp4/hdl/cmp.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/mp4/hdl {/home/sphan5/Pied-Piper/mp4/hdl/alu.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/mp4/hdl {/home/sphan5/Pied-Piper/mp4/hdl/mp4.sv}

vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/mp4/hvl {/home/sphan5/Pied-Piper/mp4/hvl/magic_dual_port.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/mp4/hvl {/home/sphan5/Pied-Piper/mp4/hvl/param_memory.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/mp4/hvl {/home/sphan5/Pied-Piper/mp4/hvl/rvfi_itf.sv}
vlog -vlog01compat -work work +incdir+/home/sphan5/Pied-Piper/mp4/hvl {/home/sphan5/Pied-Piper/mp4/hvl/rvfimon.v}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/mp4/hvl {/home/sphan5/Pied-Piper/mp4/hvl/shadow_memory.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/mp4/hvl {/home/sphan5/Pied-Piper/mp4/hvl/source_tb.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/mp4/hvl {/home/sphan5/Pied-Piper/mp4/hvl/tb_itf.sv}
vlog -sv -work work +incdir+/home/sphan5/Pied-Piper/mp4/hvl {/home/sphan5/Pied-Piper/mp4/hvl/top.sv}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L arriaii_hssi_ver -L arriaii_pcie_hip_ver -L arriaii_ver -L rtl_work -L work -voptargs="+acc"  mp4_tb

add wave *
view structure
view signals
run -all
