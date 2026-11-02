module test_status_bits(input logic [7:0] status);


always @(status) begin

// Combinations for zero_f
// zero_f and inf_f do not assert together
a1: assert (!(status[0] && status[1])) $display(" @%0t zero_f && inf_f : PASS", $time); else $display(" @%0t zero_f && inf_f : FAIL", $time);

// zero_f and nan_f do not assert together
a2: assert (!(status[0] && status[2])) $display(" @%0t zero_f && nan_f : PASS", $time); else $display(" @%0t zero_f && nan_f : FAIL", $time);

// zero_f and huge_f do not assert together
a3: assert (!(status[0] && status[4])) $display(" @%0t zero_f && huge_f : PASS", $time); else $display(" @%0t zero_f && huge_f : FAIL", $time);

// zero_f and unused_f do not assert together
a4: assert (!(status[0] && status[6])) $display(" @%0t zero_f && unused_f : PASS", $time); else $display(" @%0t zero_f && unused_f : FAIL", $time);

// zero_f and div_by_0_f do not assert together
a5: assert (!(status[0] && status[7])) $display(" @%0t zero_f && div_by_0_f : PASS", $time); else $display(" @%0t zero_f && div_by_0_f : FAIL", $time);


// Combinations for inf_f
// inf_f and tiny_f do not assert together
a6: assert (!(status[1] && status[3])) $display(" @%0t inf_f && nan_f : PASS", $time); else $display(" @%0t inf_f && nan_f : FAIL", $time);

// inf_f and unused_f do not assert together
a7: assert (!(status[1] && status[6])) $display(" @%0t inf_f && unused_f : PASS", $time); else $display(" @%0t inf_f && unused_f : FAIL", $time);


// Combinations for nan_f
// nan_f and tiny_f do not assert together
a8: assert (!(status[2] && status[3])) $display(" @%0t nan_f && tiny_f : PASS", $time); else $display(" @%0t nan_f && tiny_f : FAIL", $time);

// nan_f and huge_f do not assert together
a9: assert (!(status[2] && status[4])) $display(" @%0t nan_f && huge_f : PASS", $time); else $display(" @%0t nan_f && huge_f : FAIL", $time);

// nan_f and inexact_f do not assert together
a10: assert (!(status[2] && status[5])) $display(" @%0t nan_f && inexact_f : PASS", $time); else $display(" @%0t nan_f && inexact_f : FAIL", $time);

// nan_f and unused_f do not assert together
a11: assert (!(status[2] && status[6])) $display(" @%0t nan_f and unused_f : PASS", $time); else $display(" @%0t nan_f and unused_f : FAIL", $time);


// Combinations for tiny_f
// tiny_f and huge_f do not assert together
a12: assert (!(status[3] && status[4])) $display(" @%0t tiny_f && huge_f : PASS", $time); else $display(" @%0t tiny_f && huge_f : FAIL", $time);

// tiny_f and unused_f do not assert together
a13: assert (!(status[3] && status[6])) $display(" @%0t tiny_f && unused_f : PASS", $time); else $display(" @%0t tiny_f && unused_f : FAIL", $time);

// tiny_f and div_by_0_f do not assert together
a14: assert (!(status[3] && status[7])) $display(" @%0t tiny_f && div_by_0_f : PASS", $time); else $display(" @%0t tiny_f && div_by_0_f : FAIL", $time);


// Combinations for huge_f
// huge_f and unused_f do not assert together
a15: assert (!(status[4] && status[6])) $display(" @%0t huge_f && unused_f : PASS", $time); else $display(" @%0t huge_f && unused_f : FAIL", $time);

// huge_f and div_by_0_f do not assert together
a16: assert (!(status[4] && status[7])) $display(" @%0t huge_f && div_by_0_f : PASS", $time); else $display(" @%0t huge_f && div_by_0_f : FAIL", $time);


// Combinations for inexact_f
// inexact_f and unused_f do not assert together
a17: assert (!(status[5] && status[6])) $display(" @%0t inexact_f && unused_f : PASS", $time); else $display(" @%0t inexact_f && unused_f : FAIL", $time);

// inexact_f and div_by_0_f do not assert together
a18: assert (!(status[5] && status[7])) $display(" @%0t inexact_f && div_by_0_f : PASS", $time); else $display(" @%0t inexact_f && div_by_0_f : FAIL", $time);

// Combination for unused_f
// unused_f and div_by_0_f do not assert together
a19: assert (!(status[6] && status[7])) $display(" @%0t unused_f && div_by_0_f : PASS", $time); else $display(" @%0t unused_f && div_by_0_f : FAIL", $time);



end

endmodule


module test_status_z_combinations(input logic clk, input logic [7:0] status, input logic [31:0] z, input logic [31:0] a,b);

property pr1;
    @(posedge clk) status[0] |-> (z[30:23]==8'b0); 
endproperty
assert property (pr1) $display(" @%0t zero_f and z_exponent : PASS", $time); else $display(" @%0t zero_f and z_exponent : FAIL", $time);

property pr2;
    @(posedge clk) status[1] |-> (z[30:23]==8'b11111111); 
endproperty
assert property (pr2) $display(" @%0t inf_f and z_exponent : PASS", $time); else $display(" @%0t inf_f and z_exponent : FAIL", $time);

property pr3;
    @(posedge clk) status[2] |-> ( ($past(a[30:23],3)==8'b0 && $past(b[30:23],3)==8'b11111111) || ($past(b[30:23],3)==8'b0 && $past(a[30:23],4)==8'b11111111) ); 
endproperty
assert property (pr3)$display(" @%0t nan_f and a_exponent and b_exponent : PASS", $time); else $display(" @%0t nan_f and a_exponent and b_exponent : FAIL", $time);

property pr4;
    @(posedge clk) status[4] |-> ( (z[30:23]==8'b11111111) || (z[30:23]==8'b11111110 && z[22:0]=={23{1'b1}}) ); 
endproperty
assert property (pr4)$display(" @%0t huge_f and z : PASS", $time); else $display(" @%0t huge_f and z : FAIL", $time);

property pr5;
    @(posedge clk) status[3] |-> ((z[30:23]==8'b0) || (z[30:23]==8'b00000001 && z[22:0]==23'b0)); 
endproperty
assert property (pr5)$display(" @%0t tiny_f and z : PASS", $time); else $display(" @%0t tiny_f and z : FAIL", $time);


endmodule