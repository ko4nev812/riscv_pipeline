#-------------------------------------------------------------------------------
#    project:       RISC-V (Sber Novosibirsk State University)
#    cfg:           BASYS-3
#
#    description:   
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#    configuration options
#-------------------------------------------------------------------------------
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

#-------------------------------------------------------------------------------
#    clocks
#-------------------------------------------------------------------------------

set_property PACKAGE_PIN W5 [get_ports ref_clk]
set_property IOSTANDARD LVCMOS33 [get_ports ref_clk]
#create_clock -add -name ref_clk -period 10.0  [get_ports ref_clk]
#create_clock -name ref_clk -period 10.0  [get_ports ref_clk]
#set_switching_activity -deassert_resets

#-------------------------------------------------------------------------------
#    led
#-------------------------------------------------------------------------------

set_property PACKAGE_PIN U16   [get_ports {led[0]}]
set_property PACKAGE_PIN E19   [get_ports {led[1]}]
set_property PACKAGE_PIN U19   [get_ports {led[2]}]
set_property PACKAGE_PIN V19   [get_ports {led[3]}]

set_property PACKAGE_PIN W18   [get_ports {led[4]}]
set_property PACKAGE_PIN U15   [get_ports {led[5]}]
set_property PACKAGE_PIN U14   [get_ports {led[6]}]
set_property PACKAGE_PIN V14   [get_ports {led[7]}]

set_property PACKAGE_PIN V13   [get_ports {led[8]}]
set_property PACKAGE_PIN V3    [get_ports {led[9]}]
set_property PACKAGE_PIN W3    [get_ports {led[10]}]
set_property PACKAGE_PIN U3    [get_ports {led[11]}]

set_property PACKAGE_PIN P3    [get_ports {led[12]}]
set_property PACKAGE_PIN N3    [get_ports {led[13]}]
set_property PACKAGE_PIN P1    [get_ports {led[14]}]
set_property PACKAGE_PIN L1    [get_ports {led[15]}]

set_property IOSTANDARD LVCMOS33 [get_ports {led}]
#set_property IOB TRUE [get_ports {led}]

#-------------------------------------------------------------------------------
#    Pmod Header JA
#-------------------------------------------------------------------------------

#set_property PACKAGE_PIN J1 [get_ports {dbg_insn_addr[0]}]      ;# Sch name = JA1
#set_property PACKAGE_PIN L2 [get_ports {dbg_insn_addr[1]}]      ;# Sch name = JA2
#set_property PACKAGE_PIN J2 [get_ports {dbg_insn_addr[2]}]      ;# Sch name = JA3
#set_property PACKAGE_PIN G2 [get_ports {dbg_insn_addr[3]}]      ;# Sch name = JA4

#set_property PACKAGE_PIN H1 [get_ports {dbg_insn_funct3[0]}]    ;# Sch name = JA7
#set_property PACKAGE_PIN K2 [get_ports {dbg_insn_funct3[1]}]    ;# Sch name = JA8
#set_property PACKAGE_PIN H2 [get_ports {dbg_insn_funct3[2]}]    ;# Sch name = JA9
#set_property PACKAGE_PIN G3 [get_ports {out_lb_reg[7]}]      ;# Sch name = JA10

#set_property IOSTANDARD LVCMOS33 [get_ports {dbg_insn_addr}]
#set_property IOB TRUE [get_ports {dbg_insn_addr}]
#set_property DRIVE 4 [get_ports [list {dbg_insn_addr}]]
#set_property SLEW SLOW [get_ports [list {dbg_insn_addr}]]

#set_property IOSTANDARD LVCMOS33 [get_ports {dbg_insn_funct3}]
##set_property IOB TRUE [get_ports {dbg_insn_funct3}]
#set_property DRIVE 4 [get_ports [list {dbg_insn_funct3}]]
#set_property SLEW SLOW [get_ports [list {dbg_insn_funct3}]]

#-------------------------------------------------------------------------------
#    Pmod Header JB
#-------------------------------------------------------------------------------

#set_property PACKAGE_PIN A14 [get_ports {dbg_insn_opcode[0]}]      ;# Sch name = JB1
#set_property PACKAGE_PIN A16 [get_ports {dbg_insn_opcode[1]}]      ;# Sch name = JB2
#set_property PACKAGE_PIN B15 [get_ports {dbg_insn_opcode[2]}]      ;# Sch name = JB3
#set_property PACKAGE_PIN B16 [get_ports {dbg_insn_opcode[3]}]      ;# Sch name = JB4
#set_property PACKAGE_PIN A15 [get_ports {dbg_insn_opcode[4]}]      ;# Sch name = JB7
#set_property PACKAGE_PIN A17 [get_ports {dbg_insn_opcode[5]}]      ;# Sch name = JB8
#set_property PACKAGE_PIN C15 [get_ports {dbg_insn_opcode[6]}]      ;# Sch name = JB9
#set_property PACKAGE_PIN C16 [get_ports {data_reg[7]}]      ;# Sch name = JB10

