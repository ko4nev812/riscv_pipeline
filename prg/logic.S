.text
    addi x1, x0, 1
    addi x2, x0, -2
    xor  x3, x1, x2
    addi x4, x0, -1
    bne  x3, x4 bad_halt
    or   x3, x1, x2
    bne  x3, x4 bad_halt
    and  x3, x1, x2
    bne  x3, x0 bad_halt
    addi x1, x0, -2
    addi x2, x0, -4
    xor  x3, x1, x2
    addi x4, x0, 2
    bne  x3, x4 bad_halt
    or   x3, x1, x2
    bne  x3, x1 bad_halt
    and  x3, x1, x2
    bne  x3, x2 bad_halt
halt:
    addi a0, x0, 0
    j halt
bad_halt:
    addi a0, x0, -1
    j bad_halt   
    