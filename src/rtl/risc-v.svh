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

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
`define IMEM_BRAM


//******************************************************************************
//******************************************************************************
package risc_v_pkg;

//=== common section

//--------------------------------------------------------------------------
localparam int XLEN = 32;                            // RISC-V ISA dependent

localparam int IMEM_ADDR_BYTE_WIDTH = 10;            // (byte addressed) CPU system implementation dependent
localparam int DMEM_ADDR_BYTE_WIDTH = 12;            // (byte addressed) CPU system implementation dependent, 2^12 = 4KB - it's 1 BRAM block (TODO: check it)

localparam int INSTR_LEN       = 32;                 // fixed for all RISC-V ISA except RVC
localparam int RF_ADDR_WIDTH   = 5;                  // RISC-V ISA dependent (?)

//--------------------------------------------------------------------------
parameter int DATA_BYTE_NUM   = XLEN / 8;
parameter int BYTE_ADDR_WIDTH = $clog2(DATA_BYTE_NUM);
parameter int DMEM_PORT_ADDR_WIDTH = DMEM_ADDR_BYTE_WIDTH - BYTE_ADDR_WIDTH;

//--------------------------------------------------------------------------
typedef logic [RF_ADDR_WIDTH-1:0]        RegAddr_t;
typedef logic [XLEN-1:0]                 Data_t;
typedef logic [DATA_BYTE_NUM-1:0]        ByteDataEna_t;
typedef logic [7:0]                      Byte_t;
typedef logic [BYTE_ADDR_WIDTH-1:0]      ByteAddr_t;
typedef logic [INSTR_LEN-1:0]            Instr_t;
typedef Byte_t                           ByteData_t [DATA_BYTE_NUM];
typedef Data_t                           Addr_t;

// (reserved) typedef logic [$clog2(XLEN)-1:0]        Shamt_t;        // shift amount

// (reserved) typedef logic [6:0]                     Opcode_t;       // instruction opcode part,   fixed for all RISC-V instr. types
// (reserved) typedef logic [24:0]                    InstrVarPart_t; // instruction variadic part, different for R,I,S,B,U,J RISC-V instr. types   


//localparam Addr_t PC_START_ADDR = 32'H_0040_0000;
localparam Addr_t PC_START_ADDR = 32'h0000_0000;

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

//=== SHIFTER section
typedef logic [$clog2(XLEN)-1:0] shift_shamt_t;

typedef enum logic [2:0] {
    SHIFT_SLL = 3'b100,
    SHIFT_SRL = 3'b010,
    SHIFT_SRA = 3'b001,
    SHIFT_ANY = 3'bxxx
} shift_sel_t;
//=== SHIFTER section (end)


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
typedef logic [24:0] Imm_input_t;
`endif
//=== IMM_GEN section (end)



//===DMEM section
typedef enum logic [2:0] {
    LOAD_LB  = 3'b000,
    LOAD_LH  = 3'b001,
    LOAD_LW  = 3'b010,
    LOAD_LBU = 3'b100,
    LOAD_LHU = 3'b101
} LoadInstr_t;

typedef enum logic [3:0]{
    DMEMS_LB  = 4'b0000,
    DMEMS_LH  = 4'b0001,
    DMEMS_LW  = 4'b0010,
    DMEMS_LBU = 4'b0100,
    DMEMS_LHU = 4'b0101,

    DMEMS_SB  = 4'b1000,
    DMEMS_SH  = 4'b1001,
    DMEMS_SW  = 4'b1010,
    DMEMS_ANY = 4'b0xxx
} Dmem_sel_t;
//===DMEM section (end)



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
    logic [1:0]  ones;    // [1], [0] bits (should be 'b11 for legal instructions)
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


localparam int WB_SEL_LEN = 2;
typedef enum logic [WB_SEL_LEN-1:0] {
    WB_PC4_OUT     = 2'b00,
    WB_ALU_OUT     = 2'b01,
    WB_DMEM_OUT    = 2'b10,
    WB_ANY         = 2'bxx 
} WB_SEL_t;

typedef enum logic {
    AS_ALU_OUT = 1'b0,
    AS_SHIFT_OUT = 1'b1,
    AS_ANY = 1'bx
} ALUSHIFT_sel_t;


/*
 * Instruction decoder control OUTPUT signals.
 *
 * Output control signals:
 *   - reg_wr          write to RF - 0: disabled, 1: enabled
 *   - dmem_we         write to DMEM - 0: disabled, 1: enabled
 *   - a_sel           first operand for ALU - 0: PC, 1: rd1
 *   - b_sel           second operand for ALU - 0: imm, 1: rd2
 *   - sh_sel          type of shift - 3'b100: SLL, 3'b010: SRL, 3'b001: SRA
 *   - br_un           type of branch comparison - 0: signed, 1: unsigned
 *   - jf_id           jump from instruction decode stage - 0: not jump, 1: will jump
 *   - alu_sel         ALU op code: 0: add, 1: sub, 2: and, 3: or, 4: xor, 5: slt, 6: sltu, 7: lui, 8: jalr
 *   - wb_sel          source for write to RF: 0: PC+4, 1: ALU/SHIFT out, 2: dmem out
 *   - jfexe           jump from execute - 0: not jump, 1: will jump (only jalr instruction)
 *   - alushift_sel    alu or shift take - 0: alu, 1: shift
 *   - imm_type        type of instruction: 0: R, 1: I, 2: S, 3: B, 4: U, 5: J
 */
