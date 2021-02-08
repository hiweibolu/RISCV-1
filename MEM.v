`include "defines.v"
module MEM
(
    input wire rst,

    input wire modify_flag,
    input wire[`Data_Address_size] modify_address,
    input wire[`Data_size] modify_data,

    input wire load,
    input wire save,
    input wire[`Data_Address_size] sl_reg_address,
    input wire[`Data_size] sl_data,
    input wire[2:0] sl_data_length,
    input wire sl_data_signed,
    //input wire from EX_MEM

    output reg _modify_flag,
    output reg[`Data_Address_size] _modify_address,
    output reg[`Data_size] _modify_data,
    //output wire to MEM_WB

    output reg _load,
    output reg _save,
    output reg[`Data_Address_size] _sl_reg_address,
    output reg[`Data_size] _sl_data,
    output reg[2:0] _sl_data_length,
    output reg _sl_data_signed,
    //output wire to Mem_ctrl
    input wire mem_ctrl_done,
    input wire[`Data_size] mem_ctrl_data,
    //input wire from Mem_ctrl

    output wire stall_flag
    //output wire to stall_bus
);

assign stall_flag=(load==1||save==1)&&(mem_ctrl_done==0);

always @ (*)
begin
    _modify_flag=modify_flag;
    _modify_address=modify_address;
    _load=0;
    _save=0;
    _sl_reg_address=0;
    _sl_data=0;
    _sl_data_length=0;
    _sl_data_signed=0;
    if (rst==0)
    begin
        if (load==1)
        begin
            _load=1;
            _sl_reg_address=sl_reg_address;
            _sl_data_length=sl_data_length;
            _sl_data_signed=sl_data_signed;
        end
        else if (save==1)
        begin
            _save=1;
            _sl_reg_address=sl_reg_address;
            _sl_data=sl_data;
            _sl_data_length=sl_data_length;
        end
    end
end
always @ (*)
begin
    if (rst==0)
    begin
        _modify_data=0;
    end
    else if (load==0)
    begin
        _modify_data=modify_data;
    end
    else if (mem_ctrl_done==1)
    begin
        _modify_data=mem_ctrl_data;
    end
end
endmodule