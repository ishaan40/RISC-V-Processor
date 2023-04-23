import rv32i_types::*; 

module ev_buffer (
    input clk, 
    input rst, 
    /* CACHE -> EV */
    input rv32i_word data_pmem_address,
    input logic data_pmem_write, 
    input logic data_pmem_read, 
    input rv32i_line data_pmem_wdata,
    /* EV -> CACHE */
    output logic ev_resp, 
    output rv32i_line ev_rdata, 
    /* ARBITER -> EV */
    input logic data_pmem_resp, 
    input rv32i_line data_pmem_rdata, 
    /* EV -> ARBITER */
    output rv32i_word ev_address,
    output logic ev_write, 
    output logic ev_read, 
    output rv32i_line ev_wdata
);
/* Buffer the dirty data/address from cache */
rv32i_word dirty_address_o;
rv32i_word dirty_address_i;
rv32i_line dirty_data_o; 
rv32i_line dirty_data_i;

// performance counter register -- measures number of times the eviction buffer is used to hold dirty data and write back to pmem
logic [31:0] counter;
register ev_buffer_pc (.clk(clk), .rst(rst), .load(ev_resp), .in(counter + 32'b1), .out(counter));


/* writeback flag */
logic wb; 
logic load_wb; 
logic rst_wb; 

enum int unsigned {
    idle, read, writeback
} state, next_state; 

always_comb begin : control_logic 
    ev_resp = 1'b0; 
    ev_rdata = 256'd0; 
    ev_address = 32'd0; 
    ev_write = 1'b0;
    ev_read = 1'b0; 
    ev_wdata = 256'd0; 
    load_wb = 1'b0; 
    rst_wb = 1'b0; 
    dirty_address_i = dirty_address_o;
    dirty_data_i = dirty_data_o; 
    case(state)
        idle: begin 
            if (data_pmem_write) begin 
                load_wb = 1'b1; 
                dirty_address_i = data_pmem_address; 
                dirty_data_i = data_pmem_wdata; 
                ev_resp = 1'b1; 
            end 
        end
        read: begin 
            ev_rdata = data_pmem_rdata; 
            ev_resp = data_pmem_resp; 
            ev_address = data_pmem_address; 
            ev_read = 1'b1; 
        end  
        writeback: begin 
            rst_wb = 1'b1; 
            ev_wdata = dirty_data_o; 
            ev_address = dirty_address_o;
            ev_write = 1'b1; 
        end 
    endcase 
end : control_logic 

always_comb begin : next_state_logic 
    next_state = state; 
    case(state)
        idle: begin 
            if (data_pmem_read)
                next_state = read; 
        end 
        read: begin 
            if (data_pmem_resp) begin 
                if (wb)
                    next_state = writeback; 
                else
                    next_state = idle; 
            end 
        end 
        writeback: begin 
            if (data_pmem_resp)
                next_state = idle; 
        end 
    endcase 
end : next_state_logic 

always_ff @(posedge clk) begin : set_dirty_data 
    if (rst) begin 
        dirty_address_o <= 32'd0; 
        dirty_data_o <= 256'd0; 
    end 
    else begin 
        dirty_address_o <= dirty_address_i; 
        dirty_data_o <= dirty_data_i; 
    end 
end : set_dirty_data

always_ff @(posedge clk) begin : next_state_assignment 
    if (rst) 
        state <= idle; 
    else 
        state <= next_state; 
end : next_state_assignment

always_ff @(posedge clk) begin : wb_assignment
    if (rst || rst_wb) 
        wb <= 1'b0; 
    else if (load_wb)
        wb <= 1'b1; 
end : wb_assignment

endmodule : ev_buffer