`include "sha3_256.svh"
module sha3_tb;
    initial begin
        Sha3_256 h = new();
        string result;
        
        result = h.digest_bytes('{});
        $display("empty: %s", result);
        assert (result == "a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a")
            else $error("FAIL empty string");
        result = h.digest_bytes('{8'h61, 8'h62, 8'h63});
        $display("abc:   %s", result);
        assert (result == "3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532")
            else $error("FAIL abc");
        // digest_slice: hash "abc" (bytes 1..3) out of a 5-byte buffer "xabcy"
        result = h.digest_slice('{8'h78, 8'h61, 8'h62, 8'h63, 8'h79}, 1, 3);
        $display("slice: %s", result);
        assert (result == "3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532")
            else $error("FAIL slice");
        $display("DONE");
        $finish;
    end
endmodule