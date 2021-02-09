`include "defines.v"
module i_cache
(
    input wire clk,
    input wire rst,

    input wire instruction_read_flag,
    input wire[`Instruction_Address_size] instruction_read_address,
    //wire from IF
    output reg _instruction_flag,
    output reg[`Instruction_size] _instruction,
    //wire to IF

    input wire running,
    input wire instruction_flag,
    input wire[`Instruction_size] instruction,
    //wire from Mem_ctrl
    output reg _instruction_read_flag,
    output reg[`Instruction_Address_size] _instruction_read_address
    //wire to Mem_ctrl
);
reg[`Instruction_Address_size] cache_address[`Cache_size-1:0];
reg[`Instruction_size] cache_instruction[`Cache_size-1:0];
integer i;
always @ (*)
begin
    if (rst==1)
    begin
        _instruction_read_flag=0;
        _instruction_read_address=0;
        for (i=0;i<`Cache_size;i=i+1)
        begin
            cache_address[i]=0;
            cache_instruction[i]=0;
        end
    end
    else if (instruction_read_flag==0)
    begin
        _instruction_read_flag=0;
        _instruction_read_address=0;
    end
//    else if (cache_address[instruction_read_address[9:2]]==instruction_read_address)
//    begin
//        _instruction_read_flag<=0;
//        _instruction_read_address<=0;
//    end
    else if (instruction_flag==0)
    begin
$display("Icache in %d",_instruction_read_address); 
        _instruction_read_flag=1;
        _instruction_read_address=instruction_read_address;
    end
end
always @ (*)
begin
    if (rst==1||instruction_read_flag==0)
    begin
        _instruction_flag=0;
        _instruction=0;
    end
//    else if (cache_address[instruction_read_address[9:2]]==instruction_read_address)
//    begin
//        _instruction_flag<=1;
//        _instruction<=cache_instruction[instruction_read_address[9:2]];
//    end
    else if (instruction_flag==1)
    begin
        _instruction_flag=1;
        _instruction=instruction;
//$display("Icache out %d  %d",instruction_read_address,_instruction); 
//        cache_address[instruction_read_address[9:2]]<=instruction_read_address;
//        cache_instruction[instruction_read_address[9:2]]<=instruction;
    end
end
endmodule