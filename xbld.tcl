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

set prjDir        "$current_dir"
set cfgDir        "$prjDir/cfg"
set ipDir         "$prjDir/ip"
set libDir        "$prjDir/lib"
set srcDir        "$prjDir/src"
set constrDir     "$srcDir/constr"
set rtlDir        "$srcDir/rtl"
set simDir        "$srcDir/sim"
set featuresDir   "$prjDir/features"

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
puts $fh "\`endif"
close $fh


# Copy features
set source_dirs [list "alu_shifter" "branch_unit" "id" "imem" "imm_gen" "pc" "rf" "cpu"]

file delete -force $srcDir
file mkdir $srcDir

foreach feature $source_dirs {
    puts "Parsing files in $feature:"
    set dir "$featuresDir/$feature/src"
    if {[file isdirectory $dir]} {
        set subdirs [glob -nocomplain -type d [file join $dir "*"]]
        
        foreach subdir $subdirs {
            set subdir_name [file tail $subdir]
            set dest_subdir [file join $srcDir $subdir_name]
            
            # Создаем подпапку в назначении
            file mkdir $dest_subdir
            
            # Копируем все файлы из подпапки с заменой
            set files [glob -nocomplain -type f [file join $subdir "*"]]
            foreach file $files {
                set filename [file tail $file]
                if {[string match "*.svh" $filename] && $feature != "cpu"} {
                    # Формируем новое имя с префиксом $feature_
                    set new_filename "$feature\_$filename"
                    set dest_path [file join $dest_subdir $new_filename]
            
                    file copy -force $file $dest_path
                    puts "\tCopying header file: $file -> $dest_path"
                } else {
                    puts "\tCopying source file $file -> $dest_subdir"
                    file copy -force $file $dest_subdir
                }       
            }
        }
    }
    puts "\n"
}

#---------

puts "Generated IMEM init path: $imem_mem_path"

# SV files:
set rtl_files [list]    
set sv_files [glob -nocomplain -type f $rtlDir/*.sv]
set rtl_files [concat $rtl_files $sv_files  $init_def_file]
if {[llength $rtl_files] > 0} {
    add_files -fileset sources_1 $rtl_files
} else {
    error "No *.sv files were found in $rtlDir dir"
}

# Constraint files:
set constr_files [glob -nocomplain -type f $constrDir/*.*dc]
if {[llength $constr_files] > 0} {
    add_files -fileset constrs_1 $constr_files
} else {
    error "No constraint files were found in $constrDir dir"
}

# Sim files:
set sim_files [glob -nocomplain -type f $simDir/*.sv]
if {[llength $sim_files] > 0} {
    add_files -fileset sim_1 $sim_files
} else {
    error "No constraint files were found in $simDir dir"
}


set_property INCLUDE_DIRS $rtlDir [get_filesets sim_1]
set_property used_in_synthesis      false [get_files  $simDir/rv_nsu_tb.sv]
set_property used_in_implementation false [get_files  $simDir/rv_nsu_tb.sv]
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
