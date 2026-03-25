//------------------------------------------------------------------------------
//  project:       RISC-V (SberLab Novosibirsk State University)
//
//  modules:        
//
//  description:   
//------------------------------------------------------------------------------

`ifndef RISC_V_SVH
`define RISC_V_SVH

`timescale 1ns / 1ps

// synopsys translate_off
`ifndef SIMULATOR
    `define SIMULATOR
`endif
// synopsys translate_on

//==============================================================================
//    IMPLEMENTATION SPECIFIC COMPILE TIME DIRECTIVES - ONE SHOULD BE CAREFUL!
//==============================================================================

`define CFG_NAME_BASYS_3
`ifdef CFG_NAME_BASYS_3
    `define LED_NUM 16
`endif

//==============================================================================
//    DEBUG COMPILE TIME DIRECTIVES - ONE SHOULD BE CAREFUL!
//==============================================================================

//------------------------------------------------------------------------------
//    RISC_V_KEEP_HIEARARCHY
//
//    when defined  "yes" - (* keep_hierarchy = "yes" *)
//    wnen defined  "no"  - (* keep_hierarchy = "no" *)
//    default - "no"
//------------------------------------------------------------------------------
`define PRJ_KEEP_HIEARARCHY "yes"

//******************************************************************************
//******************************************************************************
package risc_v_pkg;

//=== common section

//--------------------------------------------------------------------------
localparam int XLEN = 32;                            // RISC-V ISA dependent

localparam int IMEM_ADDR_WIDTH = 8;                  // (byte addressed) CPU system implementation dependent
localparam int DMEM_ADDR_WIDTH = 8;                  // (byte addressed) CPU system implementation dependent

localparam int INSTR_LEN       = 32;                 // fixed for all RISC-V ISA except RVC
localparam int RF_ADDR_WIDTH   = 5;                  // RISC-V ISA dependent (?)
// (reserved) localparam int BYTE_ADDR_WIDTH = $clog2(XLEN/8);     // number of lower address bits - for select byte in word
// (reserved) localparam int DATA_BYTE_NUM   = 2**BYTE_ADDR_WIDTH; // number of bytes in data word with length = XLEN

//--------------------------------------------------------------------------
// (reserved) typedef logic [7:0]                     Byte_t;

typedef logic [XLEN-1:0]                Data_t;
// (reserved) typedef logic [DATA_BYTE_NUM-1:0]       ByteDataEna_t;
// (reserved) typedef Byte_t [DATA_BYTE_NUM-1:0]      ByteData_t;
typedef Data_t                          Addr_t;
// (reserved) typedef logic [BYTE_ADDR_WIDTH-1:0]     ByteAddr_t;
typedef logic [INSTR_LEN-1:0]           Instr_t;
// (reserved) typedef logic [$clog2(XLEN)-1:0]        Shamt_t;        // shift amount

// (reserved) typedef logic [6:0]                     Opcode_t;       // instruction opcode part,   fixed for all RISC-V instr. types
// (reserved) typedef logic [24:0]                    InstrVarPart_t; // instruction variadic part, different for R,I,S,B,U,J RISC-V instr. types   



//localparam Addr_t PC_START_ADDR = 32'H_0040_0000;
localparam Addr_t PC_START_ADDR = 32'H_0000_0000;

//=== common section (end)


//===IMEM section
//===IMEM section (end)

//=== ALU section 
localparam int ALU_SEL_LEN = 4;
typedef enum logic [ALU_SEL_LEN-1:0] {
    ALU_ADD  = 4'b0000,
    ALU_SUB  = 4'b0001,
    ALU_AND  = 4'b0010,
    ALU_OR   = 4'b0011,
    ALU_XOR  = 4'b0100,
    ALU_SLT  = 4'b0101,
    ALU_SLTU = 4'b0110,
    ALU_LUI  = 4'b0111,
    ALU_JALR = 4'b1000,
    ALU_ANY  = 4'bxxxx   
} ALU_SEL_t;
//=== ALU section (end)

//=== Shifter section
typedef logic [$clog2(XLEN)-1:0] shift_shamt_t;

typedef enum logic [2:0] {
    SHIFT_SLL = 3'b100,
    SHIFT_SRL = 3'b010,
    SHIFT_SRA = 3'b001,
    SHIFT_ANY = 3'bxxx
} shift_sel_t;
//=== Shifter section (end)


//=== IMM_GEN section
`define IMM_GEN_DEFS_ENA
`ifdef IMM_GEN_DEFS_ENA
typedef logic [31:0] Imm_t;
typedef enum logic [2:0] {
        IMM_I_TYPE = 3'b001,
        IMM_S_TYPE = 3'b010,
        IMM_B_TYPE = 3'b011,
        IMM_U_TYPE = 3'b100,
        IMM_J_TYPE = 3'b101,
        IMM_NC = 3'bxxx
    } Imm_type_t;
`endif
//=== IMM_GEN section (end)


