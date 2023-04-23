import rv32i_types::*; 
module mp4_tb;
`timescale 1ns/10ps

/********************* Do not touch for proper compilation *******************/
// Instantiate Interfaces
tb_itf itf();
rvfi_itf rvfi(itf.clk, itf.rst);

// Instantiate Testbench
source_tb tb(
    .magic_mem_itf(itf),
    .mem_itf(itf),
    .sm_itf(itf),
    .tb_itf(itf),
    .rvfi(rvfi)
);

// For local simulation, add signal for Modelsim to display by default
// Note that this signal does nothing and is not used for anything
bit f;

/****************************** End do not touch *****************************/

/************************ Signals necessary for monitor **********************/
// This section not required until CP2

assign rvfi.commit = 0; // Set high when a valid instruction is modifying regfile or PC
// Set high when you detect an infinite loop and there's only nop's after the execution stage
assign rvfi.halt = dut.datapath.load_pc && (dut.datapath.pc_out == dut.datapath.EX_MEM_stage.data.DataWord.pc) &&
                   (dut.datapath.MEM_WB_stage.data.ControlWord.opcode == 0) && 
                   (dut.datapath.EX_MEM_stage.data.ControlWord.br_en == 1 || 
                   dut.datapath.EX_MEM_stage.data.ControlWord.opcode == op_jal ||
                   dut.datapath.EX_MEM_stage.data.ControlWord.opcode == op_jalr);
// assign rvfi.halt = 0;
initial rvfi.order = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO

/*
The following signals need to be set:
Instruction and trap:
    rvfi.inst
    rvfi.trap

Regfile:
    rvfi.rs1_addr
    rvfi.rs2_add
    rvfi.rs1_rdata
    rvfi.rs2_rdata
    rvfi.load_regfile
    rvfi.rd_addr
    rvfi.rd_wdata

PC:
    rvfi.pc_rdata
    rvfi.pc_wdata

Memory:
    rvfi.mem_addr
    rvfi.mem_rmask
    rvfi.mem_wmask
    rvfi.mem_rdata
    rvfi.mem_wdata

Please refer to rvfi_itf.sv for more information.
*/

/**************************** End RVFIMON signals ****************************/

/********************* Assign Shadow Memory Signals Here *********************/
// This section not required until CP2
/*
The following signals need to be set:
icache signals:
    itf.inst_read
    itf.inst_addr
    itf.inst_resp
    itf.inst_rdata

dcache signals:
    itf.data_read
    itf.data_write
    itf.data_mbe
    itf.data_addr
    itf.data_wdata
    itf.data_resp
    itf.data_rdata

Please refer to tb_itf.sv for more information.
*/

/*********************** End Shadow Memory Assignments ***********************/

// Set this to the proper value
assign itf.registers = '{default: '0};

/*********************** Instantiate your design here ************************/
/*
The following signals need to be connected to your top level:
Clock and reset signals:
    itf.clk
    itf.rst

Burst Memory Ports:
    itf.mem_read
    itf.mem_write
    itf.mem_wdata
    itf.mem_rdata
    itf.mem_addr
    itf.mem_resp

Please refer to tb_itf.sv for more information.
*/

mp4 dut(    
    .clk(itf.clk),
    .rst(itf.rst),
    .mem_rdata(itf.mem_rdata), 
    .mem_resp(itf.mem_resp), 
    .mem_wdata(itf.mem_wdata), 
    .mem_write(itf.mem_write), 
    .mem_read(itf.mem_read), 
    .mem_addr(itf.mem_addr));



/***************************** End Instantiation *****************************/

endmodule
