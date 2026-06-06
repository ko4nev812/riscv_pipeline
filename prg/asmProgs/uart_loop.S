.text
    # Базовый адрес UART (0x2000_0000)
    lui x20, 0x20000
    
    # Адрес LED_BASE (0x0000_1000)
    lui x21, 0x1

    # Адреса регистров UART
    addi x22, x20, 0x8      # x22 = RXSTATUS_ADDR (0x2000_0008)
    addi x24, x20, 0x0      # x24 = TXSTATUS_ADDR (0x2000_0000)
    addi x25, x20, 0x4      # x25 = TXDATA_ADDR   (0x2000_0004)

loop:
    lbu x3, 0(x22)          # читаем RXSTATUS
    beq x3, x0, loop        # если 0, ждем

    addi x23, x20, 0xC      # x23 = RXDATA_ADDR (0x2000_000C)
    lbu x4, 0(x23)          # x4 = принятый символ

    sw x4, 0(x21)           # показать символ на LED

tx_wait:
    lbu x5, 0(x24)          # читаем TXSTATUS
    beq x5, x0, tx_wait     # если 0, ждем

    sb x4, 0(x25)           # записываем символ в TXDATA

    jal x0, loop            # бесконечный цикл