import rv32i_types::*;
module mp4 #( parameter s_offset = 5,
  parameter s_index = 3,
  parameter s_offset_l2 = 5,
  parameter s_index_l2 = 3)(
    input clk,
    input rst,
    input logic [63:0] mem_rdata, 
    input logic mem_resp, 
    output logic [63:0] mem_wdata, 
    output logic mem_write, 
    output logic mem_read, 
    output rv32i_word mem_addr
);
// inst cache 
logic inst_resp_dp;
rv32i_word inst_rdata_dp;
logic inst_read_dp;
rv32i_word inst_addr_dp;
// data cache
logic data_resp_dp;
rv32i_word data_rdata_dp;
logic data_read_dp;
logic data_write_dp; 
logic [3:0] data_mbe_dp; 
rv32i_word data_addr_dp;
rv32i_word data_wdata_dp;

/* Between ev buffer and data cache */
rv32i_word data_pmem_address; 
logic data_pmem_read;
logic data_pmem_write;
rv32i_line data_pmem_wdata;
logic ev_resp; 
rv32i_line ev_rdata;

/* Between arbiter and ev buffer */
logic data_pmem_resp;
rv32i_line data_pmem_rdata; 
rv32i_word ev_address; 
logic ev_write; 
logic ev_read; 
rv32i_line ev_wdata; 

/* Between arbiter and instr cache */
rv32i_word inst_pmem_address; 
logic inst_pmem_read;
logic inst_pmem_resp; 
rv32i_line inst_pmem_rdata; 

/*Data L1 to L2 Interconnect*/
//rv32i_word data_L2_pmem_address; 
//logic data_L2_pmem_read;
//logic data_L2_pmem_write;
//rv32i_line data_L2_pmem_wdata;
//logic data_L2_resp; 
//rv32i_line data_L2_rdata;

/*Instr L1 to L2 Interconnect*/
//rv32i_word inst_L2_pmem_address; 
//logic inst_L2_pmem_read;
//logic inst_L2_resp; 
//rv32i_line inst_L2_rdata;

/* Declare Datapath */
datapath datapath(.*);
arbiter arbiter (
    .clk(clk),
    .rst(rst),
    .inst_pmem_address(inst_pmem_address),
    .inst_pmem_read(inst_pmem_read), 
    .inst_pmem_rdata(inst_pmem_rdata), 
    .inst_pmem_resp(inst_pmem_resp),
    .data_pmem_address(ev_address),
    .data_pmem_read(ev_read), 
    .data_pmem_write(ev_write),
    .data_pmem_wdata(ev_wdata), 
    .data_pmem_rdata(data_pmem_rdata), 
    .data_pmem_resp(data_pmem_resp),
    .pmem_rdata(mem_rdata), 
    .pmem_resp(mem_resp),
    .pmem_write(mem_write),
    .pmem_read(mem_read),
    .pmem_wdata(mem_wdata), 
    .pmem_addr(mem_addr)
);

ev_buffer ev_buffer(
  .clk(clk),
  .rst(rst), 
  .data_pmem_address(data_pmem_address),
  .data_pmem_write(data_pmem_write), 
  .data_pmem_read(data_pmem_read), 
  .data_pmem_wdata(data_pmem_wdata),
  .ev_resp(ev_resp), 
  .ev_rdata(ev_rdata), 
  .data_pmem_resp(data_pmem_resp), 
  .data_pmem_rdata(data_pmem_rdata), 
  .ev_address(ev_address),
  .ev_write(ev_write), 
  .ev_read(ev_read), 
  .ev_wdata(ev_wdata)
);

cache #(s_offset,s_index) data_cache (
  .clk(clk),
  .pmem_resp(ev_resp),
  .pmem_rdata(ev_rdata),
  .pmem_address(data_pmem_address),
  .pmem_wdata(data_pmem_wdata),
  .pmem_read(data_pmem_read),
  .pmem_write(data_pmem_write),
  .mem_read(data_read_dp),
  .mem_write(data_write_dp),
  .mem_byte_enable_cpu(data_mbe_dp),
  .mem_address(data_addr_dp),
  .mem_wdata_cpu(data_wdata_dp),
  .mem_resp(data_resp_dp),
  .mem_rdata_cpu(data_rdata_dp)
);

//cache_L2 #(s_offset_l2,s_index_l2) L2_data_cache (
//  .clk(clk),
//  .pmem_resp(ev_resp),
//  .pmem_rdata(ev_rdata),
//  .pmem_address(data_pmem_address),
//  .pmem_wdata(data_pmem_wdata),
//  .pmem_read(data_pmem_read),
//  .pmem_write(data_pmem_write),
//  .mem_read(data_L2_pmem_read),
//  .mem_write(data_L2_pmem_write),
//  .mem_byte_enable_cpu(4'hF),
//  .mem_address(data_L2_pmem_address),
//  .mem_wdata(data_L2_pmem_wdata),
//  .mem_resp(data_L2_resp),
//  .mem_rdata(data_L2_rdata)
//);

// prefetch prefetch(
//   .clk(clk),
//   .rst(rst),
//   .inst_pmem_address(inst_pmem_address), 
//   .inst_pmem_read(inst_pmem_read),
//   .pf_resp(pf_resp), 
//   .pf_rdata(pf_rdata), 
//   .inst_pmem_resp(inst_pmem_resp),
//   .inst_pmem_rdata(inst_pmem_rdata), 
//   .pf_read(pf_read),
//   .pf_address(pf_address) 
// );

cache #(s_offset, s_index) instr_cache(
  .clk(clk),
  .pmem_resp(inst_pmem_resp),
  .pmem_rdata(inst_pmem_rdata),
  .pmem_wdata(),
  .pmem_address(inst_pmem_address),
  .pmem_read(inst_pmem_read),
  .pmem_write(),
  .mem_read(inst_read_dp),
  .mem_write(1'b0),
  .mem_byte_enable_cpu(4'b0000),
  .mem_address(inst_addr_dp),
  .mem_wdata_cpu(32'd0),
  .mem_resp(inst_resp_dp),
  .mem_rdata_cpu(inst_rdata_dp)
);


//cache_L2 #(s_offset_l2, 2) L2_instr_cache(
//  .clk(clk),
//  .pmem_resp(inst_pmem_resp),
//  .pmem_rdata(inst_pmem_rdata),
//  .pmem_wdata(),
//  .pmem_address(inst_pmem_address),
//  .pmem_read(inst_pmem_read),
//  .pmem_write(),
//  .mem_read(inst_L2_pmem_read),
//  .mem_write(1'b0),
//  .mem_byte_enable_cpu(4'b0000),
//  .mem_address(inst_L2_pmem_address),
//  .mem_wdata(256'd0),
//  .mem_resp(inst_L2_resp),
//  .mem_rdata(inst_L2_rdata)
//);

endmodule : mp4
