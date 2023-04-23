module data_array #(
  parameter s_offset = 5,
  parameter s_index = 3,
  parameter s_tag = 32 - s_offset - s_index,
  parameter s_mask = 2**s_offset,
  parameter s_line = 8*s_mask,
  parameter num_sets = 2**s_index
)(
  input clk,
  input logic [31:0] write_en,
  input logic [s_index-1:0] rindex,
  input logic [s_index - 1:0] windex,
  input logic [s_line - 1:0] datain,
  output logic [s_line - 1:0] dataout
);

logic [s_line - 1:0] data [num_sets] = '{default: '0};

always_comb begin
  for (int i = 0; i < 32; i++) begin
      dataout[8*i +: 8] = data[rindex][8*i +: 8];
  end
end

always_ff @(posedge clk) begin
    for (int i = 0; i < 32; i++) begin
		  data[windex][8*i +: 8] <= write_en[i] ? datain[8*i +: 8] : data[windex][8*i +: 8];
    end
end

endmodule : data_array

