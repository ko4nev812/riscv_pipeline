puts "=================== create prj"

#---
set build_pll_ip  1
set build_imem_ip 0
set build_tdp_bram_ip 0 ; # TODO: supress warnings about AXI unconnected
set enable_uart 0

set trace_logger_ena   1
set trace_sha3_dpi_ena 1

#---
set prjName rv-nsu
set prjFPGA xc7a35tcpg236-1     ;# BASYS-3
#set prjFPGA xc7a35ticsg324-1L  ;# ARTY

set current_dir [pwd]
#puts "current_dir: $current_dir"

set prjDir   "$current_dir"
set cfgDir   "$prjDir/cfg"
set constDir "$prjDir/src/constr"
set ipDir    "$prjDir/ip"
set libDir   "$prjDir/lib"
set rtlDir   "$prjDir/src/rtl"
set simDir   "$prjDir/src/sim"

#---
set tempDir "$prjDir/temp_cfg_backup"
file mkdir $tempDir
foreach f [glob -nocomplain $cfgDir/*.wcfg] {
    file copy -force $f $tempDir
}

#---
file delete -force $cfgDir
file mkdir $cfgDir
create_project $prjName $cfgDir -part $prjFPGA

set init_def_file [file join $cfgDir mem_init_path.svh]
set prgDir [file join $prjDir prg]

set fh [open $init_def_file w]
puts $fh "\`ifndef MEM_INIT_PATH_SVH"
puts $fh "\`define MEM_INIT_PATH_SVH"
puts $fh ""
puts $fh "//==== IMEM part"
puts $fh "// Available IMEM images - uncomment ONE to use:"

# Find all .mem files in prg directory and write commented defines
foreach memFile [glob -nocomplain [file join $prgDir *.mem]] {
    set memPathNormalized [file normalize $memFile]
    # Write commented define for easy switching between images
    puts $fh "//\`define IMEM_INIT_FILE \"$memPathNormalized\""
}

# Default IMEM and DMEM images if none selected above
puts $fh ""
puts $fh "// Default IMEM image (used if IMEM_INIT_FILE is not defined above)"
puts $fh "\`ifndef IMEM_INIT_FILE"
puts $fh "\`define IMEM_INIT_FILE \"[file normalize [file join $prgDir default.mem]]\""
puts $fh "\`endif  // IMEM_INIT_FILE"

puts $fh ""
puts $fh "//==== DMEM part"
puts $fh "\`define DMEM_INIT_FILE \"\""
puts $fh ""
puts $fh "\`endif  // MEM_INIT_PATH_SVH"

if $enable_uart {
    puts $fh "\`ifndef UART_ENABLE"
    puts $fh "\`define UART_ENABLE"
    puts $fh "\`endif"
}

close $fh

puts "Generated IMEM init defines for all .mem files in $prgDir"

set trace_cfg_file [file join $cfgDir trace_config.svh]
set trace_test_dir [string map {\\ /} [file normalize [file join $prjDir prg uBench hex]]]
file mkdir [file join $trace_test_dir res]

set fh [open $trace_cfg_file w]
puts $fh "\`ifndef TRACE_CONFIG_SVH"
puts $fh "\`define TRACE_CONFIG_SVH"
puts $fh ""
puts $fh "//==== Trace Logger"
puts $fh "// Comment TRACE_LOGGER_ENA to disable the test trace runner."
if {$trace_logger_ena} {
    puts $fh "\`define TRACE_LOGGER_ENA"
} else {
    puts $fh "//\`define TRACE_LOGGER_ENA"
}
puts $fh "\`define TRACE_TEST_DIR \"$trace_test_dir\""
puts $fh "\`define TRACE_TEST_LST \"ub.lst\""
puts $fh ""
puts $fh "//==== SHA3 DPI"
puts $fh "// Comment TRACE_SHA3_DPI_ENA to keep TraceLogger but remove the SHA3 column."
if {$trace_sha3_dpi_ena} {
    puts $fh "\`define TRACE_SHA3_DPI_ENA"
} else {
    puts $fh "//\`define TRACE_SHA3_DPI_ENA"
}
puts $fh ""
puts $fh "\`endif  // TRACE_CONFIG_SVH"
close $fh

puts "Generated trace config: $trace_cfg_file"

set sha3_dpi_xsc_pre_tcl [file join $cfgDir sha3_dpi_xsc_pre.tcl]
set sha3_dpi_cpp [file normalize [file join $simDir sha3_dpi.cpp]]

set fh [open $sha3_dpi_xsc_pre_tcl w]
puts $fh {puts "=== SHA3 DPI: compile C++ with xsc"}
puts $fh {set xsc_cmd [auto_execok xsc]}
puts $fh {if {$xsc_cmd eq ""} { set xsc_cmd [auto_execok xsc.bat] }}
puts $fh {if {$xsc_cmd eq ""} { error "SHA3 DPI: xsc was not found in PATH" }}
puts $fh "exec {*}\$xsc_cmd --cppversion 11 -o sha3_dpi \"$sha3_dpi_cpp\""
close $fh


set rtl_dirs [list \
    "$rtlDir" \
    "$rtlDir/modules" \
    "$rtlDir/stages" \
]

set rtl_files {}
foreach dir $rtl_dirs {
    set files [glob -nocomplain -directory $dir *.sv *.v]
    set rtl_files [concat $rtl_files $files]
}

if {[llength $rtl_files] > 0} {
    add_files -fileset sources_1 $rtl_files
}

add_files -fileset sources_1              \
         $libDir/pf.sv                    \
         $libDir/dual_port_mem.sv         \
         $init_def_file

add_files -fileset constrs_1 \
         $constDir/rv_nsu_basys_3.sdc \
         $constDir/rv_nsu_basys_3.xdc

if $enable_uart {
    add_files -fileset sources_1              \
             $rtlDir/uart_wrapper.sv          \
             $libDir/uart.sv

    add_files -fileset constrs_1 $constDir/uart_basys_3.xdc
}

#add_files -fileset constrs_1 [file join $constDir "rv_nsu_basys_3.tcl"]
#set_property FILE_TYPE {TCL} [get_files [file join $constDir "rv_nsu_basys_3.tcl"]]

add_files -fileset sim_1  \
         $simDir/rv_nsu_tb.sv \
         $trace_cfg_file \
         $simDir/sha3_dpi.cpp
set_property file_type {CPP} [get_files $simDir/sha3_dpi.cpp]

foreach f [glob -nocomplain $tempDir/*.wcfg] {
    set dest [file join $cfgDir [file tail $f]]
    file copy -force $f $dest
    add_files -fileset sim_1 $dest
}

file delete -force $tempDir  # file mkdir $tempDir

set_property INCLUDE_DIRS "$rtlDir $simDir $cfgDir" [get_filesets sim_1]
set_property used_in_synthesis      false [get_files  $simDir/rv_nsu_tb.sv]
set_property used_in_implementation false [get_files  $simDir/rv_nsu_tb.sv]
set_property top rv_nsu_tb [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {1000us} -objects [get_filesets sim_1]

#--- DPI settings
set_property -name {xsim.compile.tcl.pre} \
    -value $sha3_dpi_xsc_pre_tcl \
    -objects [get_filesets sim_1]

set_property -name {xsim.elaborate.xelab.more_options} \
    -value {--sv_lib sha3_dpi} \
    -objects [get_filesets sim_1]

puts "=================== create IP's"

set_msg_config -suppress -id {Common 17-576}

#--- IP (pll)
if $build_pll_ip {
    puts "\n------------------- create PLL IP"
    set ip_pll_name   "pll"
    set ip_pll_clk    50.0
    set ip_pll_phase2 45.0
    set ip_pll_phase3 200.0

    puts "\n------------------- Update TIME_BASE for UART"

    set time_base_ns [expr {int(1000.0 / $ip_pll_clk)}]

    if {$time_base_ns < 1.0} {
        puts "  WARNING: Clock frequency > 1000 MHz ($ip_pll_clk MHz)"
        puts "  TIME_BASE would be < 1 ns, using 1 ns"
        set time_base_value 1
    }

    puts "  PLL Clock: $ip_pll_clk MHz"
    puts "  TIME_BASE: $time_base_ns ns"

    set svh_file "$rtlDir/risc-v.svh"
    if {[file exists $svh_file]} {
        set fp [open $svh_file r]
        set content [read $fp]
        close $fp
    
        regsub -all {RV_TIME_BASE\s*=\s*\d+} $content "RV_TIME_BASE  = $time_base_ns" content
    
        set fp [open $svh_file w]
        puts $fp $content
        close $fp
    
        puts "  Updated $svh_file"
    } else {
        puts "  ERROR: $svh_file not found!"
    }

    file mkdir $ipDir
    set ip_pll_dir "$ipDir/$ip_pll_name"
    file delete -force $ip_pll_dir

    create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name $ip_pll_name -dir $ipDir
    set_property -dict [ \
                        list CONFIG.Component_Name $ip_pll_name        \
                        CONFIG.PRIMITIVE {PLL}                         \
                        CONFIG.CLKOUT2_USED {true}                     \
                        CONFIG.CLKOUT3_USED {true}                     \
                        CONFIG.PRIMARY_PORT {clk_in}                   \
                        CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $ip_pll_clk  \
                        CONFIG.CLKOUT2_REQUESTED_OUT_FREQ $ip_pll_clk  \
                        CONFIG.CLKOUT2_REQUESTED_PHASE $ip_pll_phase2  \
                        CONFIG.CLKOUT3_REQUESTED_OUT_FREQ $ip_pll_clk  \
                        CONFIG.CLKOUT3_REQUESTED_PHASE $ip_pll_phase3  \
                        CONFIG.USE_RESET {false}                       \
                        ] [get_ips $ip_pll_name]

    generate_target {instantiation_template} [get_files $ip_pll_dir/$ip_pll_name.xci]
    update_compile_order -fileset sources_1
    generate_target all [get_files  $ip_pll_dir/$ip_pll_name.xci]
    catch { config_ip_cache -export [get_ips -all $ip_pll_name] }
    export_ip_user_files -of_objects [get_files $ip_pll_dir/$ip_pll_name.xci] -no_script -sync -force -quiet
    create_ip_run [get_files -of_objects [get_fileset sources_1] $ip_pll_dir/$ip_pll_name.xci]

    #---
    launch_runs -jobs 4 ${ip_pll_name}_synth_1
    wait_on_run ${ip_pll_name}_synth_1
}

#--- IP (Simple Dual-Port Block RAM)
if $build_imem_ip {
    puts "\n------------------- create Simple_Dual_Port_RAM IP"
    set ip_imem_name "blk_mem_sdp"
    set bitWidth 32
    set memDepth 1024

    file mkdir $ipDir
    set ip_imem_dir "$ipDir/$ip_imem_name"
    file delete -force $ip_imem_dir

    create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name $ip_imem_name -dir $ipDir
    set_property -dict [ \
        list CONFIG.Component_Name {blk_mem_sdp}   \
        CONFIG.Memory_Type {Simple_Dual_Port_RAM}  \
        CONFIG.Assume_Synchronous_Clk {true}       \
        CONFIG.Write_Width_A $bitWidth             \
        CONFIG.Write_Depth_A $memDepth             \
        CONFIG.Read_Width_A  $bitWidth             \
        CONFIG.Operating_Mode_A {READ_FIRST}       \
        CONFIG.Write_Width_B $bitWidth             \
        CONFIG.Read_Width_B $bitWidth              \
        CONFIG.Operating_Mode_B {READ_FIRST}       \
        CONFIG.Enable_B {Use_ENB_Pin}              \
        CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
        CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
        CONFIG.Load_Init_File {false} \
        CONFIG.Fill_Remaining_Memory_Locations {true} \
        CONFIG.Remaining_Memory_Locations {800000ec} \
        CONFIG.Port_B_Clock {100} \
        CONFIG.Port_B_Enable_Rate {100} \
        ] [get_ips $ip_imem_name]

    generate_target {instantiation_template} [get_files $ip_imem_dir/$ip_imem_name.xci]
    update_compile_order -fileset sources_1
    generate_target all [get_files  $ip_imem_dir/$ip_imem_name.xci]
    catch { config_ip_cache -export [get_ips -all $ip_imem_name] }
    export_ip_user_files -of_objects [get_files $ip_imem_dir/$ip_imem_name.xci] -no_script -sync -force -quiet
    create_ip_run [get_files -of_objects [get_fileset sources_1] $ip_imem_dir/$ip_imem_name.xci]

    #---
    set_msg_config -suppress -id {Synth 8-3331} -string {blk_mem_output_block}
    set_msg_config -suppress -id {Synth 8-3331} -string {blk_mem_gen_prim_wrapper_init}
    set_msg_config -suppress -id {Synth 8-3331} -string {blk_mem_gen_generic_cstr}
    set_msg_config -suppress -id {Synth 8-3331} -string {blk_mem_input_block}

    #---
    launch_runs ${ip_imem_name}_synth_1 -jobs 4
    wait_on_run ${ip_imem_name}_synth_1

    #---
    reset_msg_config -suppress -id {Synth 8-3331}
}

#--- IP (True Dual-Port Block RAM)
if $build_tdp_bram_ip {
    puts "\n------------------- create True_Dual_Port_RAM IP"
    set ip_imem_name "tdp_bram_ip"
    set bitWidth 32
    set byteSize 8
    set memDepth 1024

    file mkdir $ipDir
    set ip_imem_dir "$ipDir/$ip_imem_name"
    file delete -force $ip_imem_dir

    create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name $ip_imem_name -dir $ipDir
    set_property -dict [ \
        list CONFIG.Component_Name {tdp_bram_ip}                  \
        CONFIG.Memory_Type {True_Dual_Port_RAM}                   \
        CONFIG.Use_Byte_Write_Enable {true}                       \
        CONFIG.Byte_Size     $byteSize                            \
        CONFIG.Write_Width_A $bitWidth                            \
        CONFIG.Write_Depth_A $memDepth                            \
        CONFIG.Read_Width_A  $bitWidth                            \
        CONFIG.Operating_Mode_A {READ_FIRST}                      \
        CONFIG.Enable_A {Use_ENA_Pin}                             \
        CONFIG.Write_Width_B $bitWidth                            \
        CONFIG.Read_Width_B $bitWidth                             \
        CONFIG.Operating_Mode_B {READ_FIRST}                      \
        CONFIG.Enable_B {Use_ENB_Pin}                             \
        CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
        CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
        CONFIG.Fill_Remaining_Memory_Locations {true}             \
        CONFIG.Port_B_Clock {100}                                 \
        CONFIG.Port_B_Write_Rate {50}                             \
        CONFIG.Port_B_Enable_Rate {100}                           \
    ] [get_ips $ip_imem_name]

    generate_target {instantiation_template} [get_files $ip_imem_dir/$ip_imem_name.xci]
    update_compile_order -fileset sources_1
    generate_target all [get_files  $ip_imem_dir/$ip_imem_name.xci]
    catch { config_ip_cache -export [get_ips -all $ip_imem_name] }
    export_ip_user_files -of_objects [get_files $ip_imem_dir/$ip_imem_name.xci] -no_script -sync -force -quiet
    create_ip_run [get_files -of_objects [get_fileset sources_1] $ip_imem_dir/$ip_imem_name.xci]

    #---
    set_msg_config -suppress -id {Synth 8-3331}
    #set_msg_config -suppress -id {Synth 8-3331} -string {blk_mem_output_block}
    #set_msg_config -suppress -id {Synth 8-3331} -string {blk_mem_gen_prim_wrapper_init}
    #set_msg_config -suppress -id {Synth 8-3331} -string {blk_mem_gen_generic_cstr}
    #set_msg_config -suppress -id {Synth 8-3331} -string {blk_mem_input_block}

    #---
    launch_runs ${ip_imem_name}_synth_1 -jobs 4
    wait_on_run ${ip_imem_name}_synth_1

    #---
    reset_msg_config -suppress -id {Synth 8-3331}
}    
