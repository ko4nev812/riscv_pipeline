# test04: знаковое расширение LB (0x80) и LH (0x8000). Буфер 0x80000100.
.globl _start
_start:
        lui     a1, 0x80000
        addi    a1, a1, 0x100

        sb      zero, 0(a1)
        li      t0, 0x80
        sb      t0, 0(a1)
        lb      t1, 0(a1)
        li      t2, 0xFFFFFF80
        bne     t1, t2, fail

        lbu     t1, 0(a1)
        li      t2, 0x80
        bne     t1, t2, fail

        sh      zero, 4(a1)
        li      t0, 0x8000
        sh      t0, 4(a1)
        lh      t1, 4(a1)
        li      t2, 0xFFFF8000
        bne     t1, t2, fail

        lhu     t1, 4(a1)
        li      t2, 0x8000
        bne     t1, t2, fail

        lui     a0, 0x80000
        li      t0, 1
        sw      t0, 0(a0)
pass:   j       pass

fail:
        lui     a0, 0x80000
        li      t0, 2
        sw      t0, 0(a0)
hang:   j       hang
