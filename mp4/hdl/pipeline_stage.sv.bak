import rv32i_types::*; 

module pipeline_stage (
    input clk, 
    input rst, 
    input load, 
    input rv32i_stage stage_i,
    output rv32i_stage stage_o; 
);

rv32i_stage data = 0;

always_ff @(posedge clk)
begin
    if (rst)
    begin
        data <= '0;
    end
    else if (load)
    begin
        data <= stage_i;
    end
    else
    begin
        data <= data;
    end
end

always_comb
begin
    stage_o = data;
end

endmodule : pipeline_stage