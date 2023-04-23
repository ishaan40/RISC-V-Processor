import rv32i_types::*; 

module datapath (
    input clk, 
    input rst, 
    /* Instruction memory interface */ 
    input  inst_resp_dp,
    input  rv32i_word inst_rdata_dp, 
    output inst_read_dp, 
    output rv32i_word inst_addr_dp, 
    /* Data memory interface */
    input data_resp_dp, 
    input rv32i_word data_rdata_dp, 
    output data_read_dp,
    output data_write_dp, 
    output [3:0] data_mbe_dp, 
    output rv32i_word data_addr_dp, 
    output rv32i_word data_wdata_dp
);
/****************************************************** Variables *****************************************************/
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
rv32i_word regfilemux_out; 
logic [1:0] mask_bits; 
rv32i_word alumux1_out; 
rv32i_word alumux2_out; 
rv32i_word cmpmux1_out; 
rv32i_word cmpmux2_out;
logic br_en_temp;
logic jump_en; 
logic load_pc;
logic load_IF_ID; 
logic load_ID_EX;
logic load_EX_MEM;
logic load_MEM_WB;
logic rst_IF_ID;
logic rst_ID_EX;
logic rst_EX_MEM; 
logic rst_MEM_WB;
rv32i_word ex_mem_forwarding_out1;
rv32i_word mem_wb_forwarding_out1;
rv32i_word ex_mem_forwarding_out2;
rv32i_word mem_wb_forwarding_out2;
rv32i_word ex_mem_forwarding_cmp1out;
rv32i_word mem_wb_forwarding_cmp1out;
rv32i_word ex_mem_forwarding_cmp2out;
rv32i_word mem_wb_forwarding_cmp2out; 
rv32i_word forwarded_store_data;
rv32i_word alu_out;
rv32i_word muldiv_out;
logic forwarding_load1;
logic forwarding_load2;
logic forwarding_cmp1_load;
logic forwarding_cmp2_load;
logic forwarding_mux1;
logic forwarding_mux2;
logic forwarding_cmp1mux;
logic forwarding_cmp2mux;
logic alumux2_sel;
logic forwarding_store;
logic br_forwarding;
logic muldiv_start;
logic muldiv_resp;
/*********************************************************************************************************************/

