`include "defines.v"
module ID_EX
(
    input wire clk,
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
    input wire prediction,
    //wire from ID
    input wire[`Stall_size] stall_state,
    //input wire from stall_bus
    input wire discard,
    //input wire from EX
    output reg[`Instruction_Address_size] _pc,
    output reg[`Alusel_size] _alusel,
    output reg[`Aluop_size] _aluop,
    output reg[`Data_size] _op1,
    output reg[`Data_size] _op2,
    output reg _write_flag,
    output reg[`Data_Address_size] _sl_address, //for save & load
    output reg[`Data_Address_size] _sl_offset, //for save & load
    output reg[`Instruction_Address_size] _br_address, //for branch
    output reg[`Instruction_Address_size] _br_offset, //for branch
    output reg _prediction
    //wire to ID_EX
);
always @ (posedge clk)
begin
    if (rst==1||discard==1)
    begin
        _pc<=0;
        _alusel<=0;
        _aluop<=0;
        _op1<=0;
        _op2<=0;
        _write_flag<=0;
        _sl_address<=0;
        _sl_offset<=0;
        _br_address<=0;
        _br_offset<=0;
        _prediction<=0;
    end
    else if (stall_state[2]==0)
    begin
        _pc<=pc;
        _alusel<=alusel;
        _aluop<=aluop;
        _op1<=op1;
        _op2<=op2;
        _write_flag<=write_flag;
        _sl_address<=sl_address;
        _sl_offset<=sl_offset;
        _br_address<=br_address;
        _br_offset<=br_offset;
        _prediction<=prediction;
    end
end
endmodule