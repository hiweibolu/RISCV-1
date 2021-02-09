`include "defines.v"
module ID
(
    input wire rst,

    input wire[`Instruction_Address_size] pc,
    input wire[`Instruction_size] instruction,
    input wire prediction,
    //wire from IF_ID
    output reg read1_flag,
    output reg[`Data_Address_size] read1_address,
    output reg read2_flag,
    output reg[`Data_Address_size] read2_address,
    //wire to regfile
    input wire[`Data_size] read1_data,
    input wire[`Data_size] read2_data,
    //wire from regfile
    input wire ex_load_flag,
    input wire ex_write_flag,
    input wire[`Data_Address_size] ex_modify_address,
    input wire[`Data_size] ex_modify_data,
    //wire from EX
    input wire mem_write_flag,
    input wire[`Data_Address_size] mem_modify_address,
    input wire[`Data_size] mem_modify_data,
    //wire from MEM
    output wire stall_flag,
    //wire to stall_bus
    output wire[`Instruction_Address_size] _pc,
    output wire _prediction,
    output reg[`Alusel_size] alusel,
    output reg[`Aluop_size] aluop,
    output reg[`Data_size] op1,
    output reg[`Data_size] op2,
    output reg write_flag,
    output reg[`Data_Address_size] sl_address, //for save & load
    output reg[`Data_Address_size] sl_offset, //for save & load
    output reg[`Instruction_Address_size] br_address, //for branch
    output reg[`Instruction_Address_size] br_offset //for branch
    //wire to ID_EX
);
wire[6:0] opcode=instruction[6:0];
wire[4:0] rd=instruction[11:7];
wire[2:0] funct3=instruction[14:12];
wire[6:0] funct7=instruction[31:25];
wire[4:0] rs1=instruction[19:15];
wire[4:0] rs2=instruction[24:20];
wire[31:0] I_imm={{20{instruction[31]}},instruction[31:20]};
wire[31:0] S_imm={{20{instruction[31]}},instruction[31:25],instruction[11:7]};
wire[31:0] B_imm={{20{instruction[31]}},instruction[7],instruction[30:25],instruction[11:8],1'b0};
wire[31:0] U_imm={instruction[31:12],12'b0};
wire[31:0] J_imm={{12{instruction[31]}},instruction[19:12],instruction[20],instruction[30:21],1'b0};

reg[`Data_size] data1;
reg[`Data_size] data2;
reg stall_flag1;
reg stall_flag2;

assign _pc=pc;
assign _prediction=prediction;

always @ (*)
begin
    read1_flag=0;
    read1_address=0;
    read2_flag=0;
    read2_address=0;
    alusel=0;
    aluop=0;
    op1=0;
    op2=0;
    write_flag=0;
    sl_address=0;
    sl_offset=0;
    br_address=0;
    br_offset=0;
    if (rst==0)
    begin
        case (opcode)
            7'b0110111:
            begin
                alusel=`EX_arith;
                aluop=`EX_arith_LUI;
                data1=U_imm;
                data2=0;
                write_flag=1;
                sl_address=rd;
            end // LUI
            7'b0010111:
            begin
                alusel=`EX_arith;
                aluop=`EX_arith_AUIPC;
                data1=U_imm;
                data2=pc;
                write_flag=1;
                sl_address=rd;
            end // AUIPC
            7'b1101111:
            begin
                alusel=`EX_branch;
                aluop=`EX_branch_JAL;
                write_flag=1;
                sl_address=rd;
                br_address=pc;
                br_offset=J_imm;
            end // JAL
            7'b1100111:
            begin
                alusel=`EX_branch;
                aluop=`EX_branch_JALR;
                read1_flag=1;
                read1_address=rs1;
                write_flag=1;
                sl_address=rd;
                br_address=op1;
                br_offset=I_imm;
            end // JALR
            7'b1100011:
            begin
                alusel=`EX_branch;
                read1_flag=1;
                read1_address=rs1;
                read2_flag=1;
                read2_address=rs2;
                br_address=pc;
                br_offset=B_imm;
                case (funct3)
                    3'b000:
                    begin
                        aluop=`EX_branch_BEQ;
                    end // BEQ
                    3'b001:
                    begin
                        aluop=`EX_branch_BNE;
                    end // BNE
                    3'b100:
                    begin
                        aluop=`EX_branch_BLT;
                    end // BLT
                    3'b101:
                    begin
                        aluop=`EX_branch_BGE;
                    end // BGE
                    3'b110:
                    begin
                        aluop=`EX_branch_BLTU;
                    end // BLTU
                    3'b111:
                    begin
                        aluop=`EX_branch_BGEU;
                    end // BGEU
                endcase
            end
            7'b0000011:
            begin
                alusel=`EX_load;
                read1_flag=1;
                read1_address=rs1;
                write_flag=1;
                sl_address=rd;
                sl_offset=I_imm;
                case (funct3)
                    3'b000:
                    begin
                        aluop=`EX_load_LB;
                    end // LB
                    3'b001:
                    begin
                        aluop=`EX_load_LH;
                    end // LH
                    3'b010:
                    begin
                        aluop=`EX_load_LW;
                    end // LW
                    3'b100:
                    begin
                        aluop=`EX_load_LBU;
                    end // LBU
                    3'b101:
                    begin
                        aluop=`EX_load_LHU;
                    end // LHU
                endcase
            end
            7'b0100011:
            begin
                alusel=`EX_save;
                read1_flag=1;
                read1_address=rs1;
                read2_flag=1;
                read2_address=rs2;
                sl_offset=S_imm;
                case (funct3)
                    3'b000:
                    begin
                        aluop=`EX_save_SB;
                    end // SB
                    3'b001:
                    begin
                        aluop=`EX_save_SH;
                    end // SH
                    3'b010:
                    begin
                        aluop=`EX_save_SW;
                    end // SW
                endcase
            end
            7'b0010011:
            begin
                read1_flag=1;
                read1_address=rs1;
                write_flag=1;
                sl_address=rd;
                data2=I_imm;
                case (funct3)
                    3'b000:
                    begin
                        alusel=`EX_arith;
                        aluop=`EX_arith_ADDI;
                    end // ADDI
                    3'b010:
                    begin
                        alusel=`EX_arith;
                        aluop=`EX_arith_SLTI;
                    end // SLTI
                    3'b011:
                    begin
                        alusel=`EX_arith;
                        aluop=`EX_arith_SLTIU;
                    end // SLTIU
                    3'b100:
                    begin
                        alusel=`EX_logic;
                        aluop=`EX_logic_XORI;
                    end // XORI
                    3'b110:
                    begin
                        alusel=`EX_logic;
                        aluop=`EX_logic_ORI;
                    end // ORI
                    3'b111:
                    begin
                        alusel=`EX_logic;
                        aluop=`EX_logic_ANDI;
                    end // ANDI
                    3'b001:
                    begin
                        alusel=`EX_shift;
                        aluop=`EX_shift_SLLI;
                    end // SLLI
                    3'b101:
                    begin
                        case (funct7)
                            7'b0000000:
                            begin
                                alusel=`EX_shift;
                                aluop=`EX_shift_SRLI;
                            end // SRLI
                            7'b0100000:
                            begin
                                alusel=`EX_shift;
                                aluop=`EX_shift_SRAI;
                            end // SRAI
                        endcase
                    end
                endcase
            end
            7'b0110011:
            begin
                read1_flag=1;
                read1_address=rs1;
                read2_flag=1;
                read2_address=rs2;
                write_flag=1;
                sl_address=rd;
                case (funct3)
                    3'b000:
                    begin
                        alusel=`EX_arith;
                        case (funct7)
                            7'b0000000:
                            begin
                                aluop=`EX_arith_ADD;
                            end // ADD
                            7'b0100000:
                            begin
                                aluop=`EX_arith_SUB;
                            end // SUB
                        endcase
                    end
                    3'b001:
                    begin
                        alusel=`EX_shift;
                        aluop=`EX_shift_SLL;
                    end // SLL
                    3'b010:
                    begin
                        alusel=`EX_arith;
                        aluop=`EX_arith_SLT;
                    end // SLT
                    3'b011:
                    begin
                        alusel=`EX_arith;
                        aluop=`EX_arith_SLTU;
                    end // SLTU
                    3'b100:
                    begin
                        alusel=`EX_logic;
                        aluop=`EX_logic_XOR;
                    end // XOR
                    3'b101:
                    begin
                        alusel=`EX_shift;
                        case (funct7)
                            7'b0000000:
                            begin
                                aluop=`EX_shift_SRL;
                            end // SRL
                            7'b0100000:
                            begin
                                aluop=`EX_shift_SRA;
                            end // SRA
                        endcase
                    end
                    3'b110:
                    begin
                        alusel=`EX_logic;
                        aluop=`EX_logic_OR;
                    end // OR
                    3'b111:
                    begin
                        alusel=`EX_logic;
                        aluop=`EX_logic_AND;
                    end // AND
                endcase
            end
        endcase 
    end 
//$display("ID    %x %x %d %d",_pc,instruction,alusel,aluop); 
end

always @ (*)
begin
    stall_flag1=0;
    if (rst==1)
    begin
        op1=0;
    end
    else if (read1_flag==0)
    begin
        op1=data1;
    end
    else if (read1_address==0)
    begin
        op1=0;
    end
    else if (ex_load_flag==1&&read1_address==ex_modify_address)
    begin
        stall_flag1=1;
        op1=0;
    end
    else if (ex_write_flag==1&&read1_address==ex_modify_address)
    begin
        op1=ex_modify_data;
    end
    else if (mem_write_flag==1&&read1_address==mem_modify_address)
    begin
        op1=mem_modify_data;
    end
    else
    begin
        op1=read1_data;
    end
end

always @ (*)
begin
    stall_flag2=0;
    if (rst==1)
    begin
        op2=0;
    end
    else if (read2_flag==0)
    begin
        op2=data2;
    end
    else if (read2_address==0)
    begin
        op2=0;
    end
    else if (ex_load_flag==1&&read2_address==ex_modify_address)
    begin
        stall_flag2=1;
        op2=0;
    end
    else if (ex_write_flag==1&&read2_address==ex_modify_address)
    begin
        op2=ex_modify_data;
    end
    else if (mem_write_flag==1&&read2_address==mem_modify_address)
    begin
        op2=mem_modify_data;
    end
    else
    begin
        op2=read2_data;
    end
end

assign stall_flag=stall_flag1||stall_flag2;
endmodule