typedef struct packed {
    logic           reg_wr;
    Dmem_sel_t      dmem_sel;
    logic           a_sel;
    logic           b_sel;
    shift_sel_t     sh_sel;
    logic           br_un;
    logic           jf_id;
    ALU_SEL_t       alu_sel;
    WB_SEL_t        wb_sel;
    logic           jf_exe;
    ALUSHIFT_sel_t  alushift_sel;
    Imm_type_t      imm_type;
} Id_controls_out_t;


// instruction type
localparam int INSTR_TYPE_LEN = 3;
typedef enum logic [INSTR_TYPE_LEN-1:0] {
  //  INSTR_TYPE_R     = 3'b000,  <--- Not used
    INSTR_TYPE_I     = 3'b001,
    INSTR_TYPE_S     = 3'b010,
    INSTR_TYPE_B     = 3'b011,
    INSTR_TYPE_U     = 3'b100,
    INSTR_TYPE_J     = 3'b101,
    INSTR_TYPE_ANY   = 3'bxxx
} INSTR_TYPE_t;

`ifdef ID_DEFS_ENA
`endif
//=== ID section (end)




// ================================================
// ============= STAGE CATEGORY ===================

// ===FETCH section
// interstage buffer (ISB)
typedef struct packed {
    Addr_t pc;
    Instr_t instr;
    logic valid;
} ISB_fetch_t;
// ===FETCH section (end)


// ===DECODE section
// interstage buffer (ISB)
typedef struct packed {
    Addr_t pc;
    Data_t rf_rd1;
    Data_t rf_rd2;
    Imm_t imm;
    RegAddr_t rs1;
    RegAddr_t rs2;
    RegAddr_t rd;
    ALU_SEL_t alu_sel;
    shift_sel_t shift_sel;
    logic a_sel;
    logic b_sel;
    WB_SEL_t wb_sel;
    logic reg_wr;
    Dmem_sel_t dmem_sel;
    logic jf_exe;
    logic alushift_sel;
    logic valid;
} ISB_decode_t;
// ===DECODE section (and)


// ===EXECUTE section
// interstage buffer (ISB)
typedef struct packed {
    Data_t alu_out;
    Data_t rf_rd2;
    RegAddr_t rd;
    WB_SEL_t wb_sel;
    logic reg_wr;
    Addr_t pc4;
    logic valid;
} ISB_execute_t;
// ===EXECUTE section (end)


// ===MEMORY section
// interstage buffer (ISB)
typedef struct packed {
    Data_t alu_out;
    Data_t dmem_data_out;
    RegAddr_t rd;
    WB_SEL_t wb_sel;
    logic reg_wr;
    Addr_t pc4;
    logic valid;
} ISB_memory_t;

// Dmem input
typedef struct packed {
    Dmem_sel_t dmem_sel;
    Data_t dmem_addr;
    Data_t dmem_data_in;
} Dmem_memory_stage_input_t;
// ===MEMORY section (end)


// ===WRITE BACK section
// ===WRITE BACK section (end)


// =================================================



//=== Hazard detection unit section
typedef struct packed {
    logic jf_id_D;
    logic jf_exe_D;
    RegAddr_t rf_rs1_D;
    RegAddr_t rf_rs2_D;
    logic [4:0] opcode_D;

    logic jf_exe_E;
    RegAddr_t rf_rd_E;
    logic rf_we_E;

    RegAddr_t rf_rd_M;
    logic rf_we_M;

    RegAddr_t rf_rd_W;
    logic rf_we_W;
} HDU_input_t;

typedef struct packed {
    logic stall_pc;
    logic if_id_stall;
    logic if_id_flush;
    logic id_ex_stall;
    logic id_ex_flush;
} HDU_output_t;

//=== Hazard detection unit section (end)






//===UART section
localparam RV_BAUD_RATE  = 115200;
localparam RV_TIME_BASE  = 20;  // ns per system clock period
localparam RV_DATA_WIDTH = 8;


typedef enum logic[1:0] {
    TXSTATUS_ADDR = 2'h0,
    TXDATA_ADDR   = 2'h1,
    RXSTATUS_ADDR = 2'h2,
    RXDATA_ADDR   = 2'h3
} UARTMapAddrs;
//===UART section (end)




//=== DEBUG

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





