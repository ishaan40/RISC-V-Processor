import rv32i_types::*;

module forwarding_unit (
    input rv32i_reg dest_ex_mem,
    input rv32i_reg dest_mem_wb,
    input rv32i_reg src1,
    input rv32i_reg src2,
    input rv32i_word data_ex_mem,
    input rv32i_word data_mem_wb,
    input rv32i_word data_mdr_in,
    input rv32i_word data_mdr,
    input logic ld_regfile_ex_mem,
    input logic ld_regfile_mem_wb,
    input logic dmem_read_in,
    input logic dmem_read,
    input logic alumux1_sel,
    input logic alumux2_sel,
    input logic cmpmux2_sel,
    input logic br_ex_mem,
    input logic br_mem_wb,
    input rv32i_opcode opcode,
    input regfilemux::regfilemux_sel_t ex_mem_regfile_mux_sel,
    input regfilemux::regfilemux_sel_t mem_wb_regfile_mux_sel,
    output rv32i_word ex_mem_forwarding_out1,
    output rv32i_word mem_wb_forwarding_out1,
    output rv32i_word ex_mem_forwarding_out2,
    output rv32i_word mem_wb_forwarding_out2,
    output rv32i_word ex_mem_forwarding_cmp1out,
    output rv32i_word mem_wb_forwarding_cmp1out,
    output rv32i_word ex_mem_forwarding_cmp2out,
    output rv32i_word mem_wb_forwarding_cmp2out,
    output rv32i_word forwarded_store_data,  
    output logic forwarding_load1,
    output logic forwarding_load2,
    output logic forwarding_cmp1_load,
    output logic forwarding_cmp2_load,
    output logic forwarding_mux1,
    output logic forwarding_mux2,
    output logic forwarding_cmp1mux,
    output logic forwarding_cmp2mux,
    output logic forwarding_store
);

function void set_defaults();
    // default (no forwarding required)
    forwarding_load1 = 1'b0;
    forwarding_load2 = 1'b0;
    forwarding_cmp1_load = 1'b0;
    forwarding_cmp2_load = 1'b0;
    forwarding_mux1 = 1'b0;
    forwarding_mux2 = 1'b0;
    forwarding_cmp1mux = 1'b0;
    forwarding_cmp2mux = 1'b0;
    ex_mem_forwarding_out1 = 0;
    mem_wb_forwarding_out1 = 0;
    ex_mem_forwarding_out2 = 0;
    mem_wb_forwarding_out2 = 0;
    ex_mem_forwarding_cmp1out = 0;
    mem_wb_forwarding_cmp1out = 0;
    ex_mem_forwarding_cmp2out = 0;
    mem_wb_forwarding_cmp2out = 0;  
endfunction

function void set_store_defaults();
    forwarded_store_data = 0; 
    forwarding_store = 0;
endfunction


