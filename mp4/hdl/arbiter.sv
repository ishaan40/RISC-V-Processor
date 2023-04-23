import rv32i_types::*;

module arbiter (
    input clk, 
    input rst,
    // instruction cache ports
    input rv32i_word inst_pmem_address,
    input logic inst_pmem_read, 
    output rv32i_line inst_pmem_rdata, 
    output logic inst_pmem_resp,
    // data cache ports 
    input rv32i_word data_pmem_address,
    input logic data_pmem_read, 
    input logic data_pmem_write,
    input rv32i_line data_pmem_wdata, 
    output rv32i_line data_pmem_rdata, 
    output logic data_pmem_resp,
    // physical memory ports
    input logic [63:0] pmem_rdata, 
    input logic pmem_resp,
    output logic pmem_write,
    output logic pmem_read,
    output logic [63:0] pmem_wdata, 
    output rv32i_word pmem_addr
);

/*Logic Declarations*/
rv32i_line line_i,line_o;
rv32i_word address_i;
logic read_i, write_i, resp_o;

function void set_defaults();
    read_i = 1'b0;
    write_i = 1'b0;
    address_i = 32'd0;
    inst_pmem_resp = 1'b0;
    data_pmem_resp = 1'b0;
    line_i = data_pmem_wdata;
    inst_pmem_rdata = line_o;
    data_pmem_rdata = line_o;
endfunction

/*States*/
enum int unsigned {
    idle, instr_mem, data_mem
} state, next_state;

/*State Actions*/
always_comb
begin: state_actions
    /*Default Output Assignments*/
    set_defaults();
    case(state)
        idle: begin 
            if(inst_pmem_read || data_pmem_read) begin
                read_i = 1'b1;
            end 
            else if(data_pmem_write) begin
                write_i = 1'b1;
            end
            if(inst_pmem_read) begin
                address_i = inst_pmem_address;
            end
            else begin
                address_i = data_pmem_address;
            end
        end
        instr_mem: begin 
            if(resp_o) begin
                inst_pmem_resp = 1'b1;
                if(data_pmem_read || data_pmem_write) begin 
                    address_i = data_pmem_address; 
                    if (data_pmem_read)
                        read_i = 1'b1;
                    else
                        write_i = 1'b1; 
                end 
            end
            else begin 
                read_i = 1'b1;
                address_i = inst_pmem_address;
            end 
        end
        data_mem: begin
            if(resp_o) begin
                data_pmem_resp = 1'b1;
                if (inst_pmem_read) begin 
                    read_i = 1'b1; 
                    address_i = inst_pmem_address; 
                end 
            end
            else begin 
                if(data_pmem_read) begin 
                    read_i = 1'b1;
                end 
                else begin 
                    write_i = 1'b1; 
                end 
                address_i = data_pmem_address;
            end 
        end
        default:;
    endcase
end

/*State Transition*/
always_comb
begin: next_state_logic
    next_state = state;
    case(state)
        idle: begin
            if(inst_pmem_read) begin
                next_state = instr_mem;
            end 
            else if (data_pmem_read || data_pmem_write) begin
                next_state = data_mem;
            end 
            else begin
                next_state = idle;
            end
        end
        instr_mem: begin
            if(!resp_o) begin
                next_state = instr_mem;
            end 
            else if (data_pmem_read || data_pmem_write) begin
                next_state = data_mem;
            end 
            else begin
                next_state = idle;
            end
        end
        data_mem: begin
            if(!resp_o) begin 
                next_state  = data_mem;
            end 
            else if (inst_pmem_read) begin
                next_state = instr_mem;
            end 
            else begin 
                next_state = idle;
            end
        end
        default:;
    endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    state <= next_state;
end

cacheline_adaptor cacheline_adaptor (
    .clk(clk),
    .reset_n(~rst),
    .line_i(line_i),
    .line_o(line_o),
    .address_i(address_i),
    .read_i(read_i),
    .write_i(write_i),
    .resp_o(resp_o),
    .burst_i(pmem_rdata),
    .burst_o(pmem_wdata),
    .address_o(pmem_addr),
    .read_o(pmem_read),
    .write_o(pmem_write),
    .resp_i(pmem_resp)
);

endmodule : arbiter 