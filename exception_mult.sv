//Import package containing the enum type 
import round_pkg::*;

module exception_mult(input logic [31:0] a, b, z_calc, input logic overflow, underflow, inexact, input round rnd, output logic [31:0] z, output logic zero_f, inf_f, nan_f, tiny_f, huge_f, inexact_f);

// Define enum type for "interp_t"  
typedef enum logic [2:0]{ZERO=3'b000, INF=3'b001, NORM=3'b010, MIN_NORM=3'b011, MAX_NORM=3'b100} interp_t;


// Define "num_interp" function
function interp_t num_interp(input logic [31:0] signal);

if(signal[30:23]==8'b0) // Zeros and Denormals
    return ZERO;
else if(signal[30:23]==8'b11111111) // Infinities and NaNs
    return INF;
else if(signal[30:23]!=8'b11111111 && signal[30:23]!=8'b0) // Normals
    return NORM;

endfunction


// Define "z_num" function
function [30:0] z_num(input interp_t category);

if(category==ZERO) // Zeros and Denormals
    return 31'b0;
else if(category==INF) // Infinities and NaNs
    return {8'b11111111, 23'b0};

endfunction

// Declare a_interp and b_interp and assign values to them with the "num_interp" function
interp_t a_interp, b_interp;

always_comb begin
    a_interp = num_interp(a);
    b_interp = num_interp(b);
end

always_comb begin

zero_f=0;
inf_f=0;
nan_f=0;
tiny_f=0;
huge_f=0;
inexact_f=0;


case({a_interp, b_interp})

{ZERO,ZERO}: begin
     z={z_calc[31],z_num(ZERO)};
     zero_f=1;
end
{ZERO,NORM}: begin 
     z={z_calc[31],z_num(ZERO)};
     zero_f=1;
end
{ZERO,INF}:begin  
     z={1'b0,z_num(INF)};
     inf_f=1;
     if(z_calc[22]==0)
         nan_f=1;
end
{INF,INF}:begin   
     z={z_calc[31],z_num(INF)};
     inf_f=1;
end
{INF,NORM}:begin  
     z={z_calc[31],z_num(INF)};
     inf_f=1;
end
{INF,ZERO}:begin  
     z={1'b0,z_num(INF)};
     inf_f=1;
     if(z_calc[22]==0)
         nan_f=1;
end
{NORM,ZERO}:begin 
     z={z_calc[31],z_num(ZERO)};
     zero_f=1;
end
{NORM,INF}:begin  
     z={z_calc[31],z_num(INF)};
     inf_f=1;
end
{NORM,NORM}: begin

if(overflow==1'b1) begin
    huge_f=1;
    inexact_f=1;
    case(rnd)
      IEEE_near: begin
          z={z_calc[31],z_num(INF)}; // Round to infinity
          inf_f=1;
      end
      IEEE_zero: z={z_calc[31],8'b11111110, {23{1'b1}}};
      IEEE_pinf: begin
          if(z_calc[31]==1'b1)
              z={z_calc[31],8'b11111110, {23{1'b1}}};
          else begin
              z={z_calc[31],z_num(INF)};
              inf_f=1;
          end
      end
      IEEE_ninf: begin 
          if(z_calc[31]==1'b1) begin
              z={z_calc[31],z_num(INF)};
              inf_f=1;
          end
          else
              z={z_calc[31],8'b11111110, {23{1'b1}}};
      end
      near_up: begin

          z={z_calc[31],z_num(INF)};
          inf_f=1;
      end         
      away_zero: begin
          z={z_calc[31],z_num(INF)};
          inf_f=1;
      end
      default: begin
          z={z_calc[31],z_num(INF)};
          inf_f=1;
      end
    endcase
end
else if(underflow==1'b1)begin
    tiny_f=1;
    inexact_f=1;
    case(rnd)

     IEEE_near: begin 
            z={z_calc[31],z_num(ZERO)};
            zero_f=1;
     end
     IEEE_zero: begin 
            z={z_calc[31],z_num(ZERO)};
            zero_f=1;
     end
     IEEE_pinf: begin
         if(z_calc[31]==1'b1) begin
             z={z_calc[31],z_num(ZERO)};
             zero_f=1;
         end
         else
             z={z_calc[31],8'b00000001,23'b0};
     end
     IEEE_ninf: begin
         if(z_calc[31]==1'b1)
             z={z_calc[31],8'b00000001,23'b0};
         else begin
             z={z_calc[31],z_num(ZERO)};
             zero_f=1;
         end
     end
     near_up: begin
         z={z_calc[31],z_num(ZERO)};
         zero_f=1;
    end    
    away_zero: z={z_calc[31],8'b00000001,23'b0};
    default: begin
        z={z_calc[31],z_num(ZERO)};
        zero_f=1;
    end
   endcase
end

else begin
    z=z_calc;
    inexact_f=inexact;
end

end

endcase

end

endmodule

