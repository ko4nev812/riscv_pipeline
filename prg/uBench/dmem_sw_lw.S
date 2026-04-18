# test01: SW / LW одного слова. RAM 0x80000000, буфер 0x80000100.
.globl _start
_start:
        lui     a1, 0x80000
        addi    a1, a1, 0x100

        li      t0, 0x11223344
        sw      t0, 0(a1)
        lw      t1, 0(a1)
        bne     t0, t1, fail

        lui     a0, 0x80000
        li      t0, 1
        sw      t0, 0(a0)
pass:   j       pass

fail:
        lui     a0, 0x80000
        li      t0, 2
        sw      t0, 0(a0)
hang:   j       hang
