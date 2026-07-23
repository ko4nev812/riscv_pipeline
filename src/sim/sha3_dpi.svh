`ifndef SHA3_DPI_SVH
`define SHA3_DPI_SVH

typedef int unsigned uint32_t;

import "DPI-C" function int dpi_sha3_256_begin();

import "DPI-C" function int dpi_sha3_256_update_word(
    input int unsigned word, 
    input int          byte_count
);

import "DPI-C" function int dpi_sha3_256_final(
    output int unsigned digest0,
    output int unsigned digest1,
    output int unsigned digest2,
    output int unsigned digest3,
    output int unsigned digest4,
    output int unsigned digest5,
    output int unsigned digest6,
    output int unsigned digest7
);

class Sha3Dpi;
    static function automatic void check_status(input int status, input string op);
        if (status != 0) begin
            $fatal(1, "[E] SHA3 DPI %s failed with status %0d", op, status);
        end
    endfunction : check_status

    static function automatic void begin_hash();
        check_status(dpi_sha3_256_begin(), "begin");
    endfunction : begin_hash

    static function automatic void update_word(input logic [31:0] word, input int byte_count = 4);
        check_status(dpi_sha3_256_update_word(uint32_t'(word), byte_count), "update_word");
    endfunction : update_word

    static function automatic string final_hex();
        int status;
        int unsigned d0;
        int unsigned d1;
        int unsigned d2;
        int unsigned d3;
        int unsigned d4;
        int unsigned d5;
        int unsigned d6;
        int unsigned d7;

        status = dpi_sha3_256_final(d0, d1, d2, d3, d4, d5, d6, d7);
        check_status(status, "final");

        return $sformatf("%08x%08x%08x%08x%08x%08x%08x%08x",
                         d0, d1, d2, d3, d4, d5, d6, d7);
    endfunction : final_hex

    static task automatic self_test();
        string result;

        begin_hash();
        result = final_hex();
        $display("=== SHA3 DPI empty: %s", result);
        if (result != "a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a") begin
            $fatal(1, "[E] SHA3 DPI empty string self-test failed");
        end

        begin_hash();
        update_word(32'h00636261, 3);
        result = final_hex();
        $display("=== SHA3 DPI abc:   %s", result);
        if (result != "3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532") begin
            $fatal(1, "[E] SHA3 DPI abc self-test failed");
        end

        $display("=== SHA3 DPI self-test PASS");
    endtask : self_test
endclass : Sha3Dpi

`endif // SHA3_DPI_SVH
