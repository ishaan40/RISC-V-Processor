module cache_datapath #(
  parameter s_offset = 5,
  parameter s_index = 3,
  parameter s_tag = 32 - s_offset - s_index,
  parameter s_mask = 2**s_offset,
  parameter s_line = 8*s_mask,
  parameter num_sets = 2**s_index
)(
  input clk,
  /* CPU memory data signals */
  input logic  [31:0]  mem_byte_enable,
  input logic  [31:0]  mem_address,
  input logic  [s_line-1:0] mem_wdata,
  output logic [s_line-1:0] mem_rdata,

  /* Physical memory data signals */
  input  logic [s_line-1:0] pmem_rdata,
  output logic [s_line-1:0] pmem_wdata,
  output logic [31:0]  pmem_address,

  /* Control signals */
  input logic tag_load,
  input logic valid_load,
  input logic dirty_load,
  input logic dirty_in,
  output logic dirty_out,

  output logic hit,
  input logic [1:0] writing
);

/* Datapath signals */
logic dirty_o [4];
logic dirty_i [4]; 
logic dirty_ld [4];
logic valid_ld [4];
logic tag_ld [4]; 
logic [2:0] lru_i; 
logic [2:0] lru_o[num_sets] = '{default: '0}; 
logic [s_line-1:0] line_in [4];
logic [s_line-1:0] line_out [4];
logic [s_tag-1:0] address_tag;
logic [s_tag-1:0] tag_out [4];
logic [s_index-1:0]  index;
logic [31:0] mask [4];
logic [3:0] valid_out;
logic [3:0] way_hit; 

logic [31:0] hit_counter =  '{default: '0};
logic [31:0] miss_counter = '{default: '0};


always_ff @ (posedge clk) begin 
  if (hit) 
    hit_counter <= hit_counter + 32'd1; 
  if (tag_load)
    miss_counter <= miss_counter + 32'd1; 
end 

always_ff @ (posedge clk) begin 

end 

always_ff @ (posedge clk) begin 
    if(hit)
    begin
      lru_o[index] <= lru_i;
    end 
end 

always_comb begin : calc_lru
    case(way_hit)
      /* Way A was hit */
      4'b1000: begin 
        lru_i = {1'b0, 1'b0, lru_o[index][0]}; 
      end 
      /* Way B was hit */
      4'b0100: begin 
        lru_i = {1'b0, 1'b1, lru_o[index][0]};
      end 
      /* Way C was hit */
      4'b0010: begin  
        lru_i = {1'b1, lru_o[index][1], 1'b0};
      end 
      /* Way D was hit */
      4'b0001: begin 
        lru_i = {1'b1, lru_o[index][1], 1'b1};
      end 
		default: lru_i = lru_o[index];
    endcase 
end : calc_lru

always_comb begin : calc_hit 
  way_hit[3] = valid_out[3] && (address_tag == tag_out[3]);
  way_hit[2] = valid_out[2] && (address_tag == tag_out[2]);
  way_hit[1] = valid_out[1] && (address_tag == tag_out[1]);
  way_hit[0] = valid_out[0] && (address_tag == tag_out[0]);
  hit = way_hit[3] || way_hit[2]  || way_hit[1]  || way_hit[0];
end : calc_hit 


always_comb begin : update_way
  for(int i = 0; i < 4; i++) begin 
    mask[i] = 32'd0; 
    tag_ld[i] = 1'b0; 
    valid_ld[i] = 1'b0; 
    dirty_ld[i] = 1'b0;
    line_in[i] = mem_wdata; 
    dirty_i[i] = 1'b0; 
  end 

  case(writing)
    /* Load from memory */
    2'b00: begin 
      case(lru_o[index])
        /* MRU was A/B, A, C -> Replace D or MRU was A/B, B, C -> Replace D */
        3'b000, 3'b010: begin
          line_in[0] = pmem_rdata; 
          mask[0] = 32'hFFFFFFFF; 
          tag_ld[0] = tag_load; 
          valid_ld[0] = valid_load; 
          dirty_i[0] = dirty_in; 
          dirty_ld[0] = dirty_load;
        end
        /* MRU was A/B, A, D -> Replace C or MRU was A/B, B, D -> Replace C */
        3'b001, 3'b011: begin 
          line_in[1] = pmem_rdata; 
          mask[1] = 32'hFFFFFFFF; 
          tag_ld[1] = tag_load; 
          valid_ld[1] = valid_load; 
          dirty_i[1] = dirty_in; 
          dirty_ld[1] = dirty_load;
        end
        /* MRU was C/D, A, C -> Replace B or MRU was C/D, A, D -> Replace B */
        3'b100, 3'b101: begin 
          line_in[2] = pmem_rdata; 
          mask[2] = 32'hFFFFFFFF; 
          tag_ld[2] = tag_load; 
          valid_ld[2] = valid_load; 
          dirty_i[2] = dirty_in; 
          dirty_ld[2] = dirty_load;
        end 
        /* MRU was C/D, B, C -> Replace A or MRU was C/D, A, C -> Replace A */
        3'b110, 3'b111: begin 
          line_in[3] = pmem_rdata; 
          mask[3] = 32'hFFFFFFFF; 
          tag_ld[3] = tag_load; 
          valid_ld[3] = valid_load; 
          dirty_i[3] = dirty_in; 
          dirty_ld[3] = dirty_load;
        end 
      endcase 
    end 
    /* Write from CPU */
    2'b01: begin 
      case(way_hit)
        4'b0001: begin
          line_in[0] = mem_wdata; 
          mask[0] = mem_byte_enable; 
          tag_ld[0] = tag_load; 
          valid_ld[0] = valid_load; 
          dirty_i[0] = dirty_in; 
          dirty_ld[0] = dirty_load;
        end
        4'b0010: begin 
          line_in[1] = mem_wdata; 
          mask[1] = mem_byte_enable; 
          tag_ld[1] = tag_load; 
          valid_ld[1] = valid_load; 
          dirty_i[1] = dirty_in; 
          dirty_ld[1] = dirty_load;
        end
        4'b0100: begin 
          line_in[2] = mem_wdata; 
          mask[2] = mem_byte_enable; 
          tag_ld[2] = tag_load; 
          valid_ld[2] = valid_load; 
          dirty_i[2] = dirty_in; 
          dirty_ld[2] = dirty_load;
        end 
        4'b1000: begin 
          line_in[3] = mem_wdata; 
          mask[3] = mem_byte_enable; 
          tag_ld[3] = tag_load; 
          valid_ld[3] = valid_load; 
          dirty_i[3] = dirty_in; 
          dirty_ld[3] = dirty_load;
        end
        default:;
      endcase 
    end 
    default:;
  endcase 
