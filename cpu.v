`include "defines.v"
// RISCV32I CPU top module
// port modification allowed for debugging purposes

module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

wire Rst=(rst_in==1)||(rdy_in==0);
wire[`Stall_size] Stall_state;
wire[`Instruction_Address_size] Pc_reg_pc;
wire IF_instruction_read_flag;
wire[`Instruction_Address_size] IF_instruction_read_address;
wire[`Instruction_Address_size] IF_pc;
wire[`Instruction_size] IF_instruction;
wire IF_stall_flag;
wire EX_br_error;
wire predictor_prediction;
wire[`Instruction_Address_size] IF_ID_pc;
wire[`Instruction_size] IF_ID_instruction;
wire IF_ID_prediction;
wire MEM_WB_modify_flag;
wire[`Data_Address_size] MEM_WB_modify_address;
wire[`Data_size] MEM_WB_modify_data;
wire ID_read1_flag;
wire[`Data_Address_size] ID_read1_address;
wire ID_read2_flag;
wire[`Data_Address_size] ID_read2_address;
wire[`Data_size] Regfile_read1_data;
wire[`Data_size] Regfile_read2_data;
wire EX_load;
wire EX_save;
wire[`Data_Address_size] EX_sl_reg_address;
wire[`Data_size] EX_sl_data;
wire Mem_write_flag;
wire ID_stall_flag;
wire[`Instruction_Address_size] ID_pc;
wire ID_prediction;
wire[`Alusel_size] ID_alusel;
wire[`Aluop_size] ID_aluop;
wire[`Data_size] ID_op1;
wire[`Data_size] ID_op2;
wire ID_write_flag;
wire[`Data_Address_size] ID_sl_address;
wire[`Data_Address_size] ID_sl_offset;
wire[`Instruction_Address_size] ID_br_address;
wire[`Instruction_Address_size] ID_br_offset;
wire[`Instruction_Address_size] ID_EX_pc;
wire ID_EX_prediction;
wire[`Alusel_size] ID_EX_alusel;
wire[`Aluop_size] ID_EX_aluop;
wire[`Data_size] ID_EX_op1;
wire[`Data_size] ID_EX_op2;
wire ID_EX_write_flag;
wire[`Data_Address_size] ID_EX_sl_address;
wire[`Data_Address_size] ID_EX_sl_offset;
wire[`Instruction_Address_size] ID_EX_br_address;
wire[`Instruction_Address_size] ID_EX_br_offset;
wire EX_modify_flag;
wire[`Data_Address_size] EX_modify_address;
wire[`Data_size] EX_modify_data;
wire EX_br_update;
wire EX_br;
wire[`Instruction_Address_size] EX_br_address;
wire[`Instruction_Address_size] EX_br_nxt_address;
wire[2:0] EX_sl_data_length;
wire EX_sl_data_signed;
wire EX_MEM_modify_flag;
wire[`Data_Address_size] EX_MEM_modify_address;
wire[`Data_size] EX_MEM_modify_data;
wire EX_MEM_load;
wire EX_MEM_save;
wire[`Data_Address_size] EX_MEM_sl_reg_address;
wire[`Data_size] EX_MEM_sl_data;
wire[2:0] EX_MEM_sl_data_length;
wire EX_MEM_sl_data_signed;
wire MEM_modify_flag;
wire[`Data_Address_size] MEM_modify_address;
wire[`Data_size] MEM_modify_data;
wire MEM_load;
wire MEM_save;
wire[`Data_Address_size] MEM_sl_reg_address;
wire[`Data_size] MEM_sl_data;
wire[2:0] MEM_sl_data_length;
wire MEM_sl_data_signed;
wire Memctrl_mem_ctrl_done;
wire[`Data_size] Memctrl_mem_ctrl_data;
wire MEM_stall_flag;
wire Memctrl_running;
wire Memctrl_instruction_flag;
wire[`Instruction_Address_size] Memctrl_instruction_read_address;
wire[`Instruction_size] Memctrl_instruction;
wire[`Instruction_Address_size] predictor_pc;
wire[`Instruction_Address_size] EX_br_pc;
wire ID_br_JALR;
wire ID_EX_br_JALR;
wire EX_br_JALR;

pc_reg _pc_reg
(
  .clk(clk_in),
  .rst(Rst), 

  .stall_state(Stall_state),

  .pc(predictor_pc),

  .ex_flag(EX_br_error),
  .ex_target(EX_br_nxt_address),

  ._pc(Pc_reg_pc)
);

IF _IF
(
  .clk(clk_in),
  .rst(Rst),

  .pc(Pc_reg_pc),

  ._pc(IF_pc),
  ._instruction(IF_instruction),

  .stall_flag(IF_stall_flag),

  .instruction_flag(Memctrl_instruction_flag),
  .instruction_read_address(Memctrl_instruction_read_address),
  .instruction(Memctrl_instruction),
  
  ._instruction_read_flag(IF_instruction_read_flag),
  ._instruction_read_address(IF_instruction_read_address)
);

IF_ID _IF_ID
(
  .clk(clk_in),
  .rst(Rst),

  .pc(IF_pc),
  .instruction(IF_instruction),

  .stall_state(Stall_state),

  .discard(EX_br_error),

  .prediction(predictor_prediction),

  ._pc(IF_ID_pc),
  ._instruction(IF_ID_instruction),
  ._prediction(IF_ID_prediction)
);

regfile _regfile
(
  .clk(clk_in),
  .rst(Rst),

  .wb_flag(MEM_WB_modify_flag),
  .wb_address(MEM_WB_modify_address),
  .wb_data(MEM_WB_modify_data),

  .read1_flag(ID_read1_flag),
  .read1_address(ID_read1_address),
  .read2_flag(ID_read2_flag),
  .read2_address(ID_read2_address),

  .read1_data(Regfile_read1_data),
  .read2_data(Regfile_read2_data)
);

ID _ID
(
  .rst(Rst),

  .pc(IF_ID_pc),
  .instruction(IF_ID_instruction),
  .prediction(IF_ID_prediction),

  .read1_flag(ID_read1_flag),
  .read1_address(ID_read1_address),
  .read2_flag(ID_read2_flag),
  .read2_address(ID_read2_address),

  .read1_data(Regfile_read1_data),
  .read2_data(Regfile_read2_data),

  .ex_load_flag(EX_load),
  .ex_write_flag(EX_modify_flag),
  .ex_modify_address(EX_modify_address),
  .ex_modify_data(EX_modify_data),

  .mem_write_flag(MEM_modify_flag),
  .mem_modify_address(MEM_modify_address),
  .mem_modify_data(MEM_modify_data),

  .stall_flag(ID_stall_flag),

  ._pc(ID_pc),
  ._prediction(ID_prediction),
  .alusel(ID_alusel),
  .aluop(ID_aluop),
  .op1(ID_op1),
  .op2(ID_op2),
  .write_flag(ID_write_flag),
  .sl_address(ID_sl_address),
  .sl_offset(ID_sl_offset),
  .br_address(ID_br_address),
  .br_offset(ID_br_offset),
  .br_JALR(ID_br_JALR)
);

ID_EX _ID_EX
(
  .clk(clk_in),
  .rst(Rst),

  .pc(ID_pc),
  .alusel(ID_alusel),
  .aluop(ID_aluop),
  .op1(ID_op1),
  .op2(ID_op2),
  .write_flag(ID_write_flag),
  .sl_address(ID_sl_address),
  .sl_offset(ID_sl_offset),
  .br_address(ID_br_address),
  .br_offset(ID_br_offset),
  .br_JALR(ID_br_JALR),
  .prediction(ID_prediction),

  .stall_state(Stall_state),

  .discard(EX_br_error),

  ._pc(ID_EX_pc),
  ._alusel(ID_EX_alusel),
  ._aluop(ID_EX_aluop),
  ._op1(ID_EX_op1),
  ._op2(ID_EX_op2),
  ._write_flag(ID_EX_write_flag),
  ._sl_address(ID_EX_sl_address),
  ._sl_offset(ID_EX_sl_offset),
  ._br_address(ID_EX_br_address),
  ._br_offset(ID_EX_br_offset),
  ._br_JALR(ID_EX_br_JALR),
  ._prediction(ID_EX_prediction)
);

EX _EX
(
  .rst(Rst),

  .pc(ID_EX_pc),
  .alusel(ID_EX_alusel),
  .aluop(ID_EX_aluop),
  .op1(ID_EX_op1),
  .op2(ID_EX_op2),
  .write_flag(ID_EX_write_flag),
  .sl_address(ID_EX_sl_address),
  .sl_offset(ID_EX_sl_offset),
  .br_address(ID_EX_br_address),
  .br_offset(ID_EX_br_offset),
  .br_JALR(ID_EX_br_JALR),
  .prediction(ID_EX_prediction),

  .modify_flag(EX_modify_flag),
  .modify_address(EX_modify_address),
  .modify_data(EX_modify_data),

  .br_update(EX_br_update),
  ._br_JALR(EX_br_JALR),
  .br(EX_br),

  ._br_address(EX_br_address),
  ._br_pc(EX_br_pc),

  ._br_nxt_address(EX_br_nxt_address),

  .br_error(EX_br_error),

  .load(EX_load),
  .save(EX_save),
  .sl_reg_address(EX_sl_reg_address),
  .sl_data(EX_sl_data),
  .sl_data_length(EX_sl_data_length),
  .sl_data_signed(EX_sl_data_signed)
);

EX_MEM _EX_MEM
(
  .clk(clk_in),
  .rst(Rst),

  .stall_state(Stall_state),

  .modify_flag(EX_modify_flag),
  .modify_address(EX_modify_address),
  .modify_data(EX_modify_data),
  .load(EX_load),
  .save(EX_save),
  .sl_reg_address(EX_sl_reg_address),
  .sl_data(EX_sl_data),
  .sl_data_length(EX_sl_data_length),
  .sl_data_signed(EX_sl_data_signed),

  ._modify_flag(EX_MEM_modify_flag),
  ._modify_address(EX_MEM_modify_address),
  ._modify_data(EX_MEM_modify_data),
  ._load(EX_MEM_load),
  ._save(EX_MEM_save),
  ._sl_reg_address(EX_MEM_sl_reg_address),
  ._sl_data(EX_MEM_sl_data),
  ._sl_data_length(EX_MEM_sl_data_length),
  ._sl_data_signed(EX_MEM_sl_data_signed)
);

MEM _MEM
(
  .rst(Rst),

  .modify_flag(EX_MEM_modify_flag),
  .modify_address(EX_MEM_modify_address),
  .modify_data(EX_MEM_modify_data),
  .load(EX_MEM_load),
  .save(EX_MEM_save),
  .sl_reg_address(EX_MEM_sl_reg_address),
  .sl_data(EX_MEM_sl_data),
  .sl_data_length(EX_MEM_sl_data_length),
  .sl_data_signed(EX_MEM_sl_data_signed),

  ._modify_flag(MEM_modify_flag),
  ._modify_address(MEM_modify_address),
  ._modify_data(MEM_modify_data),

  ._load(MEM_load),
  ._save(MEM_save),
  ._sl_reg_address(MEM_sl_reg_address),
  ._sl_data(MEM_sl_data),
  ._sl_data_length(MEM_sl_data_length),
  ._sl_data_signed(MEM_sl_data_signed),

  .mem_ctrl_done(Memctrl_mem_ctrl_done),
  .mem_ctrl_data(Memctrl_mem_ctrl_data),

  .stall_flag(MEM_stall_flag)
);

Mem_ctrl _Mem_ctrl
(
  .clk(clk_in),
  .rst(Rst),

  .instruction_read_flag(IF_instruction_read_flag),
  .instruction_read_address(IF_instruction_read_address),

  .instruction_flag(Memctrl_instruction_flag),
  ._instruction_read_address(Memctrl_instruction_read_address),
  .instruction(Memctrl_instruction),

  .load(MEM_load),
  .save(MEM_save),
  .sl_reg_address(MEM_sl_reg_address),
  .sl_data(MEM_sl_data),
  .sl_data_length(MEM_sl_data_length),
  .sl_data_signed(MEM_sl_data_signed),

  .mem_ctrl_done(Memctrl_mem_ctrl_done),
  .mem_ctrl_data(Memctrl_mem_ctrl_data),

  .mem_din(mem_din),
  .io_buffer_full(io_buffer_full),

  .mem_dout(mem_dout),
  .mem_a(mem_a),
  .mem_wr(mem_wr)
);

MEM_WB _MEM_WB
(
  .clk(clk_in),
  .rst(Rst),

  .stall_state(Stall_state),

  .modify_flag(MEM_modify_flag),
  .modify_address(MEM_modify_address),
  .modify_data(MEM_modify_data),

  ._modify_flag(MEM_WB_modify_flag),
  ._modify_address(MEM_WB_modify_address),
  ._modify_data(MEM_WB_modify_data)
);

stall_bus _stall_bus
(
  .rst(Rst),

  .stall_if(IF_stall_flag),
  .stall_id(ID_stall_flag),
  .stall_mem(MEM_stall_flag),
  .stall_state(Stall_state)
);

predictor _predictor
(
  .clk(clk_in),
  .rst(Rst),

  .pc(IF_pc),

  ._pc(predictor_pc),

  .prediction(predictor_prediction),

  .br_update(EX_br_update),
  .br(EX_br),
  .br_JALR(EX_br_JALR),
  .br_address(EX_br_address),
  .br_pc(EX_br_pc)
);

endmodule