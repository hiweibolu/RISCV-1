`include "defines.v"
module IF_ID
(
    input wire clk,
    input wire rst,

    input wire[`Instruction_Address_size] pc,
    input wire[`Instruction_size] instruction,
    //input wire from IF
    input wire[`Stall_size] stall_state,
    //input wire from stall_bus
    input wire discard,
    //input wire from EX
    input wire prediction,
    //input wire from predictor
    output reg[`Instruction_Address_size] _pc,
    output reg[`Instruction_size] _instruction,
    output reg _prediction
    //output wire to ID
);
always @ (posedge clk)
begin
    if (rst==1||discard==1)
    begin
        _pc<=0;
        _instruction<=0;
        _prediction<=0;
    end
    else if (stall_state[1]==0)
    begin
        _pc<=pc;
        _instruction<=instruction;
        _prediction<=prediction;
//$display("IF_ID    %d %d %d %d",pc,_pc,instruction,prediction); 
    end
end
endmodule