always_comb begin
    set_store_defaults();
    if(opcode == op_store) begin
        case({ld_regfile_ex_mem, ld_regfile_mem_wb})
            2'b00: ;
            2'b01: begin
                    if(dest_mem_wb == src2) begin
                        forwarded_store_data = (dmem_read == 1'b1) ? data_mdr : data_mem_wb;
                        forwarding_store = 1'b1;
                    end
                end
            2'b10: begin
                    if(dest_ex_mem == src2) begin
                        forwarded_store_data = (dmem_read_in == 1'b1) ? data_mdr_in : data_ex_mem;
                        forwarding_store = 1'b1;
                    end
                end
            2'b11: begin
                    if(dest_mem_wb == dest_ex_mem) begin
                        if(dest_ex_mem == src2) begin
                            forwarded_store_data = (dmem_read_in == 1'b1) ? data_mdr_in : data_ex_mem;
                            forwarding_store = 1'b1;
                        end
                    end
                    else if(dest_mem_wb == src2) begin
                        forwarded_store_data = (dmem_read == 1'b1) ? data_mdr : data_mem_wb;
                        forwarding_store = 1'b1;
                    end
                    else if(dest_ex_mem == src2) begin
                        forwarded_store_data = (dmem_read_in == 1'b1) ? data_mdr_in : data_ex_mem;
                        forwarding_store = 1'b1;                        
                    end
                end
        endcase
    end
end

always_comb begin
    set_defaults();
    // alu forwarding logic
    case({ld_regfile_ex_mem, ld_regfile_mem_wb})
        2'b00:;
        2'b01: begin
            if(dest_mem_wb == src1 && alumux1_sel == 1'b0) begin
                if(src1 == 0) begin
                    ex_mem_forwarding_out1 = 32'd0;
                    mem_wb_forwarding_out1 = 32'd0;
                    forwarding_load1 = 1'b1;
                end
                else if(mem_wb_regfile_mux_sel == regfilemux::br_en) begin
                    mem_wb_forwarding_out1 = br_mem_wb;
                    forwarding_load1 = 1'b1;
                end
                else begin
                    mem_wb_forwarding_out1 = (dmem_read == 1'b1) ? data_mdr : data_mem_wb;
                    forwarding_load1 = 1'b1;
                end
                forwarding_mux1 = 1'b1;
            end
            if(dest_mem_wb == src2 && alumux2_sel == 1'b1) begin
                if(src2 == 0) begin
                    ex_mem_forwarding_out2 = 32'd0;
                    mem_wb_forwarding_out2 = 32'd0;
                    forwarding_load2 = 1'b1;
                end
                else if(mem_wb_regfile_mux_sel == regfilemux::br_en) begin
                    mem_wb_forwarding_out2 = br_mem_wb;
                    forwarding_load2 = 1'b1;
                end
                else begin
                    mem_wb_forwarding_out2 = (dmem_read == 1'b1) ? data_mdr : data_mem_wb;
                    forwarding_load2 = 1'b1;
                end
                forwarding_mux2 = 1'b1;
            end
        end
        2'b10: begin
            if(dest_ex_mem == src1 && alumux1_sel == 1'b0) begin
                if(src1 == 0) begin
                    ex_mem_forwarding_out1 = 32'd0;
                    mem_wb_forwarding_out1 = 32'd0;
                    forwarding_load1 = 1'b1;
                end
                else if(ex_mem_regfile_mux_sel == regfilemux::br_en) begin
                    ex_mem_forwarding_out1 = br_ex_mem;
                    forwarding_load1 = 1'b1;
                end
                else begin
                    ex_mem_forwarding_out1 = (dmem_read_in == 1'b1) ? data_mdr_in : data_ex_mem;
                    forwarding_load1 = 1'b1;
                end
                forwarding_mux1 = 1'b0;
            end
            if(dest_ex_mem == src2 && alumux2_sel == 1'b1) begin
                if(src2 == 0) begin
                    ex_mem_forwarding_out2 = 32'd0;
                    mem_wb_forwarding_out2 = 32'd0;
                    forwarding_load2 = 1'b1;
                end
                else if(ex_mem_regfile_mux_sel == regfilemux::br_en) begin
                    ex_mem_forwarding_out2 = br_ex_mem;
                    forwarding_load2 = 1'b1;
                end
                else begin
                    ex_mem_forwarding_out2 = (dmem_read_in == 1'b1) ? data_mdr_in : data_ex_mem;
                    forwarding_load2 = 1'b1;
                end
                forwarding_mux2 = 1'b0;
            end
        end 
        2'b11: begin
            if(dest_mem_wb == dest_ex_mem) begin
                if(dest_ex_mem == src1 && alumux1_sel == 1'b0) begin
                    if(src1 == 0) begin
                        ex_mem_forwarding_out1 = 32'd0;
                        mem_wb_forwarding_out1 = 32'd0;
                        forwarding_load1 = 1'b1;
                    end
                    else if(ex_mem_regfile_mux_sel == regfilemux::br_en) begin
                        ex_mem_forwarding_out1 = br_ex_mem;
                        forwarding_load1 = 1'b1;
                    end
                    else begin
                        ex_mem_forwarding_out1 = (dmem_read_in == 1'b1) ? data_mdr_in : data_ex_mem;
                        forwarding_load1 = 1'b1;
                    end
                    forwarding_mux1 = 1'b0;
                end
                if(dest_ex_mem == src2 && alumux2_sel == 1'b1) begin
                    if(src2 == 0) begin
                        ex_mem_forwarding_out2 = 32'd0;
                        mem_wb_forwarding_out2 = 32'd0;
                        forwarding_load2 = 1'b1;
                    end
                    else if(ex_mem_regfile_mux_sel == regfilemux::br_en) begin
                        ex_mem_forwarding_out2 = br_ex_mem;
                        forwarding_load2 = 1'b1;
                    end
                    else begin
                        ex_mem_forwarding_out2 = (dmem_read_in == 1'b1) ? data_mdr_in : data_ex_mem;
                        forwarding_load2 = 1'b1;
                    end
                    forwarding_mux2 = 1'b0;
                end
            end
            else begin
                if(dest_mem_wb == src1 && alumux1_sel == 1'b0) begin
                    if(src1 == 0) begin
                        ex_mem_forwarding_out1 = 32'd0;
                        mem_wb_forwarding_out1 = 32'd0;
                        forwarding_load1 = 1'b1;
                    end
                    else if(mem_wb_regfile_mux_sel == regfilemux::br_en) begin
                        mem_wb_forwarding_out1 = br_mem_wb;
                        forwarding_load1 = 1'b1;
                    end
                    else begin
                        mem_wb_forwarding_out1 = (dmem_read == 1'b1) ? data_mdr : data_mem_wb;
                        forwarding_load1 = 1'b1;
                    end
                    forwarding_mux1 = 1'b1;
                end
                if(dest_mem_wb == src2 && alumux2_sel == 1'b1) begin
                    if(src2 == 0) begin
                        ex_mem_forwarding_out2 = 32'd0;
                        mem_wb_forwarding_out2 = 32'd0;
                        forwarding_load2 = 1'b1;
                    end
                    else if(mem_wb_regfile_mux_sel == regfilemux::br_en) begin
                        mem_wb_forwarding_out2 = br_mem_wb;
                        forwarding_load2 = 1'b1;
                    end
                    else begin
                        mem_wb_forwarding_out2 = (dmem_read == 1'b1) ? data_mdr : data_mem_wb;
                        forwarding_load2 = 1'b1;
                    end
                    forwarding_mux2 = 1'b1;
                end
                if(dest_ex_mem == src1 && alumux1_sel == 1'b0) begin
                    if(src1 == 0) begin
                        ex_mem_forwarding_out1 = 32'd0;
                        mem_wb_forwarding_out1 = 32'd0;
                        forwarding_load1 = 1'b1;
                    end
                    else if(ex_mem_regfile_mux_sel == regfilemux::br_en) begin
                        ex_mem_forwarding_out1 = br_ex_mem;
                        forwarding_load1 = 1'b1;
                    end
                    else begin
                        ex_mem_forwarding_out1 = (dmem_read_in == 1'b1) ? data_mdr_in : data_ex_mem;
                        forwarding_load1 = 1'b1;
                    end
                    forwarding_mux1 = 1'b0;
                end
                if(dest_ex_mem == src2 && alumux2_sel == 1'b1) begin
                    if(src2 == 0) begin
                        ex_mem_forwarding_out2 = 32'd0;
                        mem_wb_forwarding_out2 = 32'd0;
                        forwarding_load2 = 1'b1;
                    end
                    else if(ex_mem_regfile_mux_sel == regfilemux::br_en) begin
                        ex_mem_forwarding_out2 = br_ex_mem;
                        forwarding_load2 = 1'b1;
                    end
                    else begin
                        ex_mem_forwarding_out2 = (dmem_read_in == 1'b1) ? data_mdr_in : data_ex_mem;
                        forwarding_load2 = 1'b1;
                    end
                    forwarding_mux2 = 1'b0;
                end
            end
        end
    endcase
    // comparator forwarding unit
    if(dest_ex_mem == src1) begin
        if(src1 == 0) begin
            ex_mem_forwarding_cmp1out = 32'd0;
            mem_wb_forwarding_cmp1out = 32'd0;
            forwarding_cmp1_load = 1'b1;
        end
        else if(ex_mem_regfile_mux_sel == regfilemux::br_en) begin
            ex_mem_forwarding_cmp1out = br_ex_mem;
            forwarding_cmp1_load = 1'b1;
        end
        else begin
            ex_mem_forwarding_cmp1out = (dmem_read_in == 1'b1) ? data_mdr_in : data_ex_mem;
            forwarding_cmp1_load = 1'b1;
        end
        forwarding_cmp1mux = 1'b0;
    end
    else if(dest_mem_wb == src1) begin
        if(src1 == 0) begin
            ex_mem_forwarding_cmp1out = 32'd0;
            mem_wb_forwarding_cmp1out = 32'd0;
            forwarding_cmp1_load = 1'b1;
        end
        else if(mem_wb_regfile_mux_sel == regfilemux::br_en) begin
            mem_wb_forwarding_cmp1out = br_mem_wb;
            forwarding_cmp1_load = 1'b1;
        end
        else begin
            mem_wb_forwarding_cmp1out = (dmem_read == 1'b1) ? data_mdr : data_mem_wb;
            forwarding_cmp1_load = 1'b1;
        end
        forwarding_cmp1mux = 1'b1;
    end

    if(dest_ex_mem == src2 && cmpmux2_sel == 1'b0) begin
        if(src2 == 0) begin
            ex_mem_forwarding_cmp2out = 32'd0;
            mem_wb_forwarding_cmp2out = 32'd0;
            forwarding_cmp2_load = 1'b1;
        end
        else if(ex_mem_regfile_mux_sel == regfilemux::br_en) begin
            ex_mem_forwarding_cmp2out = br_ex_mem;
            forwarding_cmp2_load = 1'b1;
        end
        else begin
            ex_mem_forwarding_cmp2out = (dmem_read_in == 1'b1) ? data_mdr_in : data_ex_mem;
            forwarding_cmp2_load = 1'b1;
        end
        forwarding_cmp2mux = 1'b0;
    end
    else if(dest_mem_wb == src2 && cmpmux2_sel == 1'b0) begin
        if(src2 == 0) begin
            ex_mem_forwarding_cmp2out = 32'd0;
            mem_wb_forwarding_cmp2out = 32'd0;
            forwarding_cmp2_load = 1'b1;
        end
        else if(mem_wb_regfile_mux_sel == regfilemux::br_en) begin
            mem_wb_forwarding_cmp2out = br_mem_wb;
            forwarding_cmp2_load = 1'b1;
        end
        else begin
            mem_wb_forwarding_cmp2out = (dmem_read == 1'b1) ? data_mdr : data_mem_wb;
            forwarding_cmp2_load = 1'b1;
        end
        forwarding_cmp2mux = 1'b1;
    end
end
endmodule : forwarding_unit