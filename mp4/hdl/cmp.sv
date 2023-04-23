import rv32i_types::*;

module cmp
(
    input branch_funct3_t cmpop,
    input rv32i_word cmpmux1_out,
    input rv32i_word cmpmux2_out,
	output logic br_en
);

always_comb
begin
    unique case (cmpop)
		 beq: br_en = cmpmux1_out == cmpmux2_out;
		 bne: br_en = cmpmux1_out != cmpmux2_out; 
		 blt: br_en = $signed(cmpmux1_out) < $signed(cmpmux2_out); 
		 bge: br_en = $signed(cmpmux1_out) >= $signed(cmpmux2_out);
		 bltu: br_en = cmpmux1_out < cmpmux2_out; 
		 bgeu: br_en = cmpmux1_out >= cmpmux2_out; 
    endcase
end

endmodule : cmp
