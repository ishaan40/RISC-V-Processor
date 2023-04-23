import rv32i_types::*; 

module pipeline_stage (
    input clk, 
    input rst, 
    input load, 
    input rv32i_stage stage_i,
    output rv32i_stage stage_o
);

rv32i_stage data = 0;

always_ff @(posedge clk)
begin
    if (rst) begin
        data.ControlWord.load_regfile <= 1'b0;
        data.ControlWord.regfilemux_sel <= regfilemux::alu_out; 
        data.ControlWord.cmpmux_sel <= cmpmux::rs2_out; 
        data.ControlWord.alumux1_sel <= alumux::rs1_out; 
        data.ControlWord.cmpop <= beq; 
        data.ControlWord.aluop <= alu_add; 
        data.ControlWord.dmem_read <= 1'b0;
        data.ControlWord.dmem_write <= 1'b0; 
        data.ControlWord.mem_byte_enable <= 4'b1111; 
        data.ControlWord.opcode <= rv32i_opcode'(7'd0); 
        data.ControlWord.funct3 <= 3'd0; 
        data.ControlWord.funct7 <= 7'd0; 
        data.ControlWord.br_en <= 1'b0; 
        data.DataWord.pc <= 32'd0; 
        data.DataWord.rs1 <= 5'd0; 
        data.DataWord.rs2 <= 5'd0; 
        data.DataWord.rd <= 5'd0; 
        data.DataWord.rs1_out <= 32'd0; 
        data.DataWord.rs2_out <= 32'd0;
        data.DataWord.alu_out <= 32'd0; 
        data.DataWord.imm <= 32'd0;
        data.DataWord.data_mdr <= 32'd0;
    end
    else if (load) begin
        data <= stage_i;
    end
    else begin
        data <= data; 
    end
end

always_comb
begin
    stage_o = data; 
end

endmodule : pipeline_stage