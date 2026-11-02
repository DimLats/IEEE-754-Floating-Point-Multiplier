module normalize_mult(input logic [47:0] p, input logic signed [9:0] sum_of_exponents, output logic guard, sticky, output logic [22:0] norm_mantissa, output logic signed [9:0] norm_exponent);

always_comb begin

    // Find Normalized Exponent
    if(p[47]==1'b1)
        norm_exponent = sum_of_exponents + 1;
    else
        norm_exponent = sum_of_exponents;
    
    
    // Find Normalized Mantissa
    if(p[47]==1'b1)
        norm_mantissa = p[46:24];
    else
        norm_mantissa = p[45:23];
    
    
    // Find Guard Bit
    if(p[47]==1'b1)
        guard = p[23];
    else
        guard = p[22];
    
    
    // Find Sticky Bit
    if(p[47]==1'b1)
        sticky = |p[22:0];
    else
        sticky = |p[21:0];
    
end

endmodule
