`ifndef SHA3_256_SVH
`define SHA3_256_SVH

/**
 * From-scratch implementation of SHA3-256 (FIPS 202) using the Keccak sponge construction.
 *
 * Parameters for SHA3-256:
 *   - State size b = 1600 bits
 *   - Capacity c = 512 bits
 *   - Rate r = 1088 bits = 136 bytes
 *   - Output length = 256 bits = 32 bytes
 *
 * This module is reusable but not thread-safe (non-reentrant if using global signals).
 */
class Sha3_256;
    /** Rate in bytes for SHA3-256: 1088 / 8 = 136. */
    localparam int RATE_BYTES   = 136;

    /** Digest size in bytes for SHA3-256: 256 / 8 = 32. */
    localparam int DIGEST_BYTES = 32;

    /** Rounds number for Keccak*/
    localparam int NUM_ROUNDS   = 24;

    /** 24 round constants for Keccak-f[1600]. */
    localparam longint unsigned RC[24] = '{
        64'h0000000000000001, 64'h0000000000008082, 64'h800000000000808A,
        64'h8000000080008000, 64'h000000000000808B, 64'h0000000080000001,
        64'h8000000080008081, 64'h8000000000008009, 64'h000000000000008A,
        64'h0000000000000088, 64'h0000000080008009, 64'h000000008000000A,
        64'h000000008000808B, 64'h800000000000008B, 64'h8000000000008089,
        64'h8000000000008003, 64'h8000000000008002, 64'h8000000000000080,
        64'h000000000000800A, 64'h800000008000000A, 64'h8000000080008081,
        64'h8000000000008080, 64'h0000000080000001, 64'h8000000080008008
    };

    /** Flat array indexed by x + 5*y.
     ROTATION_OFFSETS[x + 5*y] == A[x][y] offset. */
    localparam int ROTATION_OFFSETS[25] = '{
        0, 1, 62, 28, 27,
        36, 44, 6, 55, 20, 
        3, 10, 43, 25, 39, 
        41, 45, 15, 21, 8, 
        18, 2, 61, 56, 14
    };

    /** State as 5x5 lanes of 64 bits each: state[x][y]. */
    local longint unsigned state[25];

    local function automatic longint unsigned rotLeft64(longint unsigned x, int n);
        return (x << n) | (x >> (64 - n));
    endfunction

    /**
    * Applies the Keccak-f[1600] permutation.
    */
    local task automatic keccak_f();
        /** Column parities for the Theta step. */
        longint unsigned c[5];
    
        /** Theta diffusion values. */
        longint unsigned d[5];
    
        /** Temporary state used by the Pi step. */
        longint unsigned temp[25];
    
        /** Row snapshot used by the Chi step. */
        longint unsigned row[5];

        int x;
        int y;

        for (int round = 0; round < NUM_ROUNDS; round++) begin
            
            /** --- Theta --- */
            for (x = 0; x < 5; x++) begin
                c[x] = state[x + 5 * 0] ^ state[x + 5 * 1] ^ state[x + 5 * 2] ^ state[x + 5 * 3] ^ state[x + 5 * 4];
            end
            for (x = 0; x < 5; x++) begin
                d[x] = c[(x + 4) % 5] ^ rotLeft64(c[(x + 1) % 5], 1);
            end
            for (x = 0; x < 5; x++) begin
                for (y = 0; y < 5; y++) begin
                    state[x + 5 * y] ^= d[x];
                end
            end
 
            /** --- Rho --- */
            for (x = 0; x < 5; x++) begin
                for (y = 0; y < 5; y++) begin
                    state[x + 5 * y] = rotLeft64(state[x + 5 * y], ROTATION_OFFSETS[x + 5 * y]);
                end
            end
 
            /** --- Pi --- */
            for (x = 0; x < 5; x++) begin
                for (y = 0; y < 5; y++) begin
                    temp[x + 5 * y] = state[(x + 3 * y) % 5 + 5 * x];
                end
            end
            for (x = 0; x < 5; x++) begin
                for (y = 0; y < 5; y++) begin
                    state[x + 5 * y] = temp[x + 5 * y];
                end
            end
 
            /** --- Chi --- */
            for (y = 0; y < 5; y++) begin
                for (x = 0; x < 5; x++) begin
                    row[x] = state[x + 5 * y];
                end
                for (x = 0; x < 5; x++) begin
                    state[x + 5 * y] = row[x] ^ (~row[(x + 1) % 5] & row[(x + 2) % 5]);
                end
            end
 
            /** --- Iota --- */
            state[0] ^= RC[round];

        end

    endtask

endclass : Sha3_256
`endif // SHA3_256_SVH