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

    /**
     * SHA-3 domain separation suffix (FIPS 202, Section 6.1).
     * Distinguishes SHA-3 from SHAKE and raw Keccak.
     */
    localparam byte SHA3_DOMAIN_SUFFIX = 0x06;

    /**
     * High bit set in the final padding byte, completing the pad10*1 pattern.
     * Combined with SHA3_DOMAIN_SUFFIX when exactly one byte of padding is available:
     * 0x06 | 0x80 = 0x86.
     */
    localparam byte PADDING_END_BIT = 0x80;

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

    /** 
    * XORs a slice of the given byte array into the state using little-endian packing 
    * within each 64-bit lane. 
    */
    local task automatic xor_block(input byte unsigned blk[], input int len);
        int pos;
        int x;
        int y; 
        int b; 
        int end_b;
        longint unsigned lane;
        assert (len >= 0 && len <= RATE_BYTES) else $fatal(1, "xor_block: invalid len=%0d", len);
        pos = 0;
        for (y = 0; y < 5; y++) begin : outer_loop
            for (x = 0; x < 5; x++) begin
                if (pos >= len) disable outer_loop;
                lane = 0;
                end_b = ((8 < len - pos) ? 8 : len - pos);
                for (b = 0; b < end_b; b++) begin
                    lane |= longint unsigned'(blk[pos++]) << (8 * b);
                end
                state[x + 5 * y] ^= lane;
            end
        end
    endtask

    /** 
    * Applies SHA-3 domain separation and multi-rate padding (pad10*1) to the final partial 
    * block, absorbs it into the state, and runs the permutation. 
    * 
    * Uses the pre-allocated {@link #paddingBlock} field instead of allocating a new array. 
    * The buffer is always fully overwritten here, so no stale bytes can leak between calls. 
    * 
    * The SHA-3 domain suffix is 0x06 (FIPS 202, Section 6.1). Combined with pad10*1: 
    * If exactly one byte of padding fits: append 0x86 (0x06 | 0x80) 
    * Otherwise: append 0x06, then zero bytes, then 0x80 in the last position 
    * 
    * @param blk source buffer; bytes [0, filled) contain the message tail 
    * @param filled number of message bytes in the buffer, in range [0, RATE_BYTES) 
    */
    local task automatic absorb_final(input byte unsigned blk[], input int filled);
        int y;
        int q;
        localparam byte unsigned pad_blk[RATE_BYTES];
        assert (filled >= 0 && filled < RATE_BYTES) else $fatal(1, "absorb_final: invalid filled=%0d", filled)

        /** 
        * Copy the message tail into the reusable padding blk.
        */
        for (y = 0; y < filled; y++) begin
            blk[y] = pad_blk[y];
        end

        /** 
        * Zero out the remainder so no stale bytes survive from a previous call.
        */
        for (y = filled; y < RATE_BYTES; y++) begin
            pad_blk[y] = 8'h00;
        end

        q = RATE_BYTES - filled; /** always >= 1 */

        if (q == 1) begin
            /** 
            * Only one byte of space: domain suffix and end-bit are combined.
            */
            pad_blk[filled] = byte'(SHA3_DOMAIN_SUFFIX | PADDING_END_BIT); /** 0x86 */
        end else begin
            pad_blk[filled]         = SHA3_DOMAIN_SUFFIX; /** 0x06 */
            pad_blk[RATE_BYTES - 1] = PADDING_END_BIT;   /** 0x80 */
        end

        /** 
        * Absorb the full padding block — length == RATE_BYTES is intentional.
        */
        xor_block(pad_blk, RATE_BYTES);
        keccakf();
    endtask


endclass : Sha3_256
`endif // SHA3_256_SVH