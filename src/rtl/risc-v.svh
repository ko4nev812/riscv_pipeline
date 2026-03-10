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

localparam int INSTR_LEN       = 32;                 // fixed for all RISC-V ISA
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
typedef enum logic [ALU_SEL_LEN-1:0] { ALU_ADD, ALU_SUB, ALU_AND, ALU_OR, ALU_XOR, ALU_SLT, ALU_SLTU, ALU_JALR, ALU_BYP } ALU_SEL_t;
`endif
//=== ALU section (end)

//=== ID section 
`define ID_DEFS_ENA
`ifdef ID_DEFS_ENA
//localparam int INSTR_LEN     = 32; // fixed for all RISC-V ISA except RVC
//localparam int RF_ADDR_WIDTH = 5; // RISC-V ISA dependent (?)
localparam int ADDI_IMM_LEN  = 12;

//typedef logic [INSTR_LEN-1:0] Instr_t;
typedef logic [RF_ADDR_WIDTH-1:0] RegAddr_t;
`endif
//=== ID section (end)


//=== DEBUG

`define SYS_DEBUG_OUT
`define RF_DEBUG_OUT

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