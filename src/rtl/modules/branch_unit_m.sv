`include "risc-v.svh"

module branch_unit_m import risc_v_pkg::*;
(
    input  Data_t        rd1,
    input  Data_t        rd2,
    input  Branch_sel_t  branch_sel,

    output logic         branch_taken
);

always_comb begin
    case (branch_sel)
        BRANCH_BEQ:  branch_taken = (rd1 == rd2);
        BRANCH_BNE:  branch_taken = (rd1 != rd2);
        BRANCH_BLT:  branch_taken = ($signed(rd1) < $signed(rd2));
        BRANCH_BGE:  branch_taken = ($signed(rd1) >= $signed(rd2));
        BRANCH_BLTU: branch_taken = (rd1 < rd2);
        BRANCH_BGEU: branch_taken = (rd1 >= rd2);
        default:     branch_taken = 1'b0;  // BRANCH_ANY or invalid
    endcase
end

endmodule : branch_unit_m