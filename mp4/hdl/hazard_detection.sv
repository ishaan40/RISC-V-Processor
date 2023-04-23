import rv32i_types::*; 

module hazard_detection_unit (
    // added clk and rst for performance counter -- REMOVE WHEN DONE
    input logic clk,
    input logic rst,
    // added clk and rst for performance counter -- REMOVE WHEN DONE
    input logic dmem_read, 
    input logic dmem_write,
    input logic muldiv_start,
    input logic muldiv_resp,
    input logic data_resp_dp,
    input logic inst_resp_dp,
    input rv32i_reg dest, 
    input rv32i_reg src1,
    input rv32i_reg src2, 
    input logic br_en, 
    input logic jump_en,
    input rv32i_opcode opcode,
    output logic inst_read,
    output logic rst_IF_ID, 
    output logic rst_ID_EX,
    output logic rst_EX_MEM, 
    output logic rst_MEM_WB,
    output logic load_IF_ID, 
    output logic load_ID_EX, 
    output logic load_EX_MEM,
    output logic load_MEM_WB,
    output logic load_pc
);
function void set_defaults(); 
    // default (no stall/no no-ops)
    rst_IF_ID = 1'b0; 
    rst_ID_EX = 1'b0; 
    rst_EX_MEM = 1'b0;
    rst_MEM_WB = 1'b0;  
    load_IF_ID = 1'b1; 
    load_ID_EX = 1'b1; 
    load_EX_MEM = 1'b1;
    load_MEM_WB = 1'b1; 
    load_pc = 1'b1; 
    inst_read = 1'b1; 
endfunction

function void load_stall(); 
    // inst_read = 1'b0; probably not needed
    load_pc = 1'b0; 
    load_IF_ID = 1'b0; 
    load_ID_EX = 1'b0; 
    load_EX_MEM = 1'b0;
    load_MEM_WB = 1'b0; //enable this hotfix if shit doesnt work 
endfunction 

function void load_hit();
// reset if there is a dependency (forwarding) because we want to ID_EX to grab values from regfile
    if(dest == src1 || dest == src2) begin
        rst_EX_MEM = 1'b1;
        load_pc = 1'b0;
        load_IF_ID = 1'b0; 
        load_ID_EX = 1'b0; 
    end
endfunction 

// performance counter - counts the number of extra stalls due to M extension instructions
logic [31:0] counter;
register muldiv_pc (.clk(clk), .rst(rst), .load(muldiv_resp), .in(counter + 32'b1), .out(counter));

always_comb begin 
    set_defaults();
    case({(jump_en || (br_en && opcode == op_br)), inst_resp_dp, dmem_read || dmem_write || muldiv_start, data_resp_dp || muldiv_resp})
    // NO BRANCHING, INSTRUCTION MISS, NO LOAD, xxxxxxx
    // example: 9 instructions all adds, misses on 9th instruction 
    4'b0000: begin 
        load_pc = 1'b0; 
        rst_IF_ID = 1'b1; 
    end 
    // NO BRANCHING, INSTRUCTION MISS, NO LOAD, DATA CACHE HIT?
    // no example, cannot have data hit and no load instruction 
    4'b0001:;
    // NO BRANCHING, INSTRUCTION MISS, LOAD, DATA CACHE MISS
    // example: 9 instructions, LOAD on 6th instruction (which becomes data miss on 9th), 9th is instruction miss
    4'b0010: begin 
        load_stall();
    end 
    // NO BRANCHING, INSTRUCTION MISS, LOAD, DATA CACHE HIT
    // example: 9 instructions, LOAD on 6th instruction (which becomes data hit on 9th), 9th is instruction miss
    4'b0011: begin
        if((muldiv_start && (dmem_read && !data_resp_dp)) || (dmem_read && (muldiv_start && !muldiv_resp)))
            load_stall();
        load_pc = 1'b0;
        rst_IF_ID = 1'b1; 
    end 
    // NO BRANCHING, INSTRUCTION HIT, NO LOAD, xxxxxxx
    // example: In 8 instruction window, and there's no load/branches prior to the current instruction (if_id_i)
    4'b0100: begin 
        load_pc = 1'b1; 
        inst_read = 1'b1; 
    end 
    // NO BRANCHING, INSTRUCTION HIT, NO LOAD, DATA CACHE HIT?
    // no example, cannot have data hit and no load instruction 
    4'b0101:;
    // NO BRANCHING, INSTRUCTION HIT, LOAD, DATA CACHE MISS
    // example: In 8 instruction window, there is a load (which occured within the first 5 instructions)
    4'b0110: begin 
        load_stall();
    end 
    // NO BRANCHING, INSTRUCTION HIT, LOAD, DATA CACHE HIT 
    // example: In an 8 instruction window, there was a load (within the first 5 instructions) which became a hit before the 9th instruction
    4'b0111: begin 
        if((muldiv_start && (dmem_read && !data_resp_dp)) || (dmem_read && (muldiv_start && !muldiv_resp)))
            load_stall();
    end
    // BRANCHING, INSTRUCTION MISS, NO LOAD, xxxxxxx
    // example: 9 instructions, branch on the 6th (which gets evaluated on the 9th)
    4'b1000: begin 
        load_stall();
        rst_IF_ID = 1'b1; 
    end 
    // BRANCHING, INSTRUCTION MISS, NO LOAD, DATA CACHE HIT?
    // no example cannot have data hit and no load instruction 
    4'b1001:;

    // BRANCHING, INSTRUCTION MISS, LOAD, DATA CACHE MISS 
    // example: 9 instruction window, branch on the 7th (which gets eval on the 9th) load on the 6th (which becomes a miss on the 9th)
    4'b1010: begin 
        load_stall();
        rst_IF_ID = 1'b1; 
    end 
    // BRANCHING, INSTRUCTION MISS, LOAD, DATA CACHE HIT
    // example: 9 instruction window, branch on 7th (eval at 9th), load on 6th (which becomes a hit on the 9th)
    4'b1011: begin 
        if((muldiv_start && (dmem_read && !data_resp_dp)) || (dmem_read && (muldiv_start && !muldiv_resp)))
            load_stall();
        load_pc = 1'b0;
        load_ID_EX = 1'b0; 
        rst_IF_ID = 1'b1;
    end 
    // BRANCHING, INSTRUCTION HIT, NO LOAD, xxxxxxx
    // example: 8 instruction window, branch within the first 6 (which gets eval at the 8th)
    4'b1100: begin 
        load_pc = 1'b1; 
        inst_read = 1'b1; 
        rst_IF_ID = 1'b1; 
        rst_ID_EX = 1'b1; 
    end 
    // BRANCHING, INSTRUCTION HIT, NO LOAD, DATA CACHE HIT?
    // no example
    4'b1101:;
    // BRANCHING, INSTRUCTION HIT, LOAD, DATA CACHE MISS 
    // example: 8 instruction window, consecutive load/branch (load within the first 5)
    4'b1110: begin 
        load_stall();
        rst_IF_ID = 1'b1; 
    end 
    // BRANCHING, INSTRUCTION HIT, LOAD, DATA CACHE HIT
    // example: 8 instruction window, consecutive load/branch (load within the first 5)
    4'b1111: begin 
        if((muldiv_start && (dmem_read && !data_resp_dp)) || (dmem_read && (muldiv_start && !muldiv_resp)))
            load_stall();
        load_ID_EX = 1'b0; 
        rst_IF_ID = 1'b1; 
    end 
    endcase 
end 
endmodule : hazard_detection_unit