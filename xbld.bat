set bld_script="xbld.tcl"
set log_dir="log"

rmdir .Xil
rmdir log
mkdir %log_dir%
vivado -mode batch -journal %log_dir%/bld.jou -log %log_dir%/bld.log -source %bld_script% -notrace