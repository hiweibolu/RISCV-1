`include "defines.v"
module EX
(
    input wire rst,

    input wire[`Instruction_Address_size] pc,
    input wire[`Alusel_size] alusel,
    input wire[`Aluop_size] aluop,
    input wire[`Data_size] op1,
    input wire[`Data_size] op2,
    input wire write_flag,
    input wire[`Data_Address_size] sl_address, //for save & load
    input wire[`Data_Address_size] sl_offset, //for save & load
    input wire[`Instruction_Address_size] br_address, //for branch
    input wire[`Instruction_Address_size] br_offset, //for branch
    input wire br_JALR, //if instruction is JALR
    input wire prediction,
    //wire from ID_EX
    output reg modify_flag,
    output reg[`Data_Address_size] modify_address,
    output reg[`Data_size] modify_data,
    //for modify
    //wire to EX_MEM

    output reg br_update, // if instruction is branch
    output wire _br_JALR, // if instruction is JALR
    output reg br, // if branch
    output reg[`Instruction_Address_size] _br_address, // address if branch
    output wire[`Instruction_Address_size] _br_pc, //address of the branch instruction
    //wire to predictor
    output reg[`Instruction_Address_size] _br_nxt_address, // next address
    //wire to pc_reg
    output reg br_error, // if branch prediction is wrong
    //wire for discard
    //for branch
    
    output reg load,
    output reg save,
    output reg[`Data_Address_size] sl_reg_address,
    output reg[`Data_size] sl_data,
    output reg[2:0] sl_data_length,
    output reg sl_data_signed
    //for save & load in RAM
    //wire to EX_MEM

    
    // for logic & arith & shift
    // reg[modify_address]=modify_data
    // for save
    // mem[sl_reg_address]=sl_data
    // for load
    // reg[modify_address]=mem[sl_reg_address]
);
assign _br_pc=pc;
assign _br_JALR=br_JALR;
always @ (*)
begin
    modify_flag=0;
    modify_address=0;
    modify_data=0;
    br_update=0;
    br=0;
    _br_address=0;
    _br_nxt_address=0;
    br_error=0;
    load=0;
    save=0;
    sl_data=0;
    sl_data_length=0;
    sl_data_signed=0;
    if (rst==0)
    begin
        modify_flag=write_flag;
        modify_address=sl_address;
        if (alusel==`EX_logic)
        begin
            case (aluop)
                `EX_logic_AND: modify_data=op1&op2;
                `EX_logic_ANDI: modify_data=op1&op2;
                `EX_logic_OR: modify_data=op1|op2;
                `EX_logic_ORI: modify_data=op1|op2;
                `EX_logic_XOR: modify_data=op1^op2;
                `EX_logic_XORI: modify_data=op1^op2;
            endcase
        end
        else if (alusel==`EX_shift)
        begin
            case (aluop)
                `EX_shift_SLL: modify_data=op1<<op2[4:0];
                `EX_shift_SLLI: modify_data=op1<<op2[4:0];
                `EX_shift_SRA: modify_data=({32{op1[31]}}<<(32-op2[4:0]))|(op1>>op2[4:0]);
                `EX_shift_SRAI: modify_data=({32{op1[31]}}<<(32-op2[4:0]))|(op1>>op2[4:0]);
                `EX_shift_SRL: modify_data=op1>>op2[4:0];
                `EX_shift_SRLI: modify_data=op1>>op2[4:0];
            endcase
        end
        else if (alusel==`EX_arith)
        begin
            case (aluop)
                `EX_arith_ADD: modify_data=op1+op2;
                `EX_arith_ADDI: modify_data=op1+op2;
                `EX_arith_AUIPC: modify_data=op1+op2;
                `EX_arith_LUI: modify_data=op1+op2;
                `EX_arith_SLT: modify_data=$signed(op1)<$signed(op2);
                `EX_arith_SLTI: modify_data=$signed(op1)<$signed(op2);
                `EX_arith_SLTIU: modify_data=op1<op2;
                `EX_arith_SLTU: modify_data=op1<op2;
                `EX_arith_SUB: modify_data=op1-op2;
            endcase
        end
        else if (alusel==`EX_branch)
        begin
            modify_data=pc+4;
            _br_address=br_address+br_offset;
//$display("EX %x %d %d %x",pc,alusel,aluop,_br_address);
            br_update=1;
            case (aluop)
                `EX_branch_BEQ: br=op1==op2;
                `EX_branch_BGE: br=$signed(op1)>=$signed(op2);
                `EX_branch_BGEU: br=op1>=op2;
                `EX_branch_BLT: br=$signed(op1)<$signed(op2);
                `EX_branch_BLTU: br=op1<op2;
                `EX_branch_BNE: br=op1!=op2;
                `EX_branch_JAL: br=1;
                `EX_branch_JALR:
                begin
                    br=1;
                    modify_data=pc+4;
                    _br_address=_br_address&~1;
                end
            endcase
            if (br==1)
            begin
                _br_nxt_address=_br_address;
            end
            else
            begin
                _br_nxt_address=pc+4;
            end
            if (br!=prediction)
            begin
                br_error=1;
            end
        end
        else if (alusel==`EX_load)
        begin
            load=1;
            sl_reg_address=op1+sl_offset;
            case (aluop)
                `EX_load_LB:
                begin
                    sl_data_length=1;
                    sl_data_signed=1;
                end
                `EX_load_LBU:
                begin
                    sl_data_length=1;
                    sl_data_signed=0;
                end
                `EX_load_LH:
                begin
                    sl_data_length=2;
                    sl_data_signed=1;
                end
                `EX_load_LHU:
                begin
                    sl_data_length=2;
                    sl_data_signed=0;
                end
                `EX_load_LW:
                begin
                    sl_data_length=4;
                    sl_data_signed=1;
                end
            endcase
        end
        else if (alusel==`EX_save)
        begin
            save=1;
            sl_reg_address=op1+sl_offset;
            sl_data=op2;
            case (aluop)
                `EX_save_SB: sl_data_length=1;
                `EX_save_SH: sl_data_length=2;
                `EX_save_SW: sl_data_length=4;
            endcase
        end
    end
end
endmodule