//=== ID section 
`define ID_DEFS_ENA
/*
 * Instruction decoder instruction type.
 *
 * Passed as input argument into decoder instead of full instruction [31:0].
 * There's only 9 significant bits that are mandatory to determine instruction:
 * funct7[5], funct3[2:0], opcode[4:0] = [[31], [14], [13], [12], [6], [5], [4], [3], [2]]
 */
typedef struct packed {
    logic        funct7;  // [30] bit
    logic [2:0]  funct3;  // [14], [13], [12] bits
    logic [4:0]  opcode;  // [6], [5], [4], [3], [2] bits
} Id_instr_t;

/*
 * Instruction decoder control INPUT signals.
 *
 * Consists of additional input signals, necessary to decode an instruction.
 *   - br_eq : (rd1 == rd2) ? 1 : 0    [from branch comparator]
 *   - br_lt : (rd1 < rd2) ? 1 : 0     [from branch comparator]
 */
typedef struct packed {
    logic  br_eq;
    logic  br_lt;
} Id_controls_in_t;

/*
 * Instruction decoder control OUTPUT signals.
 *
 * Output control signals:
 *   - reg_wr      write to RF - 0: disabled, 1: enabled
 *   - dmem_we     write to DMEM - 0: disabled, 1: enabled
 *   - a_sel       first operand for ALU - 0: PC, 1: rd1
 *   - b_sel       second operand for ALU - 0: imm, 1: rd2
 *   - sh_sel      type of shift - 3'b100: SLL, 3'b010: SRL, 3'b001: SRA
 *   - br_un       type of branch comparison - 0: signed, 1: unsigned
 *   - pc_sel      next PC is - 0: ALU output, 1: PC+4
 *   - alu_sel     ALU op code: 0: add, 1: sub, 2: and, 3: or, 4: xor, 5: slt, 6: sltu, 7: lui, 8: jalr
 *   - wb_sel      source for write to RF: 0: PC+4, 1: ALU out, 2: shifter out, 3: dmem out
 *   - imm_type    type of instruction: 0: R, 1: I, 2: S, 3: B, 4: U, 5: J
 */
typedef struct packed {
    logic        reg_wr;
    logic        dmem_we;
    logic        a_sel;
    logic        b_sel;
    shift_sel_t  sh_sel;
    logic        br_un;
    logic        pc_sel;
    ALU_SEL_t    alu_sel;
    logic [1:0]  wb_sel;
    Imm_type_t imm_type;
} Id_controls_out_t;



// wb_sel
localparam WB_PC4_OUT     = 2'b00;
localparam WB_ALU_OUT     = 2'b01;
localparam WB_SHIFTER_OUT = 2'b10;
localparam WB_DMEM_OUT    = 2'b11;
localparam WB_ANY         = 2'bxx;

// instruction type
localparam INSTR_TYPE_R   = 3'b000;
localparam INSTR_TYPE_I   = 3'b001;
localparam INSTR_TYPE_S   = 3'b010;
localparam INSTR_TYPE_B   = 3'b011;
localparam INSTR_TYPE_U   = 3'b100;
localparam INSTR_TYPE_J   = 3'b101;
localparam INSTR_TYPE_ANY = 3'bxxx;

`ifdef ID_DEFS_ENA

localparam int ADDI_IMM_LEN  = 12;

