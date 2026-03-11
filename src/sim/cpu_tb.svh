//------------------------------------------------------------------------------
// project:        RISC-V (SberLab Novosibirsk State University)                                                    
// package:        tb_pkg                                         
//                                                                              
// description:    testbench utilities
//------------------------------------------------------------------------------

`ifndef TB_SVH
`define TB_SVH

//******************************************************************************
//******************************************************************************

//------------------------------------------------------------------------------
package tb_pkg;

    //--------------------------------------------------------------------------
    
    const longint unsigned TimeScale = 1000; // 1ns = 1000ps

    //--------------------------------------------------------------------------
    task automatic clk_control(input real clk_period, ref logic clk);
        //---
        real clk_half_period = (clk_period*TimeScale)/2;
        real clk_offset = 0;

        clk_offset *= TimeScale;

        //---
        begin : ClkGen
            clk = 0;
            #clk_offset;
            forever #clk_half_period clk = ~clk;
        end : ClkGen
    endtask : clk_control

    //--------------------------------------------------------------------------
    task automatic stop_info(input string stop_condition);
            $write("\n");
            $write("------------------------------------------------------\n");
            $write("[INFO] simulation stop\n");
            $write("       stop condition: %20s\n", stop_condition);
            $timeformat(-9,0," ns");
            $write("       stop time:      %20t\n",$time);
            $write("------------------------------------------------------\n");
            $write("\n");
    endtask : stop_info

    //--------------------------------------------------------------------------
    task automatic stop_signal_control(const ref logic stop_signal, input longint unsigned epilogue_time = 100);
        //---
        const longint unsigned EpilogueTime = epilogue_time*TimeScale;
    
        //---
        begin : StopSignal
            wait(stop_signal) begin
            #EpilogueTime;
            stop_info("stop signal");
            end
        end : StopSignal
    endtask : stop_signal_control

    //--------------------------------------------------------------------------
    task automatic stop_time_control(input longint unsigned stop_time = 1000);
        //---
        stop_time *= TimeScale;
        
        //---
        begin : StopTime
            #stop_time;
            stop_info("stop time");
        end : StopTime
    endtask : stop_time_control

    //--------------------------------------------------------------------------
    task automatic gen_pulse(const ref logic clk, ref logic x, input longint unsigned set_time, input longint unsigned duration_time = 1);
        begin
            x = 0;
            repeat (set_time) begin
                @(posedge clk);
            end
            x = 1;
            if(duration_time) begin
                repeat (duration_time) begin
                    @(posedge clk);
                end
                x = 0;
            end
        end
    endtask : gen_pulse
    
endpackage : tb_pkg

`endif // TB_SVH
