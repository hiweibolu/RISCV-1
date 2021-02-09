`include "defines.v"
module MEM_WB
(
    input clk,
    input rst,

    input wire[`Stall_size] stall_state,
    //input wire from stall_bus

    input wire modify_flag,
    input wire[`Data_Address_size] modify_address,
    input wire[`Data_size] modify_data,
    //input wire from MEM

    output reg _modify_flag,
    output reg[`Data_Address_size] _modify_address,
    output reg[`Data_size] _modify_data
    //output wire to reg_file
);

always @ (posedge clk)
begin
    if (rst)
    begin
        _modify_flag<=0;
        _modify_address<=0;
        _modify_data<=0;
    end
    else if (stall_state[4]==0)
    begin
        _modify_flag<=modify_flag;
        _modify_address<=modify_address;
        _modify_data<=modify_data;
$display("WB %d %x %x",modify_flag,modify_address,modify_data);
    end
end
endmodule
