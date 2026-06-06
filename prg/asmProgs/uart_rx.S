.text
    # Базовый адрес UART
    lui x20, 0x20000
    
    # Адрес LED_BASE = 0x1000
    lui x21, 0x1          # x21 = 0x1000

    addi x22, x20, 0x8

loop:
    lbu x3, 0(x22)        # читаем статус
    beq x3, x0, loop      # если 0, ждем

    addi x23, x20, 0xC    # x23 = адрес RXDATA

    lbu x4, 0(x23)        # x4 = символ (беззнаковое расширение) - для LED0-LED7

    sw x4, 0(x21)
    jal x0, loop