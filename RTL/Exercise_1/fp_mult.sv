package pipeline_pkg;

    import round_pkg::*;
    typedef struct packed{
        logic [31:0] a; 
        logic [31:0] b; 
        logic sign; 
        logic signed [9:0] norm_exponent;
        logic [22:0] norm_mantissa;
        logic guard;
        logic sticky;
        round rnd;
   } pipeline_data_t;

endpackage


import round_pkg::*;
import pipeline_pkg::*;

module fp_mult(input logic [31:0] a,b ,input logic [2:0] rnd, output logic [31:0] z, output logic [7:0] status, input logic clock, input logic reset);

//  Declare "sign" 
logic sign;
assign sign=a[31]^b[31];


// Add exponents and subtract the bias (127)
logic signed [9:0] sum_of_exponents;
assign sum_of_exponents = {2'b00,a[30:23]}+{2'b00,b[30:23]}-10'd127; 


// Multiply the mantissas (along with the leading ones)
logic [47:0] p;
assign p = {1'b1,a[22:0]}*{1'b1,b[22:0]};


// Declare outputs of normalization module
logic guard, sticky;
logic [22:0] norm_mantissa;
logic signed [9:0] norm_exponent;

// Instantiate normalization module
normalize_mult u1(.p(p),.sum_of_exponents(sum_of_exponents),.guard(guard),.sticky(sticky),.norm_mantissa(norm_mantissa),.norm_exponent(norm_exponent));

 // Cast logic to enum internally
round rnd_enum;
assign rnd_enum = round'(rnd);

// Declare pipeline registers and define the pipelining logic
pipeline_data_t pipeline_stage1;

always_ff @(posedge clock) begin
    
    if(!reset) begin
        pipeline_stage1<='0;
    end
    else begin
        pipeline_stage1<= '{a: a, b: b, sign: sign, norm_exponent: norm_exponent, norm_mantissa: norm_mantissa, guard: guard, sticky: sticky, rnd: rnd_enum};
    end
    
end

// Declare outputs of rounding module
logic [24:0] post_round_mantissa;
logic signed [9:0] post_round_exponent;
logic inexact;

// Instantiate rounding module
round_mult u2(.mantissa({1'b1,pipeline_stage1.norm_mantissa}),.norm_exponent(pipeline_stage1.norm_exponent),.rnd(pipeline_stage1.rnd),.guard(pipeline_stage1.guard),.sticky(pipeline_stage1.sticky),.sign(pipeline_stage1.sign),.post_round_mantissa(post_round_mantissa),.post_round_exponent(post_round_exponent),.inexact(inexact));

// Combine mantissa, exponent and sign to create z_calc
logic [31:0] z_calc;
assign z_calc = {pipeline_stage1.sign, post_round_exponent[7:0], post_round_mantissa[22:0]};

// Define bits for overflow and underflow
logic overflow, underflow;

always_comb begin
    
    // Overflow handling
    if(post_round_exponent>254)
        overflow = 1;
    else
        overflow = 0;

    // Underflow handling
    if(pipeline_stage1.norm_exponent<1)
        underflow = 1;
    else
        underflow = 0;
    
end

// Define outputs for exception handling module
logic zero_f, inf_f, nan_f, tiny_f, huge_f, inexact_f;

// Instantiate exception handling module
exception_mult u3(.a(pipeline_stage1.a),.b(pipeline_stage1.b),.z_calc(z_calc),.overflow(overflow),.underflow(underflow),.inexact(inexact),.rnd(pipeline_stage1.rnd),.z(z),.zero_f(zero_f),.inf_f(inf_f),.nan_f(nan_f),.tiny_f(tiny_f),.huge_f(huge_f),.inexact_f(inexact_f));

// Define "Div by 0" flag
logic div_by_0_f;

always_comb begin
    
    // Assign "Div by 0" flag its value
    if(inexact_f==1'b0 && inf_f==1'b1 && pipeline_stage1.a[30:23]!=8'b11111111 && pipeline_stage1.a[30:23]!=8'b11111111)
        div_by_0_f = 1;
    else
        div_by_0_f = 0;

end


// Construct "status" bitstring
assign status = {div_by_0_f,1'b0,inexact_f,huge_f,tiny_f,nan_f,inf_f,zero_f}; 



endmodule
