`include "defines.v"
module predictor
(
    input wire clk,
    input wire rst,

    input wire[`Instruction_Address_size] pc,
    //wire from IF/ID
    output reg[`Instruction_Address_size] _pc,
    //wire to pc_reg
    output reg prediction,
    //wire to IF/ID
    input wire br_update, // if instruction is branch
    input wire br, // if branch
    input wire[`Instruction_Address_size] br_address, // address if branch
    input wire[`Instruction_Address_size] br_pc // pc of the branch instruction
    //wire from EX
);
reg[`Instruction_Address_size] address[`Predictor_size-1:0];
reg[`Instruction_size] instruction[`Predictor_size-1:0];
reg jump[`Predictor_size-1:0];
integer i;
initial begin
    for (i=0;i<`Predictor_size;i=i+1)
    begin
        address[i][31]=1;
        instruction[i]=0;
    end
end
always @ (posedge clk)
begin
    if (rst==1)
    begin
        for (i=0;i<`Predictor_size;i=i+1)
        begin
            address[i]<=0;
            instruction[i]<=0;
            jump[i]<=0;
        end
    end 
    else if (br_update==1)
    begin
        address[br_pc[9:2]]<=br_pc;
        instruction[br_pc[9:2]]<=br_address;
        jump[br_pc[9:2]]<=br;
    end
end

always @ (*)
begin
    if (rst==1)
    begin
        _pc=0;
        prediction=0;
    end
    else if (address[pc[9:2]]==pc)
    begin
        if (jump[pc[9:2]])
        begin
            _pc=instruction[pc[9:2]];
            prediction=1;
        end
        else
        begin
            _pc=pc+4;
            prediction=0;
        end
    end
    else
    begin
        _pc=pc+4;
        prediction=0;
    end
end

endmodule