end : update_way

always_comb begin : cache_output
  /* assign the dirty_out for the control */
  dirty_out = 1'b0; 

  /* Set physical mem address and the writeback data and dirty bit for control logic to dictate pmem_write */
  case(lru_o[index])
    /* MRU was A/B, A, C -> Replace D or MRU was A/B, B, C -> Replace D */
    3'b000, 3'b010: begin 
      pmem_address = dirty_o[0] ? {tag_out[0], mem_address[s_offset+s_index-1:0]} : mem_address;
      pmem_wdata = line_out[0];
      dirty_out = dirty_o[0];
    end 
    /* MRU was A/B, A, D -> Replace C or MRU was A/B, B, D -> Replace C */
    3'b001, 3'b011: begin 
      pmem_address = dirty_o[1] ? {tag_out[1], mem_address[s_offset+s_index-1:0]} : mem_address;
      pmem_wdata = line_out[1];
      dirty_out = dirty_o[1];
    end 
    /* MRU was C/D, A, C -> Replace B or MRU was C/D, A, D -> Replace B */
    3'b100, 3'b101: begin 
      pmem_address = dirty_o[2] ? {tag_out[2], mem_address[s_offset+s_index-1:0]} : mem_address;
      pmem_wdata = line_out[2];
      dirty_out = dirty_o[2];
    end 
      /* MRU was C/D, B, C -> Replace A or MRU was C/D, A, C -> Replace A */
    3'b110, 3'b111: begin 
      pmem_address = dirty_o[3] ? {tag_out[3], mem_address[s_offset+s_index-1:0]} : mem_address;
      pmem_wdata = line_out[3];
      dirty_out = dirty_o[3];
    end 
    default:; 
  endcase 

  /* Set the returned data to CPU based off hit */
 
  case(way_hit) 
    4'b1000: mem_rdata = line_out[3];
    4'b0100: mem_rdata = line_out[2];
    4'b0010: mem_rdata = line_out[1];
    4'b0001: mem_rdata = line_out[0];
    default: mem_rdata = line_out[3]; 
  endcase 
end : cache_output 

always_comb begin
  address_tag = mem_address[31:s_offset+s_index];
  index = mem_address[s_offset+s_index-1:s_offset];
end

/* Way instansiation */
data_array #(s_offset, s_index) wayA (clk, mask[3], index, index, line_in[3], line_out[3]);
array #(s_tag,s_index) tagA (clk, tag_ld[3], index, index, address_tag, tag_out[3]);
array #(1,s_index) validA (clk, valid_ld[3], index, index, 1'b1, valid_out[3]);
array #(1,s_index) dirtyA (clk, dirty_ld[3], index, index, dirty_i[3], dirty_o[3]);

data_array  #(s_offset, s_index) wayB (clk, mask[2], index, index, line_in[2], line_out[2]);
array #(s_tag,s_index) tagB (clk, tag_ld[2], index, index, address_tag, tag_out[2]);
array #(1,s_index) validB (clk, valid_ld[2], index, index, 1'b1, valid_out[2]);
array #(1,s_index) dirtyB (clk, dirty_ld[2], index, index, dirty_i[2], dirty_o[2]);

data_array  #(s_offset, s_index)  wayC (clk, mask[1], index, index, line_in[1], line_out[1]);
array #(s_tag,s_index) tagC (clk, tag_ld[1], index, index, address_tag, tag_out[1]);
array #(1,s_index) validC (clk, valid_ld[1], index, index, 1'b1, valid_out[1]);
array #(1,s_index) dirtyC (clk, dirty_ld[1], index, index, dirty_i[1], dirty_o[1]);

data_array  #(s_offset, s_index) wayD (clk, mask[0], index, index, line_in[0], line_out[0]);
array #(s_tag,s_index) tagD (clk, tag_ld[0], index, index, address_tag, tag_out[0]);
array #(1,s_index) validD (clk, valid_ld[0], index, index, 1'b1, valid_out[0]);
array #(1,s_index) dirtyD (clk, dirty_ld[0], index, index, dirty_i[0], dirty_o[0]);

endmodule : cache_datapath