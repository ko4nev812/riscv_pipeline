`include "risc-v.svh"

module hazard_detection_unit
import risc_v_pkg::*;
(
    input  HDU_input_t  hdu_in,
    output HDU_output_t hdu_out
);

    logic uses_rs1;
    logic uses_rs2;
    logic data_stall;

    always_comb begin
        //==============================================================
        // Defaults
        //==============================================================
        hdu_out = '0;

        //==============================================================
        // Source register usage
        //==============================================================
        unique case (hdu_in.opcode_D)
            5'b11001, // JALR
            5'b11000, // BRANCH
            5'b00000, // LOAD
            5'b01000, // STORE
            5'b00100, // OP-IMM
            5'b01100: // OP
                uses_rs1 = 1'b1;
            default:
                uses_rs1 = 1'b0;
        endcase

        unique case (hdu_in.opcode_D)
            5'b11000, // BRANCH
            5'b01000, // STORE
            5'b01100: // OP
                uses_rs2 = 1'b1;
            default:
                uses_rs2 = 1'b0;
        endcase

        //==============================================================
        // Data-hazard predicate
        //==============================================================
        data_stall =
            (hdu_in.rf_we_E && (hdu_in.rf_rd_E != 5'd0) &&
             ((uses_rs1 && (hdu_in.rf_rd_E == hdu_in.rf_rs1_D)) ||
              (uses_rs2 && (hdu_in.rf_rd_E == hdu_in.rf_rs2_D)))) ||
            (hdu_in.rf_we_M && (hdu_in.rf_rd_M != 5'd0) &&
             ((uses_rs1 && (hdu_in.rf_rd_M == hdu_in.rf_rs1_D)) ||
              (uses_rs2 && (hdu_in.rf_rd_M == hdu_in.rf_rs2_D)))) ||
            (hdu_in.rf_we_W && (hdu_in.rf_rd_W != 5'd0) &&
             ((uses_rs1 && (hdu_in.rf_rd_W == hdu_in.rf_rs1_D)) ||
              (uses_rs2 && (hdu_in.rf_rd_W == hdu_in.rf_rs2_D))));

        //==============================================================
        // Control hazards
        //==============================================================

        // JALR in Decode
        if (hdu_in.jf_exe_D && !data_stall) begin
            hdu_out.stall_pc    = 1'b1;
            hdu_out.if_id_flush = 1'b1;
        end

        // JALR resolved in Execute
        if (hdu_in.jf_exe_E) begin
            hdu_out.if_id_flush = 1'b1;
            hdu_out.id_ex_flush = 1'b1;
        end

        // Branch / JAL in Decode
        //if (hdu_in.jf_id_D && !data_stall) begin
        //    hdu_out.if_id_flush = 1'b1;
        //end
        
        //==============================================================
        // Data hazards
        //==============================================================
        if(data_stall) begin
            hdu_out.stall_pc    = 1'b1;
            hdu_out.if_id_stall = 1'b1;
            hdu_out.id_ex_flush = 1'b1;
        end
        /*
        // Decode <-> Execute
        if (hdu_in.rf_we_E &&
            (hdu_in.rf_rd_E != 5'd0) &&
            (
                (uses_rs1 && (hdu_in.rf_rd_E == hdu_in.rf_rs1_D)) ||
                (uses_rs2 && (hdu_in.rf_rd_E == hdu_in.rf_rs2_D))
            ))
        begin
            hdu_out.stall_pc    = 1'b1;
            hdu_out.if_id_stall = 1'b1;
            hdu_out.id_ex_flush = 1'b1;
        end

        // Decode <-> Memory
        if (hdu_in.rf_we_M &&
            (hdu_in.rf_rd_M != 5'd0) &&
            (
                (uses_rs1 && (hdu_in.rf_rd_M == hdu_in.rf_rs1_D)) ||
                (uses_rs2 && (hdu_in.rf_rd_M == hdu_in.rf_rs2_D))
            ))
        begin
            hdu_out.stall_pc    = 1'b1;
            hdu_out.if_id_stall = 1'b1;
            hdu_out.id_ex_flush = 1'b1;
        end

        // Decode <-> Writeback
        if (hdu_in.rf_we_W &&
            (hdu_in.rf_rd_W != 5'd0) &&
            (
                (uses_rs1 && (hdu_in.rf_rd_W == hdu_in.rf_rs1_D)) ||
                (uses_rs2 && (hdu_in.rf_rd_W == hdu_in.rf_rs2_D))
            ))
        begin
            hdu_out.stall_pc    = 1'b1;
            hdu_out.if_id_stall = 1'b1;
            hdu_out.id_ex_flush = 1'b1;
        end
        */

    end

endmodule : hazard_detection_unit