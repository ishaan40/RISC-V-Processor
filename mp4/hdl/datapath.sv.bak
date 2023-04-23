import rv32i_types::*; 

module datapath (
    input clk, 
    input rst, 
    /* Instruction memory interface */ 
    input  inst_resp,
    input  rv32i_word inst_rdata, 
    output inst_read, 
    output rv32i_word inst_addr, 
    /* Data memory interface */
    input data_resp, 
    input rv32i_word data_rdata, 
    output data_read,
    output data_write, 
    output [3:0] data_mbe, 
    output rv32i_word data_addr, 
    output rv32i_word data_wdata
);
/******************* Variables *******************/
rv32i_stage IF_ID_i; 
rv32i_stage IF_ID_o; 
rv32i_stage ID_EX_i; 
rv32i_stage ID_EX_o;
rv32i_stage EX_MEM_i; 
rv32i_stage EX_MEM_o;
rv32i_stage MEM_WB_i; 
rv32i_stage MEM_WB_o;
rv32i_word pc_out; 
rv32i_word pcmux_out; 
rv32i_word modmux_out; 
rv32i_word regfilemux_out; 
logic [1:0] mask_bits; 
rv32i_word alumux1_out; 
rv32i_word cmpmux_out; 


/******************* IF Stage *******************/
assign inst_read = 1'b1; 
assign inst_addr = pc_out; 
assign IF_ID_i.DataWord.pc = pc_out; 
assign IF_ID_i.DataWord.rs1 = inst_rdata[19:15]; 
assign IF_ID_i.DataWord.rs2 = inst_rdata[24:20]; 
assign IF_ID_i.DataWord.rd = inst_rdata[11:7]; 
/***** Determine what immediate will be used in the execute stage *****/
case(IF_ID_i.ControlWord.opcode) begin 
    op_jalr, op_load, op_imm:
        IF_ID_i.DataWord.imm = {{21{inst_rdata[31]}}, inst_rdata[30:20]};
    op_store:
        IF_ID_i.DataWord.imm = {{21{inst_rdata[31]}}, inst_rdata[30:25], inst_rdata[11:7]};
    op_br:
        IF_ID_i.DataWord.imm = {{20{inst_rdata[31]}}, inst_rdata[7], inst_rdata[30:25], inst_rdata[11:8], 1'b0};
    op_lui, op_auipc:
        IF_ID_i.DataWord.imm = {inst_rdata[31:12], 12'h000};
    op_jal:
        IF_ID_i.DataWord.imm = {{12{inst_rdata[31]}}, inst_rdata[19:12], inst_rdata[20], inst_rdata[30:21], 1'b0};
end 
/***** Modules *****/
control_rom ctrl_rom(.opcode(rv32i_opcode'(inst_rdata[6:0])), .funct3(inst_rdata[14:12]), 
                     .funct7(inst_rdata[31:25]), .ctrl_word(IF_ID_i.ControlWord));
                                         // Change load to pc later
pc_register pc_reg(.clk(clk), .rst(rst), .load(1'b1), .in(pcmux_out), .out(pc_out));
/***** MUXES *****/
always_comb begin : IF_MUXES 
    unique case(EX_MEM_o.ControlWord.br_en)
        pcmux::pc_plus4: pcmux_out = pc_out + 4; 
        pcmux::alu_out: pcmux_out = modmux_out; 
    endcase 
    unique case(EX_MEM_o.ControlWord.modmux_sel)
        modmux::alu_out: modmux_out = EX_MEM_o.DataWord.alu_out; 
        modmux::alu_mod2: modmux_out = {EX_MEM_o.DataWord.alu_out[31:1], 1'b0}; 
    endcase 
end 

/******************* IF_ID *******************/
pipeline_stage IF_ID_stage (.clk(clk), .rst(rst), .load(1'b1), .stage_i(IF_ID_i), .stage_o(IF_ID_o)); 

/******************* ID Stage *******************/
/****** Create Connection between stages ******/
assign ID_EX_i.ControlWord = IF_ID_o.ControlWord;
assign ID_EX_i.DataWord.pc = IF_ID_o.DataWord.pc; 
assign ID_EX_i.DataWord.rs1 = IF_ID_o.DataWord.rs1;
assign ID_EX_i.DataWord.rs2 = IF_ID_o.DataWord.rs2;  
assign ID_EX_i.DataWord.rd = IF_ID_o.DataWord.rd; 
assign ID_EX_i.DataWord.alu_out = IF_ID_o.DataWord.alu_out;
assign ID_EX_i.DataWord.imm = IF_ID_o.DataWord.imm;  
assign ID_EX_i.DataWord.data_mdr = IF_ID_o.DataWord.data_mdr; 
assign mask_bits = MEM_WB_o.alu_out[1:0];
/***** Modules *****/
regfile regfile (.clk(clk), .rst(rst), .load(MEM_WB_o.ControlWord.load_regfile), .in(regfilemux_out)
                 .src_a(IF_ID_o.DataWord.rs1), .src_b(IF_ID_o.DataWord.rs2), .dest(MEM_WB_o.DataWord.rd),
                 .reg_a(ID_EX_i.DataWord.rs1_out), .reg_b(ID_EX_i.DataWord.rs2_out));
/***** MUXES *****/
always_comb begin : ID_MUXES 
    unique case(MEM_WB_o.ControlWord.regfilemux_sel)
        regfilemux::alu_out: regfilemux_out = MEM_WB_o.DataWord.alu_out; 
        regfilemux::br_en: regfilemux_out = {{31'd0}, MEM_WB_o.ControlWord.br_en}; 
        regfilemux::u_imm: regfilemux_out = MEM_WB_o.DataWord.imm; 
        regfilemux::lw: regfilemux_out = MEM_WB_o.DataWord.data_mdr; 
        regfilemux::pc_plus4: regfilemux_out = MEM_WB_o.pc + 4;
        regfilemux::lb: begin 
            case(mask_bits)
                2'b00: regfilemux_out = {{24{MEM_WB_o.DataWord.data_mdr[7]}},  MEM_WB_o.DataWord.data_mdr[7:0]}; 
                2'b01: regfilemux_out = {{24{MEM_WB_o.DataWord.data_mdr[15]}}, MEM_WB_o.DataWord.data_mdr[15:8]};
                2'b10: regfilemux_out = {{24{MEM_WB_o.DataWord.data_mdr[23]}}, MEM_WB_o.DataWord.data_mdr[23:16]};
                2'b11: regfilemux_out = {{24{MEM_WB_o.DataWord.data_mdr[31]}}, MEM_WB_o.DataWord.data_mdr[31:24]};                
            endcase
        end 
        regfilemux::lbu: begin 
            case(mask_bits)
                2'b00: regfilemux_out = {{24'd0}, MEM_WB_o.DataWord.data_mdr[7:0]}; 
                2'b01: regfilemux_out = {{24'd0}, MEM_WB_o.DataWord.data_mdr[15:8]};
                2'b10: regfilemux_out = {{24'd0}, MEM_WB_o.DataWord.data_mdr[23:16]};
                2'b11: regfilemux_out = {{24'd0}, MEM_WB_o.DataWord.data_mdr[31:24]};
            endcase              
        end    
        regfilemux::lh: begin 
            case(mask_bits)
                2'b00: regfilemux_out = {{16{MEM_WB_o.DataWord.data_mdr[15]}}, MEM_WB_o.DataWord.data_mdr[15:0]};
                2'b01: regfilemux_out = {{16{MEM_WB_o.DataWord.data_mdr[23]}}, MEM_WB_o.DataWord.data_mdr[23:8]};
                2'b10: regfilemux_out = {{16{MEM_WB_o.DataWord.data_mdr[31]}}, MEM_WB_o.DataWord.data_mdr[31:16]}; 
                2'b11: regfilemux_out = 32'd0;
            endcase 
        end  
        regfilemux::lhu: begin 
            case(mask_bits)
                2'b00: regfilemux_out = {{16'd0}, MEM_WB_o.DataWord.data_mdr[15:0]};
                2'b01: regfilemux_out = {{16'd0}, MEM_WB_o.DataWord.data_mdr[23:8]};
                2'b10: regfilemux_out = {{16'd0}, MEM_WB_o.DataWord.data_mdr[31:16]}; 
                2'b11: regfilemux_out = 32'd0;
            endcase 
        end                      
    endcase 