typedef logic [RF_ADDR_WIDTH-1:0] RegAddr_t;
`endif
//=== ID section (end)

//=== Branch unit (end)
localparam int BRU_SEL_LEN = 3;

// BLTU/BGEU = BRU_BLT/BRU_BGE + br_un=1
typedef enum logic [BRU_SEL_LEN-1:0] {
    BRU_NONE = 3'b000,
    BRU_JAL  = 3'b001,
    BRU_JALR = 3'b010,
    BRU_BEQ  = 3'b011,
    BRU_BNE  = 3'b100,
    BRU_BLT  = 3'b101,
    BRU_BGE  = 3'b110
} BRU_SEL_t;
//=== Branch unit (end)

//=== DEBUG

`define SYS_DEBUG_OUT
//`define RF_DEBUG_OUT

`ifdef SIMULATOR
localparam int NN = 30;
typedef logic [0:NN*8-1] str_t;

//---
function automatic str_t string2str(input string in, input int N = NN);
    str_t out = '0;
    for(int i = 0; i < N && i < in.len(); i++) begin
        out[(i*8)+:8] = in[i];
    end
    return out;    
endfunction : string2str

//---
function automatic str_t disasm(input Instr_t instr);
    //opcode = instr[6:0];
    //funct3 = instr[14:12];
    //funct7 = instr[31:25];

    logic[8:0] case_key = { instr[30], instr[14:12], instr[6:2] };

    //--- imm generation
    int imm_i_type = signed'({{20{instr[31]}}, instr[31:20]});
    int imm_s_type = signed'({{20{instr[31]}}, instr[31:25], instr[11:7]});
    int imm_b_type = signed'({{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:9], 2'b00});
    int imm_u_type = signed'({instr[31:12], 12'b0});
    int imm_j_type = signed'({{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:22], 2'b00});
    // copied from feature/imm_gen branch

    logic [4:0] shamt = instr[24:20];
    //--- imm generation (end)

    string format_str;

    casex (case_key)
        // MNEMONIC  funct7_funct3_opcode
        /* LUI   */  'bx_xxx_01101: format_str = $sformatf("lui x%0d, %0d", instr[11:7], imm_u_type);
        /* AUIPC */  'bx_xxx_00101: format_str = $sformatf("auipc x%0d, %0d", instr[11:7], imm_u_type);
        /* JAL   */  'bx_xxx_11011: format_str = $sformatf("jal x%0d, %0d", instr[11:7], imm_j_type);
        /* JALR  */  'b0_000_11001: format_str = $sformatf("jalr x%0d, x%0d, %0d", instr[11:7], instr[19:15], imm_i_type);
        /* BEQ   */  'bx_000_11000: format_str = $sformatf("beq x%0d, x%0d, %0d", instr[19:15], instr[24:20], imm_b_type);
        /* BNE   */  'bx_001_11000: format_str = $sformatf("bne x%0d, x%0d, %0d", instr[19:15], instr[24:20], imm_b_type);
        /* BLT   */  'bx_100_11000: format_str = $sformatf("blt x%0d, x%0d, %0d", instr[19:15], instr[24:20], imm_b_type);
        /* BGE   */  'bx_101_11000: format_str = $sformatf("bge x%0d, x%0d, %0d", instr[19:15], instr[24:20], imm_b_type);
        /* BLTU  */  'bx_110_11000: format_str = $sformatf("bltu x%0d, x%0d, %0d", instr[19:15], instr[24:20], imm_b_type);
        /* BGEU  */  'bx_111_11000: format_str = $sformatf("bgeu x%0d, x%0d, %0d", instr[19:15], instr[24:20], imm_b_type);
        /* LB    */  'bx_000_00000: format_str = $sformatf("lb x%0d, %0d(x%0d)", instr[11:7], imm_i_type, instr[19:15]);
        /* LH    */  'bx_001_00000: format_str = $sformatf("lh x%0d, %0d(x%0d)", instr[11:7], imm_i_type, instr[19:15]);
        /* LW    */  'bx_010_00000: format_str = $sformatf("lw x%0d, %0d(x%0d)", instr[11:7], imm_i_type, instr[19:15]);
        /* LBU   */  'bx_100_00000: format_str = $sformatf("lbu x%0d, %0d(x%0d)", instr[11:7], imm_i_type, instr[19:15]);
        /* LHU   */  'bx_101_00000: format_str = $sformatf("lhu x%0d, %0d(x%0d)", instr[11:7], imm_i_type, instr[19:15]);
        /* SB    */  'bx_000_01000: format_str = $sformatf("sb x%0d, %0d(x%0d)", instr[24:20], imm_s_type, instr[19:15]);
        /* SH    */  'bx_001_01000: format_str = $sformatf("sh x%0d, %0d(x%0d)", instr[24:20], imm_s_type, instr[19:15]);
        /* SW    */  'bx_010_01000: format_str = $sformatf("sw x%0d, %0d(x%0d)", instr[24:20], imm_s_type, instr[19:15]);
        /* ADDI  */  'bx_000_00100: format_str = $sformatf("addi x%0d, x%0d, %0d", instr[11:7], instr[19:15], imm_i_type);
        /* SLTI  */  'bx_010_00100: format_str = $sformatf("slti x%0d, x%0d, %0d", instr[11:7], instr[19:15], imm_i_type);
        /* SLTIU */  'bx_011_00100: format_str = $sformatf("sltiu x%0d, x%0d, %0d", instr[11:7], instr[19:15], imm_i_type);
        /* XORI  */  'bx_100_00100: format_str = $sformatf("xori x%0d, x%0d, %0d", instr[11:7], instr[19:15], imm_i_type);
        /* ORI   */  'bx_110_00100: format_str = $sformatf("ori x%0d, x%0d, %0d", instr[11:7], instr[19:15], imm_i_type);
        /* ANDI  */  'bx_111_00100: format_str = $sformatf("andi x%0d, x%0d, %0d", instr[11:7], instr[19:15], imm_i_type);
        /* SLLI  */  'b0_001_00100: format_str = $sformatf("slli x%0d, x%0d, %0d", instr[11:7], instr[19:15], shamt);
        /* SRLI  */  'b0_101_00100: format_str = $sformatf("srli x%0d, x%0d, %0d", instr[11:7], instr[19:15], shamt);
        /* SRAI  */  'b1_101_00100: format_str = $sformatf("srai x%0d, x%0d, %0d", instr[11:7], instr[19:15], shamt);
        /* ADD   */  'b0_000_01100: format_str = $sformatf("add x%0d, x%0d, x%0d", instr[11:7], instr[19:15], instr[24:20]);
        /* SUB   */  'b1_000_01100: format_str = $sformatf("sub x%0d, x%0d, x%0d", instr[11:7], instr[19:15], instr[24:20]);
        /* SLL   */  'b0_001_01100: format_str = $sformatf("sll x%0d, x%0d, x%0d", instr[11:7], instr[19:15], instr[24:20]);
        /* SLT   */  'b0_010_01100: format_str = $sformatf("slt x%0d, x%0d, x%0d", instr[11:7], instr[19:15], instr[24:20]);
        /* SLTU  */  'b0_011_01100: format_str = $sformatf("sltu x%0d, x%0d, x%0d", instr[11:7], instr[19:15], instr[24:20]);
        /* XOR   */  'b0_100_01100: format_str = $sformatf("xor x%0d, x%0d, x%0d", instr[11:7], instr[19:15], instr[24:20]);
        /* SRL   */  'b0_101_01100: format_str = $sformatf("srl x%0d, x%0d, x%0d", instr[11:7], instr[19:15], instr[24:20]);
        /* SRA   */  'b1_101_01100: format_str = $sformatf("sra x%0d, x%0d, x%0d", instr[11:7], instr[19:15], instr[24:20]);
        /* OR    */  'b0_110_01100: format_str = $sformatf("or x%0d, x%0d, x%0d", instr[11:7], instr[19:15], instr[24:20]);
        /* AND   */  'b0_111_01100: format_str = $sformatf("and x%0d, x%0d, x%0d", instr[11:7], instr[19:15], instr[24:20]);

        /* There goes unsupported instructions, we consider them as NOPs */
        /* FENCE
            FENCE.TSO
            PAUSE */  'bx_000_00011: format_str = $sformatf("nop");
        /* ECALL
            EBREAK */ 'b0_000_11100: format_str = $sformatf("nop");

        default: begin
            format_str = $sformatf("n/i");
        end
    endcase

    return string2str(format_str);

endfunction : disasm
`endif
//=== DEBUG (end)



endpackage : risc_v_pkg

`endif // RISC_V_SVH