
module array #(parameter width = 1, parameter s_index = 3, parameter num_sets = 2**s_index)
(
  input clk,
  input logic load,
  input logic [s_index - 1:0] rindex,
  input logic [s_index - 1:0] windex,
  input logic [width-1:0] datain,
  output logic [width-1:0] dataout
);

logic [width-1:0] data [num_sets] = '{default: '0};
// logic [width-1:0] data [8];
// initial begin
//   data[0] = 0;
//   data[1] = 0;
//   data[2] = 0;
//   data[3] = 0;
//   data[4] = 0;
//   data[5] = 0;
//   data[6] = 0;
//   data[7] = 0;
// end

always_comb begin
  dataout = data[rindex];
end

always_ff @(posedge clk)
begin
    if(load)
        data[windex] <= datain;
end

endmodule : array
