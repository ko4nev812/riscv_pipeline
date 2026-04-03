.text
	addi a0,zero,2
	jal adder
	jal adder
	jal adder
	jal adder
	jal adder
	jal end
adder:
	add a0,a0,a0
	jr ra
end:
