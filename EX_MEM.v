`include "defines.v"
module EX_MEM
(
    input wire clk,
    input wire rst,

    input wire[`Stall_size] stall_state,
    //input wire from stall_bus
    input wire modify_flag,
    input wire[`Data_Address_size] modify_address,
    input wire[`Data_size] modify_data,
    input wire load,
    input wire save,
    input wire[`Data_Address_size] sl_reg_address,
    input wire[`Data_size] sl_data,
    input wire[2:0] sl_data_length,
    input wire sl_data_signed,
    //input wire from EX
    output reg _modify_flag,
    output reg[`Data_Address_size] _modify_address,
    output reg[`Data_size] _modify_data,
    output reg _load,
    output reg _save,
    output reg[`Data_Address_size] _sl_reg_address,
    output reg[`Data_size] _sl_data,
    output reg[2:0] _sl_data_length,
    output reg _sl_data_signed
    //output wire to MEM
);
always @ (posedge clk)
begin
    if (rst==1)
    begin
        _modify_flag<=0;
        _modify_address<=0;
        _modify_data<=0;
        _load<=0;
        _save<=0;
        _sl_reg_address<=0;
        _sl_data<=0;
        _sl_data_length<=0;
        _sl_data_signed<=0;
    end
    else if (stall_state[3]==0)
    begin
        _modify_flag<=modify_flag;
        _modify_address<=modify_address;
        _modify_data<=modify_data;
        _load<=load;
        _save<=save;
        _sl_reg_address<=sl_reg_address;
        _sl_data<=sl_data;
        _sl_data_length<=sl_data_length;
        _sl_data_signed<=sl_data_signed;
    end
end
endmodule