/************************************************* Instruction Fetch *************************************************/
// assign  inst_read_dp = 1'b1;
assign  inst_addr_dp = pc_out; 
control_rom ctrl_rom(.opcode(rv32i_opcode'(inst_rdata_dp[6:0])), .funct3(inst_rdata_dp[14:12]), 
                     .funct7(inst_rdata_dp[31:25]), .ctrl_word(IF_ID_i.ControlWord));
pc_register pc_reg(.clk(clk), .rst(rst), .load(load_pc), .in(pcmux_out), .out(pc_out));
always_comb begin : IF_comb
    // Init. the dataword 
    IF_ID_i.DataWord.pc = pc_out; 
    IF_ID_i.DataWord.rs1 = inst_rdata_dp[19:15]; 
    IF_ID_i.DataWord.rs2 = inst_rdata_dp[24:20]; 
    IF_ID_i.DataWord.rd = inst_rdata_dp[11:7]; 
    IF_ID_i.DataWord.rs1_out = 32'd0; 
    IF_ID_i.DataWord.rs2_out = 32'd0; 
    IF_ID_i.DataWord.alu_out = 32'd0; 
    IF_ID_i.DataWord.data_mdr = 32'd0; 
    // Decode the immediate 
    case(IF_ID_i.ControlWord.opcode) 
        op_jalr, op_load, op_imm: begin
            IF_ID_i.DataWord.imm = {{21{inst_rdata_dp[31]}}, inst_rdata_dp[30:20]};
            IF_ID_i.DataWord.rs2 = 0;
        end
        op_store: begin
            IF_ID_i.DataWord.imm = {{21{inst_rdata_dp[31]}}, inst_rdata_dp[30:25], inst_rdata_dp[11:7]};
        end
        op_br: begin
            IF_ID_i.DataWord.imm = {{20{inst_rdata_dp[31]}}, inst_rdata_dp[7], inst_rdata_dp[30:25], inst_rdata_dp[11:8], 1'b0};
        end
        op_lui, op_auipc: begin
            IF_ID_i.DataWord.imm = {inst_rdata_dp[31:12], 12'h000};
            IF_ID_i.DataWord.rs1 = 0; 
            IF_ID_i.DataWord.rs2 = 0;
        end
        op_jal: begin
            IF_ID_i.DataWord.imm = {{12{inst_rdata_dp[31]}}, inst_rdata_dp[19:12], inst_rdata_dp[20], inst_rdata_dp[30:21], 1'b0};
            IF_ID_i.DataWord.rs1 = 0; 
            IF_ID_i.DataWord.rs2 = 0;
        end
        default:
            IF_ID_i.DataWord.imm = 32'd0;
    endcase 
    // Handle Branching 
    jump_en = (EX_MEM_i.ControlWord.opcode == op_jal || EX_MEM_i.ControlWord.opcode == op_jalr);
    case({jump_en, (br_en_temp && EX_MEM_i.ControlWord.opcode == op_br)})
        2'b00: pcmux_out = pc_out + 4; 
        2'b01: pcmux_out = EX_MEM_i.DataWord.alu_out; 
        2'b10: pcmux_out = {EX_MEM_i.DataWord.alu_out[31:1], 1'b0};
        2'b11: pcmux_out = pc_out + 4;
    endcase 
end : IF_comb
/*********************************************************************************************************************/

/********************************************************IF_ID********************************************************/
pipeline_stage IF_ID_stage (.clk(clk), .rst(rst_IF_ID), .load(load_IF_ID), .stage_i(IF_ID_i), .stage_o(IF_ID_o)); 
/*********************************************************************************************************************/

/************************************************ Instruction Decode *************************************************/
regfile regfile (.clk(clk), .rst(rst), .load(MEM_WB_o.ControlWord.load_regfile), .in(regfilemux_out),
                 .src_a(IF_ID_o.DataWord.rs1), .src_b(IF_ID_o.DataWord.rs2), .dest(MEM_WB_o.DataWord.rd),
                 .reg_a(ID_EX_i.DataWord.rs1_out), .reg_b(ID_EX_i.DataWord.rs2_out));
hazard_detection_unit hdu (
    // added clk and rst for performance counter -- REMOVE WHEN DONE
    .clk(clk),
    .rst(rst),
    // added clk and rst for performance counter -- REMOVE WHEN DONE
    .dmem_read(EX_MEM_o.ControlWord.dmem_read),
    .dmem_write(EX_MEM_o.ControlWord.dmem_write),
    .muldiv_start(muldiv_start),
    .muldiv_resp(muldiv_resp),
    .data_resp_dp(data_resp_dp),
    .inst_resp_dp(inst_resp_dp),
    .dest(EX_MEM_o.DataWord.rd),
    .src1(ID_EX_o.DataWord.rs1),
    .src2(ID_EX_o.DataWord.rs2),
    .br_en(br_forwarding),
    .jump_en(jump_en),
    .opcode(ID_EX_o.ControlWord.opcode),
    .inst_read(inst_read_dp),
    .rst_IF_ID(rst_IF_ID),
    .rst_ID_EX(rst_ID_EX),
    .rst_EX_MEM(rst_EX_MEM),
    .rst_MEM_WB(rst_MEM_WB),
    .load_IF_ID(load_IF_ID),
    .load_ID_EX(load_ID_EX),
    .load_EX_MEM(load_EX_MEM),
    .load_MEM_WB(load_MEM_WB),
    .load_pc(load_pc)
);
always_comb begin : ID_comb 
    // Pass the pipeline data
    ID_EX_i.ControlWord = IF_ID_o.ControlWord;
    ID_EX_i.DataWord.pc = IF_ID_o.DataWord.pc; 
    ID_EX_i.DataWord.rs1 = IF_ID_o.DataWord.rs1;
    ID_EX_i.DataWord.rs2 = IF_ID_o.DataWord.rs2;  
    ID_EX_i.DataWord.rd = IF_ID_o.DataWord.rd; 
    ID_EX_i.DataWord.alu_out = IF_ID_o.DataWord.alu_out;
    ID_EX_i.DataWord.imm = IF_ID_o.DataWord.imm;  
    ID_EX_i.DataWord.data_mdr = IF_ID_o.DataWord.data_mdr; 
    // Regfilemux that handles writebacks
    unique case(MEM_WB_o.ControlWord.regfilemux_sel)
        regfilemux::alu_out:  regfilemux_out = MEM_WB_o.DataWord.alu_out; 
        regfilemux::br_en:    regfilemux_out = {31'd0, MEM_WB_o.ControlWord.br_en}; 
        regfilemux::u_imm:    regfilemux_out = MEM_WB_o.DataWord.imm; 
        regfilemux::lw, regfilemux::lb, regfilemux::lbu, regfilemux::lh, regfilemux::lhu: regfilemux_out = MEM_WB_o.DataWord.data_mdr; 
        regfilemux::pc_plus4: regfilemux_out = MEM_WB_o.DataWord.pc + 4;
    endcase     
end : ID_comb
/*********************************************************************************************************************/

/********************************************************ID_EX********************************************************/
pipeline_stage ID_EX_stage (.clk(clk), .rst(rst_ID_EX), .load(load_ID_EX), .stage_i(ID_EX_i), .stage_o(ID_EX_o));  
/*********************************************************************************************************************/

/****************************************************** Execute ******************************************************/
alu ALU (.aluop(ID_EX_o.ControlWord.aluop), .a(alumux1_out), .b(alumux2_out), .f(alu_out));
muldiv MD (.clk(clk), .rst(rst_ID_EX), .start(muldiv_start), .muldivop(ID_EX_o.ControlWord.funct3), .a(alumux1_out), .b(alumux2_out), .muldiv_resp(muldiv_resp), .result(muldiv_out));
cmp CMP (.cmpop(ID_EX_o.ControlWord.cmpop), .cmpmux1_out(cmpmux1_out), .cmpmux2_out(cmpmux2_out), .br_en(br_en_temp));
forwarding_unit fu(.dest_ex_mem(MEM_WB_i.DataWord.rd), .dest_mem_wb(MEM_WB_o.DataWord.rd), .src1(ID_EX_o.DataWord.rs1),
                   .src2(ID_EX_o.DataWord.rs2), .data_ex_mem(MEM_WB_i.DataWord.alu_out), .data_mem_wb(MEM_WB_o.DataWord.alu_out),
                   .data_mdr_in(MEM_WB_i.DataWord.data_mdr), .data_mdr(MEM_WB_o.DataWord.data_mdr),
                   .ld_regfile_ex_mem(MEM_WB_i.ControlWord.load_regfile), .ld_regfile_mem_wb(MEM_WB_o.ControlWord.load_regfile),
                   .dmem_read_in(MEM_WB_i.ControlWord.dmem_read), .dmem_read(MEM_WB_o.ControlWord.dmem_read),
                   .alumux1_sel(ID_EX_o.ControlWord.alumux1_sel), .alumux2_sel(alumux2_sel), .cmpmux2_sel(ID_EX_o.ControlWord.cmpmux_sel),
                   .br_ex_mem(MEM_WB_i.ControlWord.br_en), .br_mem_wb(MEM_WB_o.ControlWord.br_en),
                   .opcode(ID_EX_o.ControlWord.opcode),
                   .ex_mem_regfile_mux_sel(MEM_WB_i.ControlWord.regfilemux_sel), .mem_wb_regfile_mux_sel(MEM_WB_o.ControlWord.regfilemux_sel),
                   .ex_mem_forwarding_out1(ex_mem_forwarding_out1), .mem_wb_forwarding_out1(mem_wb_forwarding_out1),
                   .ex_mem_forwarding_out2(ex_mem_forwarding_out2), .mem_wb_forwarding_out2(mem_wb_forwarding_out2),
                   .ex_mem_forwarding_cmp1out(ex_mem_forwarding_cmp1out), .mem_wb_forwarding_cmp1out(mem_wb_forwarding_cmp1out),
                   .ex_mem_forwarding_cmp2out(ex_mem_forwarding_cmp2out), .mem_wb_forwarding_cmp2out(mem_wb_forwarding_cmp2out),
                    .forwarded_store_data(forwarded_store_data),
                   .forwarding_load1(forwarding_load1), .forwarding_load2(forwarding_load2),
                   .forwarding_cmp1_load(forwarding_cmp1_load), .forwarding_cmp2_load(forwarding_cmp2_load),
                   .forwarding_mux1(forwarding_mux1), .forwarding_mux2(forwarding_mux2),
                   .forwarding_cmp1mux(forwarding_cmp1mux), .forwarding_cmp2mux(forwarding_cmp2mux), .forwarding_store(forwarding_store));

assign muldiv_start = (ID_EX_o.ControlWord.opcode == op_reg && ID_EX_o.ControlWord.funct7 == 7'd1);        
assign alumux2_sel = (ID_EX_o.ControlWord.opcode == op_reg) ? 1'b1 : 1'b0;

always_comb begin
    if(EX_MEM_o.ControlWord.opcode == op_load && !data_resp_dp) begin
        br_forwarding = 0;
    end
    else if(MEM_WB_o.ControlWord.opcode == op_load && EX_MEM_o.ControlWord.opcode == 0) begin
        br_forwarding = 0;
    end
    else begin
        br_forwarding = (br_en_temp && (ID_EX_o.ControlWord.opcode == op_br || ((ID_EX_o.ControlWord.opcode == op_reg || ID_EX_o.ControlWord.opcode == op_imm) && (ID_EX_o.ControlWord.funct3 == 3'd2 || ID_EX_o.ControlWord.funct3 == 3'd3))));
    end
end

always_comb begin : EX_comb
    // Pass the pipeline data
    EX_MEM_i.ControlWord.load_regfile = ID_EX_o.ControlWord.load_regfile;
    EX_MEM_i.ControlWord.regfilemux_sel = ID_EX_o.ControlWord.regfilemux_sel;
    EX_MEM_i.ControlWord.cmpmux_sel = ID_EX_o.ControlWord.cmpmux_sel;
    EX_MEM_i.ControlWord.alumux1_sel = ID_EX_o.ControlWord.alumux1_sel;
    EX_MEM_i.ControlWord.aluop = ID_EX_o.ControlWord.aluop;
    EX_MEM_i.ControlWord.cmpop = ID_EX_o.ControlWord.cmpop;
    EX_MEM_i.ControlWord.dmem_read = ID_EX_o.ControlWord.dmem_read;
    EX_MEM_i.ControlWord.dmem_write = ID_EX_o.ControlWord.dmem_write;
    EX_MEM_i.ControlWord.opcode = ID_EX_o.ControlWord.opcode;
    EX_MEM_i.ControlWord.funct3 = ID_EX_o.ControlWord.funct3;
    EX_MEM_i.ControlWord.funct7 = ID_EX_o.ControlWord.funct7;
    EX_MEM_i.ControlWord.br_en = br_forwarding;
    EX_MEM_i.DataWord.pc = ID_EX_o.DataWord.pc; 
    EX_MEM_i.DataWord.rs1 = ID_EX_o.DataWord.rs1;
    EX_MEM_i.DataWord.rs2 = ID_EX_o.DataWord.rs2;  
    EX_MEM_i.DataWord.rd = ID_EX_o.DataWord.rd; 
    EX_MEM_i.DataWord.rs1_out = ID_EX_o.DataWord.rs1_out;
    EX_MEM_i.DataWord.rs2_out = (forwarding_store == 1'b1) ? forwarded_store_data : ID_EX_o.DataWord.rs2_out;
    EX_MEM_i.DataWord.alu_out = (ID_EX_o.ControlWord.opcode == op_reg && ID_EX_o.ControlWord.funct7 == 7'd1) ? muldiv_out : alu_out;
    EX_MEM_i.DataWord.imm = ID_EX_o.DataWord.imm;  
    EX_MEM_i.DataWord.data_mdr = ID_EX_o.DataWord.data_mdr; 
    // Calculate the mem_byte_enable to use in the mem stage to write to memory (store)
    case(store_funct3_t'(ID_EX_o.ControlWord.funct3))
        sw: EX_MEM_i.ControlWord.mem_byte_enable = 4'b1111;
        sh: EX_MEM_i.ControlWord.mem_byte_enable = 4'b0011 << EX_MEM_i.DataWord.alu_out[1:0];
        sb: EX_MEM_i.ControlWord.mem_byte_enable = 4'b0001 << EX_MEM_i.DataWord.alu_out[1:0];
        default: EX_MEM_i.ControlWord.mem_byte_enable = 4'b1111; 
    endcase 
    // alumux1
    unique case({forwarding_mux1, forwarding_load1, ID_EX_o.ControlWord.alumux1_sel}) 
        3'b000: alumux1_out = ID_EX_o.DataWord.rs1_out;
        3'b001: alumux1_out = ID_EX_o.DataWord.pc;
        3'b010: alumux1_out = ex_mem_forwarding_out1;  
        3'b011: alumux1_out = ex_mem_forwarding_out1;
        3'b100: alumux1_out = 32'h391BAD;
        3'b101: alumux1_out = 32'h391BAD;
        3'b110: alumux1_out = mem_wb_forwarding_out1;
        3'b111: alumux1_out = mem_wb_forwarding_out1;
        default:;
    endcase
    // alumux2
    unique case({forwarding_mux2, forwarding_load2, alumux2_sel}) 
        3'b000: alumux2_out = ID_EX_o.DataWord.imm;
        3'b001: alumux2_out = ID_EX_o.DataWord.rs2_out;
        3'b010: alumux2_out = 32'h391BAD;
        3'b011: alumux2_out = ex_mem_forwarding_out2;
        3'b100: alumux2_out = ID_EX_o.DataWord.imm;
        3'b101: alumux2_out = ID_EX_o.DataWord.rs2_out;
        3'b110: alumux2_out = 32'h391BAD;
        3'b111: alumux2_out = mem_wb_forwarding_out2;
        default:;
    endcase  
    // cmpmux2
    unique case({forwarding_cmp2mux, forwarding_cmp2_load, ID_EX_o.ControlWord.cmpmux_sel})
        3'b000: cmpmux2_out = ID_EX_o.DataWord.rs2_out; 
        3'b001: cmpmux2_out = ID_EX_o.DataWord.imm; 
        3'b010: cmpmux2_out = ex_mem_forwarding_cmp2out;
        3'b011: cmpmux2_out = ex_mem_forwarding_cmp2out;
        3'b100: cmpmux2_out = ID_EX_o.DataWord.rs2_out; 
        3'b101: cmpmux2_out = ID_EX_o.DataWord.imm; 
        3'b110: cmpmux2_out = mem_wb_forwarding_cmp2out;
        3'b111: cmpmux2_out = mem_wb_forwarding_cmp2out;
        default:;
    endcase     
    // cmpmux1
    unique case({forwarding_cmp1mux, forwarding_cmp1_load})
        2'b00: cmpmux1_out = ID_EX_o.DataWord.rs1_out;
        2'b01: cmpmux1_out = ex_mem_forwarding_cmp1out;
        2'b10: cmpmux1_out = ID_EX_o.DataWord.rs1_out;
        2'b11: cmpmux1_out = mem_wb_forwarding_cmp1out;
        default:;
    endcase
end : EX_comb

/********************************************************EX_MEM*******************************************************/
pipeline_stage EX_MEM_stage(.clk(clk), .rst(rst_EX_MEM), .load(load_EX_MEM), .stage_i(EX_MEM_i), .stage_o(EX_MEM_o));
/*********************************************************************************************************************/

/**********************************************************MEM********************************************************/
// interface with data memory 
assign data_read_dp = EX_MEM_o.ControlWord.dmem_read;
assign data_write_dp = EX_MEM_o.ControlWord.dmem_write;  
assign data_mbe_dp = EX_MEM_o.ControlWord.mem_byte_enable;
assign data_addr_dp = {EX_MEM_o.DataWord.alu_out[31:2], 2'b00}; 
assign mask_bits = EX_MEM_o.DataWord.alu_out[1:0]; 
assign data_wdata_dp = EX_MEM_o.DataWord.rs2_out << (8 * mask_bits); 
always_comb begin : MEM_comb
    // Pass the pipeline data
    MEM_WB_i.ControlWord.load_regfile = EX_MEM_o.ControlWord.load_regfile;
    MEM_WB_i.ControlWord.regfilemux_sel = EX_MEM_o.ControlWord.regfilemux_sel;
    MEM_WB_i.ControlWord.cmpmux_sel = EX_MEM_o.ControlWord.cmpmux_sel;
    MEM_WB_i.ControlWord.alumux1_sel = EX_MEM_o.ControlWord.alumux1_sel;
    MEM_WB_i.ControlWord.aluop = EX_MEM_o.ControlWord.aluop;
    MEM_WB_i.ControlWord.cmpop = EX_MEM_o.ControlWord.cmpop;
    MEM_WB_i.ControlWord.dmem_read = EX_MEM_o.ControlWord.dmem_read;
    MEM_WB_i.ControlWord.dmem_write = EX_MEM_o.ControlWord.dmem_write;
    MEM_WB_i.ControlWord.mem_byte_enable = EX_MEM_o.ControlWord.mem_byte_enable;
    MEM_WB_i.ControlWord.opcode = EX_MEM_o.ControlWord.opcode;
    MEM_WB_i.ControlWord.funct3 = EX_MEM_o.ControlWord.funct3;
    MEM_WB_i.ControlWord.funct7 = EX_MEM_o.ControlWord.funct7;
    MEM_WB_i.ControlWord.br_en = EX_MEM_o.ControlWord.br_en;
    MEM_WB_i.DataWord.pc = EX_MEM_o.DataWord.pc; 
    MEM_WB_i.DataWord.rs1 = EX_MEM_o.DataWord.rs1;
    MEM_WB_i.DataWord.rs2 = EX_MEM_o.DataWord.rs2;  
    MEM_WB_i.DataWord.rd = EX_MEM_o.DataWord.rd; 
    MEM_WB_i.DataWord.rs1_out = EX_MEM_o.DataWord.rs1_out;
    MEM_WB_i.DataWord.rs2_out = EX_MEM_o.DataWord.rs2_out;
    MEM_WB_i.DataWord.alu_out = EX_MEM_o.DataWord.alu_out;
    MEM_WB_i.DataWord.imm = EX_MEM_o.DataWord.imm;  
    MEM_WB_i.DataWord.data_mdr = data_rdata_dp; 

case(MEM_WB_i.ControlWord.regfilemux_sel)
    regfilemux::lb: begin 
        case(mask_bits)
            2'b00: MEM_WB_i.DataWord.data_mdr = {{24{data_rdata_dp[7]}},  data_rdata_dp[7:0]}; 
            2'b01: MEM_WB_i.DataWord.data_mdr = {{24{data_rdata_dp[15]}}, data_rdata_dp[15:8]};
            2'b10: MEM_WB_i.DataWord.data_mdr = {{24{data_rdata_dp[23]}}, data_rdata_dp[23:16]};
            2'b11: MEM_WB_i.DataWord.data_mdr = {{24{data_rdata_dp[31]}}, data_rdata_dp[31:24]};                
        endcase
        end 
    regfilemux::lbu: begin 
        case(mask_bits)
            2'b00: MEM_WB_i.DataWord.data_mdr = {{24'd0}, data_rdata_dp[7:0]}; 
            2'b01: MEM_WB_i.DataWord.data_mdr = {{24'd0}, data_rdata_dp[15:8]};
            2'b10: MEM_WB_i.DataWord.data_mdr = {{24'd0}, data_rdata_dp[23:16]};
            2'b11: MEM_WB_i.DataWord.data_mdr = {{24'd0}, data_rdata_dp[31:24]};
        endcase              
        end    
    regfilemux::lh: begin 
        case(mask_bits)
            2'b00: MEM_WB_i.DataWord.data_mdr = {{16{data_rdata_dp[15]}}, data_rdata_dp[15:0]};
            2'b01: MEM_WB_i.DataWord.data_mdr = {{16{data_rdata_dp[23]}}, data_rdata_dp[23:8]};
            2'b10: MEM_WB_i.DataWord.data_mdr = {{16{data_rdata_dp[31]}}, data_rdata_dp[31:16]}; 
            2'b11: MEM_WB_i.DataWord.data_mdr = 32'd0;
        endcase 
        end  
    regfilemux::lhu: begin 
        case(mask_bits)
            2'b00: MEM_WB_i.DataWord.data_mdr = {{16'd0}, data_rdata_dp[15:0]};
            2'b01: MEM_WB_i.DataWord.data_mdr = {{16'd0}, data_rdata_dp[23:8]};
            2'b10: MEM_WB_i.DataWord.data_mdr = {{16'd0}, data_rdata_dp[31:16]}; 
            2'b11: MEM_WB_i.DataWord.data_mdr = 32'd0;
        endcase 
        end   
    default: ;
endcase                   





end : MEM_comb
/*********************************************************************************************************************/

/********************************************************MEM_WB*******************************************************/
pipeline_stage MEM_WB_stage(.clk(clk), .rst(rst_MEM_WB), .load(load_MEM_WB), .stage_i(MEM_WB_i), .stage_o(MEM_WB_o));
/*********************************************************************************************************************/
endmodule : datapath 