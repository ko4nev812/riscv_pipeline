//------------------------------------------------------------------------------
//  project:       RISC-V (SberLab Novosibirsk State University)
//
//  modules:        
//
//  description:   
//------------------------------------------------------------------------------

`ifndef RISC_V_SVH
`define RISC_V_SVH

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
localparam IMEM_INIT_FILE  = "IMem_Init_File.mem";
//===IMEM section (end)
//=== ALU section 
`define ALU_DEFS_ENA
`ifdef ALU_DEFS_ENA
localparam int ALU_SEL_LEN = 8;
localparam ALU_BYP = 4'b0111;  // TODO RENAME in ALU to LUI
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
`endif
//=== ALU section (end)

//=== Shifter section
typedef logic [$clog2(XLEN)-1:0] shift_shamt_t;

typedef enum logic [2:0] {
    SLLI = 3'b100,
    SRLI = 3'b010,
    SRAI = 3'b001
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

// sh_sel
localparam SHIFT_SLL = 3'b100;
localparam SHIFT_SRL = 3'b010;
localparam SHIFT_SRA = 3'b001;
localparam SHIFT_ANY = 3'bxxx;

// alu_sel

/*
localparam ALU_ADD  = 4'b0000;
localparam ALU_SUB  = 4'b0001;
localparam ALU_AND  = 4'b0010;
localparam ALU_OR   = 4'b0011;
localparam ALU_XOR  = 4'b0100;
localparam ALU_SLT  = 4'b0101;
localparam ALU_SLTU = 4'b0110;
localparam ALU_LUI  = 4'b0111;
localparam ALU_JALR = 4'b1000;
localparam ALU_ANY  = 4'bxxxx;
*/

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

    string format_str;

    logic is_add = (instr[6:0] == 7'b0110011) & (instr[14:12] == 3'b000) & (instr[31:25] == 7'b0000000);
    logic is_addi = (instr[6:0] == 7'b0010011) & (instr[14:12] == 3'b000);

    //--- add
    if(is_add) begin
        format_str = $sformatf("add x%1d, x%1d, x%1d", instr[11:7], instr[19:15], instr[24:20]);
        return string2str(format_str);
    end    

    //--- addi
    if(is_addi) begin
        Data_t imm = {{(INSTR_LEN-ADDI_IMM_LEN){instr[INSTR_LEN-1]}}, instr[INSTR_LEN-1:INSTR_LEN-ADDI_IMM_LEN]};
        format_str = $sformatf("addi x%1d, x%1d, %4d", instr[11:7], instr[19:15], int'(imm));
        return string2str(format_str);
    end    

    //--- unknown instr
    format_str = $sformatf("n/i");
    return string2str(format_str);

endfunction : disasm
`endif
//=== DEBUG (end)



endpackage : risc_v_pkg

`endif // RISC_V_SVH