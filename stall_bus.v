`include "defines.v"
module stall_bus
(
    input rst,

    input wire stall_if,
    input wire stall_id,
    input wire stall_mem,
    output reg[`Stall_size] stall_state
);

always @ (*)
begin
    if (rst==1)
    begin
        stall_state=5'b00000;
    end
    else if (stall_mem==1)
    begin
        stall_state=5'b01111;
    end
    else if (stall_id==1)
    begin
        stall_state=5'b00111;
    end
    else if (stall_if==1)
    begin
        stall_state=5'b00011;
    end
    else
    begin
        stall_state=5'b00000;
    end
end
endmodule
