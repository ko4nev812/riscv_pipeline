.text
li   x6, 1
li   x7, 0
sb   x6, (x7)
lb   x1, (x7)
li   x2, 2
add  x3, x3, x1
add  x2, x2, x0
sub  x5, x0, x0
xor  x4, x3, x3
addi x2, x0, -1
nop
