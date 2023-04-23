import rv32i_types::*; 

module prefetch (
    input clk, 
    input rst, 
    /* CACHE -> PREFETCH */
    input rv32i_word inst_pmem_address, 
    input logic inst_pmem_read,
    /* PREFETCH -> CACHE */
    output logic pf_resp, 
    output rv32i_line pf_rdata, 
    /* ARBITER -> PREFETCH */
    input logic inst_pmem_resp,
    input rv32i_line inst_pmem_rdata, 
    /* PREFETCH -> ARBITER */
    output logic pf_read,
    output rv32i_word pf_address 
);

/* Buffer for prefetched data */
rv32i_word prefetch_address_o;
rv32i_word prefetch_address_i;
rv32i_line prefetch_data_o; 
rv32i_line prefetch_data_i;

/* Logic for signaling that data in the prefetch data buffer is valid */
logic pf_done; 
logic load_pf_done;
logic rst_pf_done;  

// performance counter - increments the counter each time we prefetch a new instruction
logic [31:0] counter;
register prefetch_pc (.clk(clk), .rst(rst), .load(pf_resp), .in(counter + 32'b1), .out(counter));

/* idle: waits for a read request by instr cache */
/* prefetch miss: the requested address doesn't match the data in the prefetch address buffer */
/* prefetch_read: currently doing read from phys memory of instr_addr + 256 */
enum int unsigned {
    idle, read_miss, read_prefetch
} state, next_state;

always_comb begin : control_logic 
    prefetch_address_i = prefetch_address_o; 
    prefetch_data_i = prefetch_data_o; 
    pf_resp = 1'b0; 
    pf_rdata = 256'd0; 
    pf_read = 1'b0; 
    pf_address = 32'd0; 
    rst_pf_done = 1'b0; 
    load_pf_done = 1'b0; 

    case(state)
        idle: begin 
            if (inst_pmem_read) begin 
                /* read request matches the prefetched data and the data is valid */
                if (inst_pmem_address == prefetch_address_o && pf_done) begin 
                    pf_rdata = prefetch_data_o; 
                    pf_resp = 1'b1; 
                end
                else begin
                    /* missed so prepare the read the miss and prefetch the miss_addr + 256 */
                    prefetch_address_i = inst_pmem_address + 32'd256;
                end 
            end 
        end 
        read_miss: begin 
            pf_address = inst_pmem_address; 
            pf_read = 1'b1; 
            rst_pf_done = 1'b1; 
            if (inst_pmem_resp) begin 
                pf_rdata = inst_pmem_rdata;
                pf_resp = 1'b1; 
            end 
        end
        read_prefetch: begin 
            pf_address = prefetch_address_o; 
            pf_read = 1'b1; 
            if (inst_pmem_resp) begin 
                prefetch_data_i = inst_pmem_rdata; 
                load_pf_done = 1'b1; 
            end 
        end  
    endcase 
end : control_logic

always_comb begin : next_state_logic 
    next_state = state; 
    case(state)
        idle: begin 
            if (inst_pmem_read) begin 
                if (inst_pmem_address != prefetch_address_o || !pf_done)
                    next_state = read_miss; 
            end 
        end 
        read_miss: begin 
            if (inst_pmem_resp)
                next_state = read_prefetch; 
        end 
        read_prefetch: begin 
            if (inst_pmem_resp)
                next_state = idle; 
        end 
    endcase 

end : next_state_logic

always_ff @(posedge clk) begin : next_state_assignment 
    if (rst) 
        state <= idle; 
    else 
        state <= next_state; 
end : next_state_assignment

always_ff @(posedge clk) begin : pf_done_assignment 
    if (rst || rst_pf_done)
        pf_done <= 1'b0; 
    else if (load_pf_done)
        pf_done <= 1'b1; 
end : pf_done_assignment 

always_ff @(posedge clk) begin : set_prefetch_data 
    if (rst) begin 
        prefetch_address_o <= 32'd0; 
        prefetch_data_o <= 256'd0; 
    end 
    else begin 
        prefetch_address_o <= prefetch_address_i; 
        prefetch_data_o <= prefetch_data_i; 
    end 
end : set_prefetch_data
endmodule : prefetch 
