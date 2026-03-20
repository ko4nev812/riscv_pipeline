puts "=================== create prj"

#---
set build_pll_ip  1
set build_imem_ip 0

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

set imem_mem_path [file normalize [file join $prjDir prg imem.mem]]
set init_def_file [file join $cfgDir imem_init_path.svh]

set fh [open $init_def_file w]
puts $fh "\`ifndef IMEM_INIT_PATH_SVH"
puts $fh "\`define IMEM_INIT_PATH_SVH"
puts $fh "\`define IMEM_INIT_FILE \"$imem_mem_path\""
puts $fh "\`define DMEM_INIT_FILE \"\""
puts $fh "\`endif"
close $fh

puts "Generated IMEM init path: $imem_mem_path"

add_files -fileset sources_1        \
         $rtlDir/cpu_system.sv      \
         $rtlDir/cpu_core.sv        \
         $rtlDir/pc.sv              \
         $rtlDir/id.sv              \
         $rtlDir/branch_unit_m.sv   \
         $rtlDir/imem_sim_m.sv      \
         $rtlDir/dmem.sv            \
         $rtlDir/imm_gen.sv         \
         $rtlDir/register_file.sv   \
         $rtlDir/alu.sv             \
         $rtlDir/shifter_alu.sv     \
         $libDir/pf.sv              \
         $init_def_file
add_files -fileset constrs_1 \
         $constDir/rv_nsu_basys_3.xdc \
         $constDir/rv_nsu_basys_3.sdc

add_files -fileset sim_1  \
         $simDir/rv_nsu_tb.sv

foreach f [glob -nocomplain $tempDir/*.wcfg] {
    set dest [file join $cfgDir [file tail $f]]
    file copy -force $f $dest
    add_files -fileset sim_1 $dest
}

file delete -force $tempDir  # file mkdir $tempDir

set_property INCLUDE_DIRS "$rtlDir $cfgDir" [get_filesets sim_1]
set_property used_in_synthesis      false [get_files  $simDir/rv_nsu_tb.sv]
set_property used_in_implementation false [get_files  $simDir/rv_nsu_tb.sv]
set_property top rv_nsu_tb [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {1000us} -objects [get_filesets sim_1]

puts "=================== create IP's"

set_msg_config -suppress -id {Common 17-576}

#--- IP (pll)
if $build_pll_ip {
    puts "\n------------------- create PLL IP"
    set ip_pll_name   "pll"
    set ip_pll_clk    10.0
    set ip_pll_phase2 45.0
    set ip_pll_phase3 90.0

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
    set Coe_File "$prjDir/imem.hex"
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
        CONFIG.Load_Init_File {true} \
        CONFIG.Coe_File  $Coe_File \
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