#set_property IOSTANDARD LVCMOS33 [get_ports {dbg_insn_opcode}]
#set_property IOB TRUE [get_ports {dbg_insn_opcode}]
#set_property DRIVE 4 [get_ports [list {dbg_insn_opcode}]]
#set_property SLEW SLOW [get_ports [list {dbg_insn_opcode}]]


#-------------------------------------------------------------------------------
#    Pmod Header JXADC
#-------------------------------------------------------------------------------

#set_property PACKAGE_PIN J3 [get_ports {dbg_clk_vec[0]}]      ;# Sch name = XA1_P
#set_property PACKAGE_PIN L3 [get_ports {dbg_clk_vec[1]}]      ;# Sch name = XA2_P
#set_property PACKAGE_PIN M2 [get_ports {dbg_clk_vec[2]}]      ;# Sch name = XA3_P

#set_property IOSTANDARD LVCMOS33 [get_ports {dbg_clk_vec}]
#set_property DRIVE 4 [get_ports [list {dbg_clk_vec}]]
#set_property SLEW SLOW [get_ports [list {dbg_clk_vec}]]

#set_property PACKAGE_PIN N2 [get_ports {dbg_pll_locked}]      ;# Sch name = XA4_P

#set_property IOSTANDARD LVCMOS33 [get_ports {dbg_pll_locked}]
#set_property DRIVE 4 [get_ports [list {dbg_pll_locked}]]
#set_property SLEW SLOW [get_ports [list {dbg_pll_locked}]]

#-------------------------------------------------------------------------------
#    7-segment display (not used now)
#-------------------------------------------------------------------------------

#set_property PACKAGE_PIN W7    [get_ports {seg[0]}]
#set_property PACKAGE_PIN W6    [get_ports {seg[1]}]
#set_property PACKAGE_PIN U8    [get_ports {seg[2]}]
#set_property PACKAGE_PIN V8    [get_ports {seg[3]}]
#set_property PACKAGE_PIN U5    [get_ports {seg[4]}]
#set_property PACKAGE_PIN V5    [get_ports {seg[5]}]
#set_property PACKAGE_PIN U7    [get_ports {seg[6]}]

#set_property IOSTANDARD LVCMOS33 [get_ports {seg}]
#set_property IOB TRUE [get_ports {seg}]

#set_property PACKAGE_PIN V7      [get_ports dp]
#set_property IOSTANDARD LVCMOS33 [get_ports {dp}]
#set_property IOB TRUE [get_ports {dp}]

#set_property PACKAGE_PIN U2    [get_ports {seg_an[0]}]
#set_property PACKAGE_PIN U4    [get_ports {seg_an[1]}]
#set_property PACKAGE_PIN V4    [get_ports {seg_an[2]}]
#set_property PACKAGE_PIN W4    [get_ports {seg_an[3]}]

#set_property IOSTANDARD LVCMOS33 [get_ports {seg_an}]
#set_property IOB TRUE [get_ports {seg_an}]

#-------------------------------------------------------------------------------
#    switches (not used now)
#-------------------------------------------------------------------------------

#set_property PACKAGE_PIN V17   [get_ports {sw[0]}]
#set_property PACKAGE_PIN V16   [get_ports {sw[1]}]
#set_property PACKAGE_PIN W17   [get_ports {sw[2]}]
#set_property PACKAGE_PIN W17   [get_ports {sw[3]}]

#set_property PACKAGE_PIN W15   [get_ports {sw[4]}]
#set_property PACKAGE_PIN V15   [get_ports {sw[5]}]
#set_property PACKAGE_PIN W14   [get_ports {sw[6]}]
#set_property PACKAGE_PIN W13   [get_ports {sw[7]}]

#set_property PACKAGE_PIN V2    [get_ports {sw[8]}]
#set_property PACKAGE_PIN T3    [get_ports {sw[9]}]
#set_property PACKAGE_PIN T2    [get_ports {sw[10]}]
#set_property PACKAGE_PIN R3    [get_ports {sw[11]}]

#set_property PACKAGE_PIN W2    [get_ports {sw[12]}]
#set_property PACKAGE_PIN U1    [get_ports {sw[13]}]
#set_property PACKAGE_PIN T1    [get_ports {sw[14]}]
#set_property PACKAGE_PIN R2    [get_ports {sw[15]}]

#set_property IOSTANDARD LVCMOS33 [get_ports {sw}]

#-------------------------------------------------------------------------------
#    buttons (not used now)
#
#    btn[0] - 'center'
#    btn[1] - 'up'
#    btn[2] - 'left'
#    btn[3] - 'right'
#    btn[4] - 'down'
#-------------------------------------------------------------------------------

#set_property PACKAGE_PIN U18   [get_ports {btn[0]}]
#set_property PACKAGE_PIN T18   [get_ports {btn[1]}]
#set_property PACKAGE_PIN W19   [get_ports {btn[2]}]
#set_property PACKAGE_PIN T17   [get_ports {btn[3]}]
#set_property PACKAGE_PIN U17   [get_ports {btn[4]}]

#set_property IOSTANDARD LVCMOS33 [get_ports {btn}]


