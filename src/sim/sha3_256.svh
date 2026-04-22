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
 * This class is reusable but not thread-safe.
 */
class Sha3_256;
    /** Rate in bytes for SHA3-256: 1088 / 8 = 136. */
    localparam int RATE_BYTES   = 136;

    /** Digest size in bytes for SHA3-256: 256 / 8 = 32. */
    localparam int DIGEST_BYTES = 32;

    /** Number of rounds for Keccak-f[1600]. */
    localparam int NUM_ROUNDS   = 24;

    /**
     * SHA-3 domain separation suffix (FIPS 202, Section 6.1).
     * Distinguishes SHA-3 from SHAKE and raw Keccak.
     */
    localparam byte unsigned SHA3_DOMAIN_SUFFIX = 8'h06;

    /**
     * High bit set in the final padding byte, completing the pad10*1 pattern.
     * Combined with SHA3_DOMAIN_SUFFIX when exactly one byte of padding is available:
     * 0x06 | 0x80 = 0x86.
     */
    localparam byte unsigned PADDING_END_BIT = 8'h80;

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

    /**
     * Per-lane rotation offsets for the Rho step (FIPS 202, Section 3.2.2).
     * Flat array indexed by x + 5*y, matching the state layout.
     * ROTATION_OFFSETS[x + 5*y] is the rotation amount for lane A[x][y].
     */
    localparam int ROTATION_OFFSETS[25] = '{
        0, 1, 62, 28, 27,
        36, 44, 6, 55, 20,
        3, 10, 43, 25, 39,
        41, 45, 15, 21, 8,
        18, 2, 61, 56, 14
    };

    /**
     * Keccak state: 25 lanes of 64 bits each.
     * Flat index: state[x + 5*y] corresponds to lane A[x][y] from FIPS 202.
     */
    local longint unsigned state[25];

    //--------------------------------------------------------------------------
    // Private helpers
    //--------------------------------------------------------------------------

    /** Returns x rotated left by n bits within a 64-bit word. */
    local function automatic longint unsigned rotLeft64(longint unsigned x, int n);
        if (n == 0) return x;
        return (x << n) | (x >> (64 - n));
    endfunction

    /**
     * Applies the Keccak-f[1600] permutation to the state.
     */
    local function automatic void keccak_f();
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
            for (x = 0; x < 5; x++)
                c[x] = state[x + 5*0] ^ state[x + 5*1] ^ state[x + 5*2] ^ state[x + 5*3] ^ state[x + 5*4];
            for (x = 0; x < 5; x++)
                d[x] = c[(x + 4) % 5] ^ rotLeft64(c[(x + 1) % 5], 1);
            for (x = 0; x < 5; x++)
                for (y = 0; y < 5; y++)
                    state[x + 5*y] ^= d[x];

            /** --- Rho --- */
            for (x = 0; x < 5; x++)
                for (y = 0; y < 5; y++)
                    state[x + 5*y] = rotLeft64(state[x + 5*y], ROTATION_OFFSETS[x + 5*y]);

            /** --- Pi --- */
            for (x = 0; x < 5; x++)
                for (y = 0; y < 5; y++)
                    temp[x + 5*y] = state[(x + 3*y) % 5 + 5*x];
            for (x = 0; x < 5; x++)
                for (y = 0; y < 5; y++)
                    state[x + 5*y] = temp[x + 5*y];

            /** --- Chi --- */
            for (y = 0; y < 5; y++) begin
                for (x = 0; x < 5; x++)
                    row[x] = state[x + 5*y];
                for (x = 0; x < 5; x++)
                    state[x + 5*y] = row[x] ^ (~row[(x + 1) % 5] & row[(x + 2) % 5]);
            end

            /** --- Iota --- */
            state[0] ^= RC[round];

        end

    endfunction

    /**
     * XORs bytes data[offset .. offset+len) into the state using little-endian
     * packing within each 64-bit lane.
     */
    local function automatic void xor_block(input byte unsigned blk[], input int offset, input int len);
        int pos;
        int x;
        int y;
        int b;
        int end_b;
        longint unsigned lane;
        assert (offset >= 0 && len >= 0 && len <= RATE_BYTES && offset + len <= blk.size())
            else $fatal(1, "xor_block: invalid args offset=%0d len=%0d", offset, len);
        pos = 0;
        for (y = 0; y < 5; y++) begin : outer_loop
            for (x = 0; x < 5; x++) begin
                if (pos >= len) disable outer_loop;
                lane = 0;
                end_b = ((8 < len - pos) ? 8 : len - pos);
                for (b = 0; b < end_b; b++)
                    lane |= longint unsigned'(blk[offset + pos++]) << (8 * b);
                state[x + 5*y] ^= lane;
            end
        end
    endfunction

    /**
     * Applies SHA-3 domain separation and multi-rate padding (pad10*1) to the
     * final partial block, absorbs it into the state, and runs the permutation.
     *
     * The SHA-3 domain suffix is 0x06 (FIPS 202, Section 6.1). Combined with pad10*1:
     *   - If exactly one byte of padding fits: append 0x86 (0x06 | 0x80)
     *   - Otherwise: append 0x06, then zero bytes, then 0x80 in the last position
     *
     * @param blk    source buffer; bytes [0, filled) contain the message tail
     * @param filled number of message bytes in the buffer, in range [0, RATE_BYTES)
     */
    local function automatic void absorb_final(input byte unsigned blk[], input int filled);
        int y;
        int q;
        byte unsigned pad_blk[RATE_BYTES];
        assert (filled >= 0 && filled < RATE_BYTES) else $fatal(1, "absorb_final: invalid filled=%0d", filled);

        for (y = 0; y < filled; y++)
            pad_blk[y] = blk[y];

        for (y = filled; y < RATE_BYTES; y++)
            pad_blk[y] = 8'h00;

        q = RATE_BYTES - filled; /** always >= 1 */

        if (q == 1) begin
            /** Only one byte of space: domain suffix and end-bit are combined. */
            pad_blk[filled] = byte'(SHA3_DOMAIN_SUFFIX | PADDING_END_BIT); /** 0x86 */
        end else begin
            pad_blk[filled]         = SHA3_DOMAIN_SUFFIX; /** 0x06 */
            pad_blk[RATE_BYTES - 1] = PADDING_END_BIT;   /** 0x80 */
        end

        xor_block(pad_blk, 0, RATE_BYTES);
        keccak_f();
    endfunction

    /**
     * Extracts the first DIGEST_BYTES bytes from the state in little-endian lane order.
     */
    local function automatic byte unsigned[] squeeze();
        byte unsigned out[] = new[DIGEST_BYTES];
        int pos;
        int x;
        int y;
        int b;
        int end_b;
        longint unsigned lane;
        pos = 0;

        for (y = 0; y < 5; y++) begin : outer_loop
            for (x = 0; x < 5; x++) begin
                if (pos >= DIGEST_BYTES) disable outer_loop;
                lane = state[x + 5*y];
                end_b = ((8 < DIGEST_BYTES - pos) ? 8 : DIGEST_BYTES - pos);
                for (b = 0; b < end_b; b++)
                    out[pos++] = byte'(lane >> (8 * b));
            end
        end

        return out;
    endfunction

    /**
     * Converts a byte array to a lowercase hexadecimal string.
     */
    local function automatic string to_hex(input byte unsigned data[]);
        string result = "";
        foreach (data[i])
            result = {result, $sformatf("%02h", data[i])};
        return result;
    endfunction

    /**
     * Resets the internal Keccak state to all zeros.
     */
    local function automatic void reset();
        foreach (state[i]) state[i] = 0;
    endfunction

    //--------------------------------------------------------------------------
    // Core absorb logic (shared by digest_bytes, digest_slice, digest_file)
    //--------------------------------------------------------------------------

    /**
     * Absorbs data[offset .. offset+len) into the state and returns the hex digest.
     * State must already be reset before calling.
     */
    local function automatic string digest_core(
            input byte unsigned data[], input int offset, input int len);
        byte unsigned last_blk[RATE_BYTES];
        int off;
        int remaining;
        int y;
        assert (offset >= 0 && len >= 0 && offset + len <= data.size())
            else $fatal(1, "digest_core: invalid offset=%0d len=%0d size=%0d", offset, len, data.size());
        off = offset;
        while (off + RATE_BYTES <= offset + len) begin
            xor_block(data, off, RATE_BYTES);
            keccak_f();
            off += RATE_BYTES;
        end

        remaining = (offset + len) - off;
        for (y = 0; y < remaining; y++)
            last_blk[y] = data[off + y];

        absorb_final(last_blk, remaining);
        return to_hex(squeeze());
    endfunction

    //--------------------------------------------------------------------------
    // Public API
    //--------------------------------------------------------------------------

    /**
     * Computes SHA3-256 of the entire byte array.
     */
    function automatic string digest_bytes(input byte unsigned data[]);
        reset();
        return digest_core(data, 0, data.size());
    endfunction

    /**
     * Computes SHA3-256 of data[offset .. offset+len).
     * Allows hashing a slice of a larger buffer without copying.
     */
    function automatic string digest_slice(
            input byte unsigned data[], input int offset, input int len);
        reset();
        return digest_core(data, offset, len);
    endfunction

    /**
     * Computes SHA3-256 of the contents of a file.
     * The file is read in binary mode to avoid CR+LF translation on Windows.
     */
    function automatic string digest_file(input string path);
        integer fd;
        byte unsigned blk[RATE_BYTES];
        byte unsigned b;
        int filled;
        filled = 0;
        fd = $fopen(path, "rb");
        if (fd == 0) $fatal(1, "digest_file: cannot open '%s'", path);
        reset();
        while ($fread(b, fd) == 1) begin
            blk[filled++] = b;
            if (filled == RATE_BYTES) begin
                xor_block(blk, 0, RATE_BYTES);
                keccak_f();
                filled = 0;
            end
        end
        $fclose(fd);
        absorb_final(blk, filled);
        return to_hex(squeeze());
    endfunction


endclass : Sha3_256
`endif // SHA3_256_SVH
