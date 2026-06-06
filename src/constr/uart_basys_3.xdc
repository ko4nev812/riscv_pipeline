#-------------------------------------------------------------------------------
#    project:       RISC-V (Sber Novosibirsk State University)
#    cfg:           BASYS-3
#
#    description:   
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#    USB-UART
#-------------------------------------------------------------------------------

set_property PACKAGE_PIN B18 [get_ports uart_rxd]
set_property PACKAGE_PIN A18 [get_ports uart_txd]

set_property IOSTANDARD LVCMOS33 [get_ports uart_txd]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rxd]


