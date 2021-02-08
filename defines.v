`ifndef define_v
`define define_v

`define Stall_size 4:0
`define Instruction_Address_size 31:0
`define Instruction_size 31:0
`define Data_Address_size 31:0
`define Data_size 31:0
`define RAM_size 7:0
`define Cache_size 256
`define Predictor_size 256

`define Alusel_size 2:0

`define EX_logic 3'b001
`define EX_shift 3'b010
`define EX_arith 3'b011
`define EX_branch 3'b100
`define EX_load 3'b101
`define EX_save 3'b110

`define Aluop_size 3:0

`define EX_logic_AND 4'b0001
`define EX_logic_ANDI 4'b0010
`define EX_logic_OR 4'b0011
`define EX_logic_ORI 4'b0100
`define EX_logic_XOR 4'b0101
`define EX_logic_XORI 4'b0110

`define EX_shift_SLL 4'b0001
`define EX_shift_SLLI 4'b0010
`define EX_shift_SRA 4'b0011
`define EX_shift_SRAI 4'b0100
`define EX_shift_SRL 4'b0101
`define EX_shift_SRLI 4'b0110

`define EX_arith_ADD 4'b0001
`define EX_arith_ADDI 4'b0010
`define EX_arith_AUIPC 4'b0011
`define EX_arith_LUI 4'b0100
`define EX_arith_SLT 4'b0101
`define EX_arith_SLTI 4'b0110
`define EX_arith_SLTIU 4'b0111
`define EX_arith_SLTU 4'b1000
`define EX_arith_SUB 4'b1001

`define EX_branch_BEQ 4'b0001
`define EX_branch_BGE 4'b0010
`define EX_branch_BGEU 4'b0011
`define EX_branch_BLT 4'b0100
`define EX_branch_BLTU 4'b0101
`define EX_branch_BNE 4'b0110
`define EX_branch_JAL 4'b0111
`define EX_branch_JALR 4'b1000

`define EX_load_LB 4'b0001
`define EX_load_LBU 4'b0010
`define EX_load_LH 4'b0011
`define EX_load_LHU 4'b0100
`define EX_load_LW 4'b0101

`define EX_save_SB 4'b0001
`define EX_save_SH 4'b0010
`define EX_save_SW 4'b0011

`endif