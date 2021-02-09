`include "defines.v"
module pc_reg
(
    input wire clk,
    input wire rst,

    input wire[`Stall_size] stall_state,
    //wire from stallbus
    input wire[`Instruction_Address_size] pc,
    //wire from predictor
    input wire ex_flag, // if branch error
    input wire[`Instruction_Address_size] ex_target,
    //wire from EX
    output reg[`Instruction_Address_size] _pc
);
always @ (posedge clk)
begin
    if (rst==1)
    begin
        _pc<=0;
    end
    else if (ex_flag==0)
    begin
        if (stall_state[0]==0)
        begin
            _pc<=pc;
//$display("Pc_reg %d",_pc);
        end
    end
    else
    begin
        _pc<=ex_target;
    end
end
endmodule
