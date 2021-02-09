`include "defines.v"
module Mem_ctrl
(
    input wire clk,
    input wire rst,

    input wire instruction_read_flag,
    input wire[`Instruction_Address_size] instruction_read_address,
    //input wire from IF

    output reg instruction_flag,
    output reg[`Instruction_Address_size] _instruction_read_address,
    output reg[`Instruction_size] instruction,
    //output wire to IF

    input wire load,
    input wire save,
    input wire[`Data_Address_size] sl_reg_address,
    input wire[`Data_size] sl_data,
    input wire[2:0] sl_data_length,
    input wire sl_data_signed,
    //input wire from MEM

    output reg mem_ctrl_done,
    output reg[`Data_size] mem_ctrl_data,
    //output wire to MEM

    input wire[`RAM_size] mem_din,
    input wire io_buffer_full,
    //input wire from RAM

    output reg[`RAM_size] mem_dout,
    output reg[`Data_Address_size] mem_a,
    output reg mem_wr
    //output wire to RAM
);
reg running_state; // 1 running 0 waiting
reg[1:0] state;
// 01 save
// 10 load
// 11 instruction_fetch
reg[2:0] num;
reg[2:0] tmp_num;
reg[31:0] tmp_data;
reg[`Data_Address_size] tmp_address;
assign running=running_state;
always @ (posedge clk)
begin
    if (rst!=1)
    begin
//        $display("Mem_ctrl %d %d %d %d %d %d",running_state,state,num,tmp_num,instruction_read_flag,tmp_address);
    end
    if (rst==1)
    begin
        instruction_flag<=0;
        instruction<=0;
        mem_ctrl_done<=0;
        mem_ctrl_data<=0;
        running_state<=0;
        state<=0;
        num<=0;
        tmp_num<=0;
        tmp_data<=0;
    end
    else if (running_state==0)
    begin
        instruction_flag<=0;
        instruction<=0;
        mem_ctrl_done<=0;
        mem_ctrl_data<=0;
        if (save==1&&mem_ctrl_done==0)
        begin
            running_state<=1;
            state<=2'b01;
            num<=sl_data_length;
            tmp_address<=sl_reg_address;
            tmp_num<=1;
        end
        else if (load==1&&mem_ctrl_done==0)
        begin
            running_state<=1;
            state<=2'b10;
            num<=sl_data_length;
            tmp_address<=sl_reg_address;
            tmp_num<=1;
        end
        else if (instruction_read_flag==1)
        begin
            running_state<=1;
            state<=2'b11;
            num<=4;
            tmp_address<=instruction_read_address;
            tmp_num<=1;
        end
    end
    else if (state==2'b01)
    begin
        if (io_buffer_full==0)
        begin
            if (tmp_num<num)
            begin
                if (tmp_num==1)
                begin
                    tmp_num<=2;
                end
                else if (tmp_num==2)
                begin
                    tmp_num<=3;
                end
                else
                begin
                    tmp_num<=4;
                end
            end
            else
            begin
                running_state<=0;
                state<=0;
                mem_ctrl_done<=1;
            end
        end
    end
    else if (state==2'b10)
    begin
        if (tmp_num==2)
        begin
            tmp_data[7:0]<=mem_din;
        end
        else if (tmp_num==3)
        begin
            tmp_data[15:8]<=mem_din;
        end
        else if (tmp_num==4)
        begin
            tmp_data[23:16]<=mem_din;
        end
        else if (tmp_num==5)
        begin
            tmp_data[31:24]<=mem_din;
        end
        tmp_num<=tmp_num+1;
        if (tmp_num==num+2)
        begin
            running_state<=0;
            state<=0;
            mem_ctrl_done<=1;
            if (sl_data_signed==1)
            begin
                if (sl_data_length==1)
                begin
                    mem_ctrl_data<={24'b0,tmp_data[7:0]};
                end
                else if (sl_data_length==2)
                begin
                    mem_ctrl_data<={16'b0,tmp_data[15:0]};
                end
                else
                begin
                    mem_ctrl_data<=tmp_data[31:0];
                end
            end
            else
            begin
                if (sl_data_length==1)
                begin
                    mem_ctrl_data<={{24{tmp_data[7]}},tmp_data[7:0]};
                end
                else if (sl_data_length==2)
                begin
                    mem_ctrl_data<={{16{tmp_data[15]}},tmp_data[15:0]};
                end
                else
                begin
                    mem_ctrl_data<=tmp_data[31:0];
                end
            end
        end
    end
    else
    begin
        if (tmp_num==2)
        begin
            tmp_data[7:0]<=mem_din;
        end
        else if (tmp_num==3)
        begin
            tmp_data[15:8]<=mem_din;
        end
        else if (tmp_num==4)
        begin
            tmp_data[23:16]<=mem_din;
        end
        else if (tmp_num==5)
        begin
            tmp_data[31:24]<=mem_din;
        end
        tmp_num<=tmp_num+1;
        if (tmp_num==num+2)
        begin
            running_state<=0;
            state<=0;
            instruction_flag<=1;
            _instruction_read_address<=tmp_address;
            instruction<=tmp_data;
//$display("instruction from RAM   %d %d %d",instruction_read_address,instruction,tmp_data);
        end
    end
end

always @ (*)
begin
    if (state==2'b00)
    begin
        mem_dout=0;
        mem_a=0;
        mem_wr=0;
    end
    else if (state==2'b01)
    begin
        if (tmp_num==1)
        begin
            mem_dout=sl_data[7:0];
            mem_a=tmp_address;
            mem_wr=1;
        end
        else if (tmp_num==2)
        begin
            mem_dout=sl_data[15:8];
            mem_a=tmp_address+1;
            mem_wr=1;
        end
        else if (tmp_num==3)
        begin
            mem_dout=sl_data[23:16];
            mem_a=tmp_address+2;
            mem_wr=1;
        end
        else if (tmp_num==4)
        begin
            mem_dout=sl_data[31:24];
            mem_a=tmp_address+3;
            mem_wr=1;
        end
        else
        begin
            mem_dout=0;
            mem_a=0;
            mem_wr=0;
        end
    end
    else
    begin
        mem_dout=0;
        if (tmp_num==1)
        begin
            mem_a=tmp_address;
            mem_wr=0;
        end
        else if (tmp_num==2)
        begin
            mem_a=tmp_address+1;
            mem_wr=0;
        end
        else if (tmp_num==3)
        begin
            mem_a=tmp_address+2;
            mem_wr=0;
        end
        else if (tmp_num==4)
        begin
            mem_a=tmp_address+3;
            mem_wr=0;
        end
        else
        begin
            mem_dout=0;
            mem_a=0;
            mem_wr=0;
        end
    end
end

endmodule
