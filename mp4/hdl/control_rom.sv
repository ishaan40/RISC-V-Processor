import rv32i_types::*;

module control_rom
(
    input rv32i_opcode opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7, 
    output rv32i_control_word ctrl_word
);
branch_funct3_t branch_funct3;
//store_funct3_t store_funct3;
load_funct3_t load_funct3;
arith_funct3_t arith_funct3;

assign arith_funct3 = arith_funct3_t'(funct3);
assign branch_funct3 = branch_funct3_t'(funct3);
assign load_funct3 = load_funct3_t'(funct3);
//assign store_funct3 = store_funct3_t'(funct3);

/* Helper functions */
function void loadRegfile(regfilemux::regfilemux_sel_t sel);
    ctrl_word.load_regfile = 1'b1; 
    ctrl_word.regfilemux_sel = sel;
endfunction
function void setALU(alumux::alumux1_sel_t sel1,
                     logic setop = 1'b0, alu_ops op = alu_add);
    if (setop) begin 
        ctrl_word.aluop = op;
        ctrl_word.alumux1_sel = sel1; 
    end 
endfunction
function automatic void setCMP(cmpmux::cmpmux_sel_t sel, 
                               logic setop = 1'b0, branch_funct3_t op = beq);
    if (setop) begin 
        ctrl_word.cmpop = op; 
        ctrl_word.cmpmux_sel = sel; 
    end 
endfunction

always_comb
begin
    /* Default assignments */
    ctrl_word.load_regfile = 1'b0;
    ctrl_word.regfilemux_sel = regfilemux::alu_out; 
    ctrl_word.cmpmux_sel = cmpmux::rs2_out; 
    ctrl_word.alumux1_sel = alumux::rs1_out; 
    ctrl_word.cmpop = beq; 
    ctrl_word.aluop = alu_add; /* changed this to alu_add */
    ctrl_word.dmem_read = 1'b0;
    ctrl_word.dmem_write = 1'b0; 
    ctrl_word.mem_byte_enable = 4'b1111; 
    ctrl_word.opcode = opcode; 
    ctrl_word.funct3 = funct3; 
    ctrl_word.funct7 = funct7;
    ctrl_word.br_en = 1'b0; 
    /* Assign control signals based on opcode */
    case(opcode)
        op_lui: begin 
            loadRegfile(regfilemux::u_imm);
        end 
        op_auipc: begin
            setALU(alumux::pc_out, 1'b1, alu_add);
            loadRegfile(regfilemux::alu_out);            
        end
        op_jal: begin 
            loadRegfile(regfilemux::pc_plus4);
            setALU(alumux::pc_out, 1'b1, alu_add);
        end 
        op_jalr: begin 
            loadRegfile(regfilemux::pc_plus4);
            setALU(alumux::rs1_out, 1'b1, alu_add);
        end 
        op_br: begin 
            setALU(alumux::pc_out, 1'b1, alu_add); 
            setCMP(cmpmux::rs2_out, 1'b1, branch_funct3);
        end 
        op_load: begin 
            ctrl_word.dmem_read = 1'b1; 
            setALU(alumux::rs1_out, 1'b1, alu_add);
            case(load_funct3)
                lb: loadRegfile(regfilemux::lb);
                lh: loadRegfile(regfilemux::lh);
                lw: loadRegfile(regfilemux::lw);
                lbu: loadRegfile(regfilemux::lbu);
                lhu: loadRegfile(regfilemux::lhu);
                default:;
            endcase
        end 
        op_store: begin 
            setALU(alumux::rs1_out, 1'b1, alu_add);
            ctrl_word.dmem_write = 1'b1; 
        end 
        op_imm: begin 
            case(arith_funct3)
                slt: begin 
                    setCMP(cmpmux::i_imm, 1'b1, blt);
                    loadRegfile(regfilemux::br_en);
                end 
                sltu: begin 
                    setCMP(cmpmux::i_imm, 1'b1, bltu);   
                    loadRegfile(regfilemux::br_en);
                end 
                sr: begin 
                    loadRegfile(regfilemux::alu_out);
                    if(funct7[5])
                        setALU(alumux::rs1_out, 1'b1, alu_sra);
                    else
                        setALU(alumux::rs1_out, 1'b1, alu_srl);
                end
                default: begin 
                    loadRegfile(regfilemux::alu_out);
                    setALU(alumux::rs1_out, 1'b1, alu_ops'(arith_funct3));
                end 
            endcase 
        end 
        op_reg: begin
            if(funct7 == 7'd1) begin
                loadRegfile(regfilemux::alu_out);
            end 
            else begin
                case(arith_funct3)
                    add: begin
                        loadRegfile(regfilemux::alu_out); 
                        if(funct7[5])
                            setALU(alumux::rs1_out, 1'b1, alu_sub);
                        else
                            setALU(alumux::rs1_out, 1'b1, alu_add);
                    end 
                    slt: begin 
                        setCMP(cmpmux::rs2_out, 1'b1, blt);
                        loadRegfile(regfilemux::br_en);
                    end 
                    sltu: begin 
                        setCMP(cmpmux::rs2_out, 1'b1, bltu);
                        loadRegfile(regfilemux::br_en);                    
                    end 
                    sr: begin 
                        loadRegfile(regfilemux::alu_out);
                        if(funct7[5])
                            setALU(alumux::rs1_out, 1'b1, alu_sra);
                        else
                            setALU(alumux::rs1_out, 1'b1, alu_srl);                    
                    end 
                    default: begin 
                        loadRegfile(regfilemux::alu_out);
                        setALU(alumux::rs1_out, 1'b1, alu_ops'(arith_funct3));
                    end    
                endcase 
            end
        end
        default: begin
            ctrl_word.load_regfile = 1'b0;
            ctrl_word.regfilemux_sel = regfilemux::alu_out; 
            ctrl_word.cmpmux_sel = cmpmux::rs2_out; 
            ctrl_word.alumux1_sel = alumux::rs1_out; 
            ctrl_word.cmpop = beq; 
            ctrl_word.aluop = alu_add; /* changed this to alu_add */
            ctrl_word.dmem_read = 1'b0;
            ctrl_word.dmem_write = 1'b0; 
            ctrl_word.mem_byte_enable = 4'b1111; 
            ctrl_word.opcode = opcode; 
            ctrl_word.funct3 = funct3; 
            ctrl_word.funct7 = funct7;
            ctrl_word.br_en = 1'b0;    /* Unknown opcode, set control word to zero */
        end
    endcase
end
endmodule : control_rom