end
/******************* ID_EX *******************/
pipeline_stage ID_EX_stage (.clk(clk), .rst(rst), .load(1'b1), .stage_i(ID_EX_i), .stage_o(ID_EX_o));  

/******************* EX *******************/
/****** Create Connection between stages ******/
assign EX_MEM_i.ControlWorld.load_regfile = ID_EX_o.ControlWord.load_regfile;
assign EX_MEM_i.ControlWorld.regfilemux_sel = ID_EX_o.ControlWord.regfilemux_sel;
assign EX_MEM_i.ControlWorld.cmpmux_sel = ID_EX_o.ControlWord.cmpmux_sel;
assign EX_MEM_i.ControlWorld.alumux1_sel = ID_EX_o.ControlWord.alumux1_sel;
assign EX_MEM_i.ControlWorld.modmux_sel = ID_EX_o.ControlWord.modmux_sel;
assign EX_MEM_i.ControlWorld.aluop = ID_EX_o.ControlWord.aluop;
assign EX_MEM_i.ControlWorld.cmpop = ID_EX_o.ControlWord.cmpop;
assign EX_MEM_i.ControlWorld.dmem_read = ID_EX_o.ControlWord.dmem_read;
assign EX_MEM_i.ControlWorld.dmem_write = ID_EX_o.ControlWord.dmem_write;
assign EX_MEM_i.ControlWorld.opcode = ID_EX_o.ControlWord.opcode;
assign EX_MEM_i.ControlWorld.funct3 = ID_EX_o.ControlWord.funct3;

assign EX_MEM_i.DataWord.pc = ID_EX_o.DataWord.pc; 
assign EX_MEM_i.DataWord.rs1 = ID_EX_o.DataWord.rs1;
assign EX_MEM_i.DataWord.rs2 = ID_EX_o.DataWord.rs2;  
assign EX_MEM_i.DataWord.rd = ID_EX_o.DataWord.rd; 
assign EX_MEM_i.DataWord.rs1_out = ID_EX_o.DataWord.rs1_out;
assign EX_MEM_i.DataWord.rs2_out = ID_EX_o.DataWord.rs2_out;
assign EX_MEM_i.DataWord.imm = ID_EX_o.DataWord.imm;  
assign EX_MEM_i.DataWord.data_mdr = ID_EX_o.DataWord.data_mdr; 
case(store_funct3'(ID_EX_o.ControlWord.funct3))
    sw: EX_MEM_i.ControlWord.mem_byte_enable = 4'b1111;
    sh: EX_MEM_i.ControlWord.mem_byte_enable = 4'b0011 << EX_MEM_i.DataWord.alu_out[1:0];
    sb: EX_MEM_i.ControlWord.mem_byte_enable = 4'b0001 << EX_MEM_i.DataWord.alu_out[1:0];
endcase 
/***** Modules *****/
alu ALU (
    .aluop(ID_EX_o.ControlWord.aluop),
    .a(alumux1_out),
    .b(ID_EX_o.DataWord.imm),
    .f(EX_MEM_i.DataWord.alu_out)
)
cmp CMP (
    .cmpop(ID_EX_o.ControlWord.cmpop),
    .rs1_out(ID_EX_o.DataWord.rs1_out),
    .cmpmux_out(cmpmux_out),
	.br_en(EX_MEM_i.ControlWord.br_en)
)
/***** MUXES *****/
always_comb begin : EX_MUXES 
    unique case(ID_EX_o.ControlWord.alumux_sel) 
        alumux::rs1_out: alumux1_out = ID_EX_o.DataWord.rs1_out;
        alumux::pc_out: alumux1_out = ID_EX_o.DataWord.pc;
    endcase 
    unique case(ID_EX_o.ControlWord.cmpmux_sel)
        cmpmux::rs2_out: cmpmux_out = ID_EX_o.DataWord.rs2_out; 
        cmpmux::i_imm: cmpmux_out = ID_EX_o.DataWord.imm; 
    endcase 
end 
/******************* EX_MEM *******************/
pipeline_stage EX_MEM_stage(.clk(clk), .rst(rst), .load(1'b1), .stage_i(EX_MEM_i), .stage_o(EX_MEM_o));

/******************* MEM *******************/
/****** Create Connection between stages ******/
assign MEM_WB_i.ControlWorld.load_regfile = EX_MEM_o.ControlWord.load_regfile;
assign MEM_WB_i.ControlWorld.regfilemux_sel = EX_MEM_o.ControlWord.regfilemux_sel;
assign MEM_WB_i.ControlWorld.cmpmux_sel = EX_MEM_o.ControlWord.cmpmux_sel;
assign MEM_WB_i.ControlWorld.alumux1_sel = EX_MEM_o.ControlWord.alumux1_sel;
assign MEM_WB_i.ControlWorld.modmux_sel = EX_MEM_o.ControlWord.modmux_sel;
assign MEM_WB_i.ControlWorld.aluop = EX_MEM_o.ControlWord.aluop;
assign MEM_WB_i.ControlWorld.cmpop = EX_MEM_o.ControlWord.cmpop;
assign MEM_WB_i.ControlWorld.dmem_read = EX_MEM_o.ControlWord.dmem_read;
assign MEM_WB_i.ControlWorld.dmem_write = EX_MEM_o.ControlWord.dmem_write;
assign MEM_WB_i.ControlWorld.mem_byte_enable = EX_MEM_o.ControlWord.mem_byte_enable;
assign MEM_WB_i.ControlWorld.opcode = EX_MEM_o.ControlWord.opcode;
assign MEM_WB_i.ControlWorld.funct3 = EX_MEM_o.ControlWord.funct3;
assign MEM_WB_i.ControlWorld.br_en = EX_MEM_o.ControlWord.br_en;

assign MEM_WB_i.DataWord.pc = EX_MEM_o.DataWord.pc; 
assign MEM_WB_i.DataWord.rs1 = EX_MEM_o.DataWord.rs1;
assign MEM_WB_i.DataWord.rs2 = EX_MEM_o.DataWord.rs2;  
assign MEM_WB_i.DataWord.rd = EX_MEM_o.DataWord.rd; 
assign MEM_WB_i.DataWord.rs1_out = EX_MEM_o.DataWord.rs1_out;
assign MEM_WB_i.DataWord.rs2_out = EX_MEM_o.DataWord.rs2_out;
assign MEM_WB_i.DataWord.alu_out = EX_MEM_o.DataWord.alu_out;
assign MEM_WB_i.DataWord.imm = EX_MEM_o.DataWord.imm;  

assign MEM_WB_i.DataWord.data_mdr = data_rdata; 
assign data_read = EX_MEM_o.ControlWord.dmem_read;
assign data_write = EX_MEM_o.ControlWord.dmem_write;  
assign data_mbe = EX_MEM_o.ControlWord.mem_byte_enable;
assign data_addr = EX_MEM_o.DataWord.alu_out;  
assign data_wdata = EX_MEM_o.DataWord.rs2_out; 

/******************* MEM_WB *******************/
pipeline_stage MEM_WB_stage(.clk(clk), .rst(rst), .load(1'b1), .stage_i(MEM_WB_i), .stage_o(MEM_WB_o));
endmodule : datapath 