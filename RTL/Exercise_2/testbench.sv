// file: log_pkg.sv
package log_pkg;
  integer tb_log_fd;
endpackage

import round_pkg::*;
import multiplication_pkg::*;
import log_pkg::*;

module testbench;

    // Enum for corner cases 
    typedef enum logic [3:0]{
        neg_sgl_NaN=4'b0000,
        pos_sgl_NaN=4'b0001, 
        neg_quiet_NaN=4'b0010, 
        pos_quiet_NaN=4'b0011,
        neg_inf=4'b0100, 
        pos_inf=4'b0101, 
        neg_norm=4'b0110, 
        pos_norm=4'b0111,
        neg_denorm=4'b1000,
        pos_denorm=4'b1001,
        neg_zero=4'b1010,
        pos_zero=4'b1011} corner_case;
     
    // Function for matching corner cases with their binary value
    function [31:0] match_cs_to_bin(input corner_case cs);

        logic [31:0] c, result;
        c = $urandom();
        case(cs)
            neg_sgl_NaN: result = {1'b1,{8{1'b1}},1'b0,c[21:0]};
            pos_sgl_NaN: result = {1'b0,{8{1'b1}},1'b0,c[21:0]};
            neg_quiet_NaN: result = {1'b1,{8{1'b1}},1'b1,c[21:0]};
            pos_quiet_NaN: result = {1'b0,{8{1'b1}},1'b1,c[21:0]};
            neg_inf: result = {1'b1, {8{1'b1}}, {23{1'b0}}};
            pos_inf: result = {1'b0, {8{1'b1}}, {23{1'b0}}};
            neg_norm: result = {1'b1, c[30:0]};
            pos_norm: result = {1'b0, c[30:0]};
            neg_denorm: result = {1'b1, {8{1'b0}}, c[22:0]};
            pos_denorm: result = {1'b0, {8{1'b0}}, c[22:0]};
            neg_zero: result = {1'b1, {8{1'b0}}, {23{1'b0}}};
            pos_zero: result = {1'b0, {8{1'b0}}, {23{1'b0}}};
        endcase
            
      return result;
    endfunction
    
    // Define struct for logging expected results for alignment with multiplier outputs
    typedef struct{
        logic [31:0] expected_result;
        logic [31:0] a;
        logic [31:0] b;
        string mode;
    } result_entry_t;

    result_entry_t result_queue[$]; // Queue to hold results for 3-cycle delay
    result_entry_t refer;
    result_entry_t entry;

    // First half :
    // Define clk, rst, rnd, a, b
    
    logic clk;
    logic rst;
    logic [2:0] rnd;
    logic [31:0] a, b; 
    logic [31:0] z;
    logic [7:0] status;
    logic enable;
    string str;
    corner_case arg_a, arg_b;
     
    // Instantiate "fp_mult_top"
    fp_mult_top u4(.clk(clk), .rst(rst),.rnd(rnd),.a(a),.b(b),.z(z),.status(status));

    // Bind assertions module
    bind fp_mult_top test_status_bits binding(.status(status));
    bind fp_mult_top test_status_z_combinations binding_2(.clk(clk),.status(status),.z(z),.a(a),.b(b));

    // Implement clock toggling
    always #5 clk = ~clk;

    initial
    begin
        
        $display("===========Assertions===========");

        tb_log_fd = $fopen("testbench_log.txt", "w");

        // First half:
        $fdisplay(tb_log_fd,"\n\n First Half");
        enable=1;

        // "IEEE_near"
        $fdisplay(tb_log_fd,"\n\nRounding Case : IEEE_near");
        $fdisplay(tb_log_fd,"==================================================================================================================");
        clk=1;
        rst = 1'b0;
        str = "IEEE_near";
        rnd = 3'b000;
        #11 rst = 1'b1;

        // "IEEE_zero"
        #490 $fdisplay(tb_log_fd,"\n\nRounding Case : IEEE_zero");
        $fdisplay(tb_log_fd,"==================================================================================================================");
        result_queue.delete();
        rst = 1'b0;
        str = "IEEE_zero";
        rnd = 3'b001;
        #10 rst = 1'b1;
        
        // "IEEE_pinf"
        #490 $fdisplay(tb_log_fd,"\n\nRounding Case : IEEE_pinf");
        $fdisplay(tb_log_fd,"==================================================================================================================");
        result_queue.delete();
        rst = 1'b0;
        str = "IEEE_pinf";
        rnd = 3'b010;
        #10 rst = 1'b1;

        // "IEEE_ninf"
        #490 $fdisplay(tb_log_fd,"\n\nRounding Case : IEEE_ninf");
        $fdisplay(tb_log_fd,"==================================================================================================================");
        result_queue.delete();
        rst = 1'b0;
        str = "IEEE_ninf";
        rnd = 3'b011;
        #10 rst = 1'b1;

        // "near_up"
        #490 $fdisplay(tb_log_fd,"\n\nRounding Case : near_up");
        $fdisplay(tb_log_fd,"==================================================================================================================");
        result_queue.delete();
        rst = 1'b0;
        str = "near_up";
        rnd = 3'b100;
        #10 rst = 1'b1;

        // "away_zero"
        #490 $fdisplay(tb_log_fd,"\n\nRounding Case : away_zero");
        $fdisplay(tb_log_fd,"==================================================================================================================");
        result_queue.delete();
        rst = 1'b0;
        str = "away_zero";
        rnd = 3'b101;
        #10 rst = 1'b1;
        
        // Second half:
               
        #490 enable=0;
        $fdisplay(tb_log_fd,"\n\n Second Half");
        result_queue.delete();
        rst = 1'b0;
        str = "IEEE_near";
        rnd = 3'b110;
        #10 rst = 1'b1;

        // Combinations for negative signaling NaN
        $fdisplay(tb_log_fd,"\n\n Combinations for negative signaling NaN");
        
        // Negative signaling NaN and Negative signaling NaN
        #9 arg_a = neg_sgl_NaN;
        arg_b = neg_sgl_NaN;   

        // Negative signaling NaN and Positive signaling NaN
        #10 arg_a = neg_sgl_NaN;
        arg_b = pos_sgl_NaN;

        // Negative signaling NaN and Negative quiet NaN
        #10 arg_a = neg_sgl_NaN;
        arg_b = neg_quiet_NaN; 

        // Negative signaling NaN and Positive quiet NaN
        #10 arg_a = neg_sgl_NaN;
        arg_b = pos_quiet_NaN;

        // Negative signaling NaN and Negative Infinity
        #10 arg_a = neg_sgl_NaN;
        arg_b = neg_inf;

        // Negative signaling NaN and Positive Infinity
        #10 arg_a = neg_sgl_NaN;
        arg_b = pos_inf;

        // Negative signaling NaN and Negative Normal
        #10 arg_a = neg_sgl_NaN;
        arg_b = neg_norm;

        // Negative signaling NaN and Positive Normal
        #10 arg_a = neg_sgl_NaN;
        arg_b = pos_norm;

        // Negative signaling NaN and Negative Denormal
        #10 arg_a = neg_sgl_NaN;
        arg_b = neg_norm;

        // Negative signaling NaN and Positive Denormal
        #10 arg_a = neg_sgl_NaN;
        arg_b = pos_norm;

        // Negative signaling NaN and Negative Zero
        #10 arg_a = neg_sgl_NaN;
        arg_b = neg_zero;

        // Negative signaling NaN and Positive Zero
        #10 arg_a = neg_sgl_NaN;
        arg_b = pos_zero;


        // Reset
        #50 result_queue.delete();
        rst = 1'b0;
        str = "IEEE_near";
        rnd = 3'b110;
        #11 rst = 1'b1;

        // Combinations for positive signaling NaN
        $fdisplay(tb_log_fd,"\n\n Combinations for positive signaling NaN");
        
        // Negative Signaling NaN and Negative signaling NaN
        #9 arg_a = pos_sgl_NaN;
        arg_b = neg_sgl_NaN;   

        // Negative Signaling NaN and Positive signaling NaN
        #10 arg_a = pos_sgl_NaN;
        arg_b = pos_sgl_NaN;

        // Negative Signaling NaN and Negative quiet NaN
        #10 arg_a = pos_sgl_NaN;
        arg_b = neg_quiet_NaN; 

        // Negative Signaling NaN and Positive quiet NaN
        #10 arg_a = pos_sgl_NaN;
        arg_b = pos_quiet_NaN;

        // Negative Signaling NaN and Negative Infinity
        #10 arg_a = pos_sgl_NaN;
        arg_b = neg_inf;

        // Negative Signaling NaN and Positive Infinity
        #10 arg_a = pos_sgl_NaN;
        arg_b = pos_inf;

        // Negative Signaling NaN and Negative Normal
        #10 arg_a = pos_sgl_NaN;
        arg_b = neg_norm;

        // Negative Signaling NaN and Positive Normal
        #10 arg_a = pos_sgl_NaN;
        arg_b = pos_norm;

        // Negative Signaling NaN and Negative Denormal
        #10 arg_a = pos_sgl_NaN;
        arg_b = neg_norm;

        // Negative Signaling NaN and Positive Denormal
        #10 arg_a = pos_sgl_NaN;
        arg_b = pos_norm;

        // Negative Signaling NaN and Negative Zero
        #10 arg_a = pos_sgl_NaN;
        arg_b = neg_zero;

        // Negative Signaling NaN and Positive Zero
        #10 arg_a = pos_sgl_NaN;
        arg_b = pos_zero;

        
        // Reset
        #50 result_queue.delete();
        rst = 1'b0;
        str = "IEEE_near";
        rnd = 3'b110;
        #11 rst = 1'b1;

        // Combinations for negative quiet NaN
        $fdisplay(tb_log_fd,"\n\n Combinations for negative quiet NaN");
        
        // Negative Quiet NaN and Negative signaling NaN
        #9 arg_a = neg_quiet_NaN;
        arg_b = neg_sgl_NaN;   

        // Negative Quiet NaN and Positive signaling NaN
        #10 arg_a = neg_quiet_NaN;
        arg_b = pos_sgl_NaN;

        // Negative Quiet NaN and Negative quiet NaN
        #10 arg_a = neg_quiet_NaN;
        arg_b = neg_quiet_NaN; 

        // Negative Quiet NaN and Positive quiet NaN
        #10 arg_a = neg_quiet_NaN;
        arg_b = pos_quiet_NaN;

        // Negative Quiet NaN and Negative Infinity
        #10 arg_a = neg_quiet_NaN;
        arg_b = neg_inf;

        // Negative Quiet NaN and Positive Infinity
        #10 arg_a = neg_quiet_NaN;
        arg_b = pos_inf;

        // Negative Quiet NaN and Negative Normal
        #10 arg_a = neg_quiet_NaN;
        arg_b = neg_norm;

        // Negative Quiet NaN and Positive Normal
        #10 arg_a = neg_quiet_NaN;
        arg_b = pos_norm;

        // Negative Quiet NaN and Negative Denormal
        #10 arg_a = neg_quiet_NaN;
        arg_b = neg_norm;

        // Negative Quiet NaN and Positive Denormal
        #10 arg_a = neg_quiet_NaN;
        arg_b = pos_norm;

        // Negative Quiet NaN and Negative Zero
        #10 arg_a = neg_quiet_NaN;
        arg_b = neg_zero;

        // Negative Quiet NaN and Positive Zero
        #10 arg_a = neg_quiet_NaN;
        arg_b = pos_zero;

        // Reset
        #50 result_queue.delete();
        rst = 1'b0;
        str = "IEEE_near";
        rnd = 3'b110;
        #11 rst = 1'b1;

        // Combinations for positive quiet NaN
        $fdisplay(tb_log_fd,"\n\n Combinations for positive quiet NaN");
        
        // Positive Quiet NaN and Negative signaling NaN
        #9 arg_a = pos_quiet_NaN;
        arg_b = neg_sgl_NaN;   

        // Positive Quiet NaN and Positive signaling NaN
        #10 arg_a = pos_quiet_NaN;
        arg_b = pos_sgl_NaN;

        // Positive Quiet NaN and Negative quiet NaN
        #10 arg_a = pos_quiet_NaN;
        arg_b = neg_quiet_NaN; 

        // Positive Quiet NaN and Positive quiet NaN
        #10 arg_a = pos_quiet_NaN;
        arg_b = pos_quiet_NaN;

        // Positive Quiet NaN and Negative Infinity
        #10 arg_a = pos_quiet_NaN;
        arg_b = neg_inf;

        // Positive Quiet NaN and Positive Infinity
        #10 arg_a = pos_quiet_NaN;
        arg_b = pos_inf;

        // Positive Quiet NaN and Negative Normal
        #10 arg_a = pos_quiet_NaN;
        arg_b = neg_norm;

        // Positive Quiet NaN and Positive Normal
        #10 arg_a = pos_quiet_NaN;
        arg_b = pos_norm;

        // Positive Quiet NaN and Negative Denormal
        #10 arg_a = pos_quiet_NaN;
        arg_b = neg_norm;

        // Positive Quiet NaN and Positive Denormal
        #10 arg_a = pos_quiet_NaN;
        arg_b = pos_norm;

        // Positive Quiet NaN and Negative Zero
        #10 arg_a = pos_quiet_NaN;
        arg_b = neg_zero;

        // Positive Quiet NaN and Positive Zero
        #10 arg_a = pos_quiet_NaN;
        arg_b = pos_zero;

        // Reset
        #50 result_queue.delete();
        rst = 1'b0;
        str = "IEEE_near";
        rnd = 3'b110;
        #11 rst = 1'b1;

        // Combinations for Negative Infinity
        $fdisplay(tb_log_fd,"\n\n Combinations for negative infinity");
        
        // Negative Infinity and Negative signaling NaN
        #9 arg_a = neg_inf;
        arg_b = neg_sgl_NaN;   

        // Negative Infinity and Positive signaling NaN
        #10 arg_a = neg_inf;
        arg_b = pos_sgl_NaN;

        // Negative Infinity and Negative quiet NaN
        #10 arg_a = neg_inf;
        arg_b = neg_quiet_NaN; 

        // Negative Infinity and Positive quiet NaN
        #10 arg_a = neg_inf;
        arg_b = pos_quiet_NaN;

        // Negative Infinity and Negative Infinity
        #10 arg_a = neg_inf;
        arg_b = neg_inf;

        // Negative Infinity and Positive Infinity
        #10 arg_a = neg_inf;
        arg_b = pos_inf;

        // Negative Infinity and Negative Normal
        #10 arg_a = neg_inf;
        arg_b = neg_norm;

        // Negative Infinity and Positive Normal
        #10 arg_a = neg_inf;
        arg_b = pos_norm;

        // Negative Infinity and Negative Denormal
        #10 arg_a = neg_inf;
        arg_b = neg_norm;

        // Negative Infinity and Positive Denormal
        #10 arg_a = neg_inf;
        arg_b = pos_norm;

        // Negative Infinity and Negative Zero
        #10 arg_a = neg_inf;
        arg_b = neg_zero;

        // Negative Infinity and Positive Zero
        #10 arg_a = neg_inf;
        arg_b = pos_zero;

        // Reset
        #50 result_queue.delete();
        rst = 1'b0;
        str = "IEEE_near";
        rnd = 3'b110;
        #11 rst = 1'b1;

        // Combinations for Positive Infinity
        $fdisplay(tb_log_fd,"\n\n Combinations for positive infinity");
        
        // Positive Infinity and Negative signaling NaN
        #9 arg_a = pos_inf;
        arg_b = neg_sgl_NaN;   

        // Positive Infinity and Positive signaling NaN
        #10 arg_a = pos_inf;
        arg_b = pos_sgl_NaN;

        // Positive Infinity and Negative quiet NaN
        #10 arg_a = pos_inf;
        arg_b = neg_quiet_NaN; 

        // Positive Infinity and Positive quiet NaN
        #10 arg_a = pos_inf;
        arg_b = pos_quiet_NaN;

        // Positive Infinity and Negative Infinity
        #10 arg_a = pos_inf;
        arg_b = neg_inf;

        // Positive Infinity and Positive Infinity
        #10 arg_a = pos_inf;
        arg_b = pos_inf;

        // Positive Infinity and Negative Normal
        #10 arg_a = pos_inf;
        arg_b = neg_norm;

        // Positive Infinity and Positive Normal
        #10 arg_a = pos_inf;
        arg_b = pos_norm;

        // Positive Infinity and Negative Denormal
        #10 arg_a = pos_inf;
        arg_b = neg_norm;

        // Positive Infinity and Positive Denormal
        #10 arg_a = pos_inf;
        arg_b = pos_norm;

        // Positive Infinity and Negative Zero
        #10 arg_a = pos_inf;
        arg_b = neg_zero;

        // Positive Infinity and Positive Zero
        #10 arg_a = pos_inf;
        arg_b = pos_zero;

        // Reset
        #50 result_queue.delete();
        rst = 1'b0;
        str = "IEEE_near";
        rnd = 3'b110;
        #11 rst = 1'b1;

        // Combinations for Negative Normal
        $fdisplay(tb_log_fd,"\n\n Combinations for negative normal");
        
        // Negative Normal and Negative signaling NaN
        #9 arg_a = neg_norm;
        arg_b = neg_sgl_NaN;   

        // Negative Normal and Positive signaling NaN
        #10 arg_a = neg_norm;
        arg_b = pos_sgl_NaN;

        // Negative Normal and Negative quiet NaN
        #10 arg_a = neg_norm;
        arg_b = neg_quiet_NaN; 

        // Negative Normal and Positive quiet NaN
        #10 arg_a = neg_norm;
        arg_b = pos_quiet_NaN;

        // Negative Normal and Negative Infinity
        #10 arg_a = neg_norm;
        arg_b = neg_inf;

        // Negative Normal and Positive Infinity
        #10 arg_a = neg_norm;
        arg_b = pos_inf;

        // Negative Normal and Negative Normal
        #10 arg_a = neg_norm;
        arg_b = neg_norm;

        // Negative Normal and Positive Normal
        #10 arg_a = neg_norm;
        arg_b = pos_norm;

        // Negative Normal and Negative Denormal
        #10 arg_a = neg_norm;
        arg_b = neg_norm;

        // Negative Normal and Positive Denormal
        #10 arg_a = neg_norm;
        arg_b = pos_norm;

        // Negative Normal and Negative Zero
        #10 arg_a = neg_norm;
        arg_b = neg_zero;

        // Negative Normal and Positive Zero
        #10 arg_a = neg_norm;
        arg_b = pos_zero;

        // Reset
        #50 result_queue.delete();
        rst = 1'b0;
        str = "IEEE_near";
        rnd = 3'b110;
        #11 rst = 1'b1;

        // Combinations for Positive Normal
        $fdisplay(tb_log_fd,"\n\n Combinations for positive normal");
        
        // Positive Normal and Negative signaling NaN
        #9 arg_a = pos_norm;
        arg_b = neg_sgl_NaN;   

        // Positive Normal and Positive signaling NaN
        #10 arg_a = pos_norm;
        arg_b = pos_sgl_NaN;

        // Positive Normal and Negative quiet NaN
        #10 arg_a = pos_norm;
        arg_b = neg_quiet_NaN; 

        // Positive Normal and Positive quiet NaN
        #10 arg_a = pos_norm;
        arg_b = pos_quiet_NaN;

        // Positive Normal and Negative Infinity
        #10 arg_a = pos_norm;
        arg_b = neg_inf;

        // Positive Normal and Positive Infinity
        #10 arg_a = pos_norm;
        arg_b = pos_inf;

        // Positive Normal and Negative Normal
        #10 arg_a = pos_norm;
        arg_b = neg_norm;

        // Positive Normal and Positive Normal
        #10 arg_a = pos_norm;
        arg_b = pos_norm;

        // Positive Normal and Negative Denormal
        #10 arg_a = pos_norm;
        arg_b = neg_norm;

        // Positive Normal and Positive Denormal
        #10 arg_a = pos_norm;
        arg_b = pos_norm;

        // Positive Normal and Negative Zero
        #10 arg_a = pos_norm;
        arg_b = neg_zero;

        // Positive Normal and Positive Zero
        #10 arg_a = pos_norm;
        arg_b = pos_zero;

        
        // Reset
        #50 result_queue.delete();
        rst = 1'b0;
        str = "IEEE_near";
        rnd = 3'b110;
        #11 rst = 1'b1;

        // Combinations for Negative Denormal
        $fdisplay(tb_log_fd,"\n\n Combinations for negative denormal");
        
        // Negative Denormal and Negative signaling NaN
        #9 arg_a = neg_denorm;
        arg_b = neg_sgl_NaN;   

        // Negative Denormal and Positive signaling NaN
        #10 arg_a = neg_denorm;
        arg_b = pos_sgl_NaN;

        // Negative Denormal and Negative quiet NaN
        #10 arg_a = neg_denorm;
        arg_b = neg_quiet_NaN; 

        // Negative Denormal and Positive quiet NaN
        #10 arg_a = neg_denorm;
        arg_b = pos_quiet_NaN;

        // Negative Denormal and Negative Infinity
        #10 arg_a = neg_denorm;
        arg_b = neg_inf;

        // Negative Denormal and Positive Infinity
        #10 arg_a = neg_denorm;
        arg_b = pos_inf;

        // Negative Denormal and Negative Normal
        #10 arg_a = neg_denorm;
        arg_b = neg_norm;

        // Negative Denormal and Positive Normal
        #10 arg_a = neg_denorm;
        arg_b = pos_norm;

        // Negative Denormal and Negative Denormal
        #10 arg_a = neg_denorm;
        arg_b = neg_norm;

        // Negative Denormal and Positive Denormal
        #10 arg_a = neg_denorm;
        arg_b = pos_norm;

        // Negative Denormal and Negative Zero
        #10 arg_a = neg_denorm;
        arg_b = neg_zero;

        // Negative Denormal and Positive Zero
        #10 arg_a = neg_denorm;
        arg_b = pos_zero;

        // Reset
        #50 result_queue.delete();
        rst = 1'b0;
        str = "IEEE_near";
        rnd = 3'b110;
        #11 rst = 1'b1;

        // Combinations for Positive Denormal
        $fdisplay(tb_log_fd,"\n\n Combinations for positive denormal");
        
        // Positive Denormal and Negative signaling NaN
        #9 arg_a = pos_denorm;
        arg_b = neg_sgl_NaN;   

        // Positive Denormal and Positive signaling NaN
        #10 arg_a = pos_denorm;
        arg_b = pos_sgl_NaN;

        // Positive Denormal and Negative quiet NaN
        #10 arg_a = pos_denorm;
        arg_b = neg_quiet_NaN; 

        // Positive Denormal and Positive quiet NaN
        #10 arg_a = pos_denorm;
        arg_b = pos_quiet_NaN;

        // Positive Denormal and Negative Infinity
        #10 arg_a = pos_denorm;
        arg_b = neg_inf;

        // Positive Denormal and Positive Infinity
        #10 arg_a = pos_denorm;
        arg_b = pos_inf;

        // Positive Denormal and Negative Normal
        #10 arg_a = pos_denorm;
        arg_b = neg_norm;

        // Positive Denormal and Positive Normal
        #10 arg_a = pos_denorm;
        arg_b = pos_norm;

        // Positive Denormal and Negative Denormal
        #10 arg_a = pos_denorm;
        arg_b = neg_norm;

        // Positive Denormal and Positive Denormal
        #10 arg_a = pos_denorm;
        arg_b = pos_norm;

        // Positive Denormal and Negative Zero
        #10 arg_a = pos_denorm;
        arg_b = neg_zero;

        // Positive Denormal and Positive Zero
        #10 arg_a = pos_denorm;
        arg_b = pos_zero;

        
        // Reset
        #50 result_queue.delete();
        rst = 1'b0;
        str = "IEEE_near";
        rnd = 3'b110;
        #11 rst = 1'b1;

        // Combinations for Negative Zero
        $fdisplay(tb_log_fd,"\n\n Combinations for negative zero");
        
        // Negative Zero and Negative signaling NaN
        #9 arg_a = neg_zero;
        arg_b = neg_sgl_NaN;   

        // Negative Zero and Positive signaling NaN
        #10 arg_a = neg_zero;
        arg_b = pos_sgl_NaN;

        // Negative Zero and Negative quiet NaN
        #10 arg_a = neg_zero;
        arg_b = neg_quiet_NaN; 

        // Negative Zero and Positive quiet NaN
        #10 arg_a = neg_zero;
        arg_b = pos_quiet_NaN;

        // Negative Zero and Negative Infinity
        #10 arg_a = neg_zero;
        arg_b = neg_inf;

        // Negative Zero and Positive Infinity
        #10 arg_a = neg_zero;
        arg_b = pos_inf;

        // Negative Zero and Negative Normal
        #10 arg_a = neg_zero;
        arg_b = neg_norm;

        // Negative Zero and Positive Normal
        #10 arg_a = neg_zero;
        arg_b = pos_norm;

        // Negative Zero and Negative Denormal
        #10 arg_a = neg_zero;
        arg_b = neg_norm;

        // Negative Zero and Positive Denormal
        #10 arg_a = neg_zero;
        arg_b = pos_norm;

        // Negative Zero and Negative Zero
        #10 arg_a = neg_zero;
        arg_b = neg_zero;

        // Negative Zero and Positive Zero
        #10 arg_a = neg_zero;
        arg_b = pos_zero;

        // Reset
        #50 result_queue.delete();
        rst = 1'b0;
        str = "IEEE_near";
        rnd = 3'b110;
        #11 rst = 1'b1;

        // Combinations for Positive Zero
        $fdisplay(tb_log_fd,"\n\n Combinations for positive zero");
        
        // Positive Zero and Negative signaling NaN
        #9 arg_a = pos_zero;
        arg_b = neg_sgl_NaN;   

        // Positive Zero and Positive signaling NaN
        #10 arg_a = pos_zero;
        arg_b = pos_sgl_NaN;

        // Positive Zero and Negative quiet NaN
        #10 arg_a = pos_zero;
        arg_b = neg_quiet_NaN; 

        // Positive Zero and Positive quiet NaN
        #10 arg_a = pos_zero;
        arg_b = pos_quiet_NaN;

        // Positive Zero and Negative Infinity
        #10 arg_a = pos_zero;
        arg_b = neg_inf;

        // Positive Zero and Positive Infinity
        #10 arg_a = pos_zero;
        arg_b = pos_inf;

        // Positive Zero and Negative Normal
        #10 arg_a = pos_zero;
        arg_b = neg_norm;

        // Positive Zero and Positive Normal
        #10 arg_a = pos_zero;
        arg_b = pos_norm;

        // Positive Zero and Negative Denormal
        #10 arg_a = pos_zero;
        arg_b = neg_norm;

        // Positive Zero and Positive Denormal
        #10 arg_a = pos_zero;
        arg_b = pos_norm;

        // Positive Zero and Negative Zero
        #10 arg_a = pos_zero;
        arg_b = neg_zero;

        // Positive Zero and Positive Zero
        #10 arg_a = pos_zero;
        arg_b = pos_zero;


        #41 $fclose(tb_log_fd);
        $display("\n\n----- Testbench Log -----");
        $system("type testbench_log.txt");
    end

    always @(posedge clk) begin
        if (rst && enable) begin
            // Apply new inputs each cycle
            a = $urandom();
            b = $urandom();

            // Compute expected result using the "multiplication" function            
            entry.a = a;
            entry.b = b;
            entry.mode = str;
            entry.expected_result = multiplication(str, a, b);
            result_queue.push_back(entry);

            // If the pipeline delay has passed, check the result
            if (result_queue.size() > 4) begin
                refer = result_queue.pop_front();
                $fdisplay(tb_log_fd,"COMPARE @%0t | a=%h b=%h | DUT=%h | status=%h | REF=%h | MODE=%s", ($time-10), refer.a, refer.b, z, status, refer.expected_result, refer.mode);
                if (z !== refer.expected_result)
                    $error("Mismatch: DUT=%h, REF=%h", z, refer.expected_result);
            end
        end


       if (rst && !enable) begin

            a = match_cs_to_bin(arg_a);
            b = match_cs_to_bin(arg_b);

            // Compute expected result using the "multiplication" function          
            entry.a = a;
            entry.b = b;
            entry.mode = str;
            entry.expected_result = multiplication(str, a, b);
            result_queue.push_back(entry);

            // If the pipeline delay has passed, check the result
            if (result_queue.size() > 4) begin
                refer = result_queue.pop_front();
                $fdisplay(tb_log_fd,"COMPARE @%0t | a=%h b=%h | DUT=%h | status=%h | REF=%h | MODE=%s", ($time-10), refer.a, refer.b, z, status, refer.expected_result, refer.mode);
                if (z !== refer.expected_result)
                    $error("Mismatch: DUT=%h, REF=%h", z, refer.expected_result);
            end
        end
    end

endmodule
