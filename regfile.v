`include "defines.v"
module regfile
(
    input wire clk,
    input wire rst,

    input wire wb_flag,
    input wire[`Data_Address_size] wb_address,
    input wire[`Data_size] wb_data,
    //wire from MEM_WB
    input wire read1_flag,
    input wire[`Data_Address_size] read1_address,
    input wire read2_flag,
    input wire[`Data_Address_size] read2_address,
    //wire from ID
    output reg[`Data_size] read1_data,
    output reg[`Data_size] read2_data
    //wire to ID
);
reg[`Data_size] regs[31:0];
integer i;
always @ (posedge clk)
begin
    if (rst==1)
    begin
        for (i=0;i<32;i=i+1) regs[i]<=0;
    end
    else if (wb_flag==1 && wb_address!=0)
    begin
        regs[wb_address]<=wb_data;
    end
end
always @ (*)
begin
    if (rst==1||read1_flag==0)
    begin
        read1_data=0;
    end
    else if (read1_address==wb_address && wb_flag==1)
    begin
        read1_data=wb_data;
    end
    else
    begin
        read1_data=regs[read1_address];
    end
end
always @ (*)
begin
    if (rst==1||read2_flag==0)
    begin
        read2_data=0;
    end
    else if (read2_address==wb_address && wb_flag==1)
    begin
        read2_data=wb_data;
    end
    else
    begin
        read2_data=regs[read2_address];
    end
end
endmodule