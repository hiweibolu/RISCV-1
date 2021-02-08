`include "defines.v"
module IF
(
    input wire rst,

    input wire[`Instruction_Address_size] pc,
    //wire from pc_reg
    input wire instruction_flag,
    input wire[`Instruction_size] instruction,
    //wire from icache
    output reg instruction_read_flag,
    output reg[`Instruction_Address_size] instruction_read,
    //wire to icache
    output reg[`Instruction_Address_size] _pc,
    output reg[`Instruction_size] _instruction,
    //wire to IF/ID
    output wire stall_flag
    //wire to stall_bus
);
assign stall_flag=!instruction_flag;
always @ (*)
begin
    if (rst==1)
    begin
        _pc=0;
        instruction_read_flag=0;
        instruction_read=0;
    end
    else
    begin
        _pc=pc;
        instruction_read_flag=1;
        instruction_read=pc;
    end
end

always @ (*)
begin
    if (rst==1)
    begin
        _instruction=0;
    end
    else if (instruction_flag==1)
    begin
        _instruction=instruction;
    end
    else
    begin
        _instruction=0;
    end
end
endmodule