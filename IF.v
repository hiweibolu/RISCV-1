`include "defines.v"
module IF
(
    input wire clk,
    input wire rst,

    input wire[`Instruction_Address_size] pc,
    //wire from pc_reg

    output reg[`Instruction_Address_size] _pc,
    output reg[`Instruction_size] _instruction,
    //wire to IF/ID

    output reg stall_flag,
    //wire to stall_bus

    input wire instruction_flag,
    input wire[`Instruction_Address_size] instruction_read_address,
    input wire[`Instruction_size] instruction,
    //wire from Mem_ctrl

    output reg _instruction_read_flag,
    output reg[`Instruction_Address_size] _instruction_read_address
    //wire to Mem_ctrl
);
reg[`Instruction_Address_size] cache_address[`Cache_size-1:0];
reg[`Instruction_size] cache_instruction[`Cache_size-1:0];
integer i;
initial begin
    for (i=0;i<`Cache_size;i=i+1)
    begin
        cache_address[i][31]=1;
        cache_instruction[i]=0;
    end
end
always @ (*)
begin
    if (rst==1)
    begin
        _pc=0;
        _instruction=0;
        stall_flag=0;
        _instruction_read_flag=0;
        _instruction_read_address=0;
        for (i=0;i<`Cache_size;i=i+1)
        begin
            cache_address[i][31]=1;
            cache_instruction[i]=0;
        end
    end
    else if (cache_address[pc[9:2]]==pc)
    begin
        _pc=pc;
        _instruction=cache_instruction[pc[9:2]];
//$display("IF %x %x",pc,cache_instruction[pc[9:2]]);
        stall_flag=0;
        _instruction_read_flag=0;
        _instruction_read_address=0;
    end
    else
    begin
        _pc=0;
        _instruction=0;
        stall_flag=1;
        _instruction_read_flag=1;
        _instruction_read_address=pc;
    end
end

always @ (posedge clk)
begin
    if (rst==0&&instruction_flag==1)
    begin
        cache_address[instruction_read_address[9:2]]<=instruction_read_address;
        cache_instruction[instruction_read_address[9:2]]<=instruction;
    end
end
endmodule
