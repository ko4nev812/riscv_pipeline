.text
li	x10, 0		# в rars заменить на lui	x10, 0x10000

li	x1, 0x12345678	# Тестовое значение 1
li	x2, 0x89ABCDEF	# Тестовое значение 2

sw	x1, 0(x10)
lw	x3, 0(x10)

sw	x2, 4(x10)
lw	x3, 4(x10)

sh	x1, 8(x10)
lh	x3, 8(x10)
lhu	x4, 8(x10)

sh	x2, 12(x10)
lh	x3, 12(x10)
lhu	x4, 12(x10)

sh	x1, 16(x10)
lh	x3, 16(x10)
lhu	x4, 16(x10)

sb	x2, 20(x10)
lb	x3, 20(x10)
lbu	x4, 20(x10)
