#----------------------------------
#	LED BLINKING TEST
#----------------------------------

.eqv DMEM_PORT_ADDR 0x1000
.eqv BLINK_PERIOD 50000000
#.eqv BLINK_PERIOD 2

.text
start:
    li x1, 0
    li x2, DMEM_PORT_ADDR
    li x3, BLINK_PERIOD

loop:
    sw x1, 0(x2)          
    addi x1, x1, 1        
    
    li x4, BLINK_PERIOD

delay:
    addi x4, x4, -1
    bnez x4, delay
    
    j loop
