// Define package containing the enum type 
package round_pkg;

// Define enum type for "round" function   
typedef enum logic [2:0]{IEEE_near=3'b000, IEEE_zero=3'b001, IEEE_pinf=3'b010, IEEE_ninf=3'b011, near_up=3'b100, away_zero=3'b101} round;

endpackage

import round_pkg::*;

module round_mult(input logic [23:0] mantissa, input logic signed [9:0] norm_exponent, input round rnd, input logic guard, sticky, sign, output logic [24:0] post_round_mantissa, output logic signed [9:0] post_round_exponent, output logic inexact);

always_comb begin

    // Determine whether result of mantissa multiplication is exact or not
    if(guard==1'b0 && sticky==1'b0) begin
        inexact=0;        // No rounding is required
        post_round_mantissa=mantissa;
    end
    else begin
        inexact=1;        // Rounding is required
        
        // Calculate result output by rounding
        case(rnd)
    
          IEEE_near: begin

              if(guard==1'b1 && sticky==1'b0) begin //It is equally away from both float numbers, we choose the one with even mantissa
                  if(mantissa[0]==1'b0)
                      post_round_mantissa = mantissa;
                  else
                      post_round_mantissa = mantissa+1;
              end
              else if(guard==1'b0 && sticky==1'b1) // We truncate because it is closer to the lesser of the two floats
                  post_round_mantissa = mantissa;
              else if(guard==1'b1 && sticky==1'b1) // We round to the higher of the two floats
                  post_round_mantissa = mantissa+1;

          end

          IEEE_zero: post_round_mantissa = mantissa; // We just truncate

          IEEE_pinf: begin

              if(sign==1'b1)
                 post_round_mantissa = mantissa;  // If the number is negative, we round to the float whose magnitude is smaller
              else 
                 post_round_mantissa = mantissa+1; // We round to the float whose magnitude is bigger
          end 

          IEEE_ninf: begin

              if(sign==1'b1)
                 post_round_mantissa = mantissa+1; // If the number is negative, we round to the float whose magnitude is bigger
              else
                 post_round_mantissa = mantissa;  // We round to the float whose magnitude is smaller

          end

          near_up: begin

             if(sign==1'b1) begin // We check if the sign is negative
                 if(guard==1'b1 && sticky==1'b0) // If the distance is equal, we break the tie and round to the number with the smaller magnitude
                     post_round_mantissa = mantissa;
                 else if(guard==1'b0 && sticky==1'b1) // We truncate because it is closer to the smaller in magnitude of the two floats
                     post_round_mantissa = mantissa;
                 else if(guard==1'b1 && sticky==1'b1) // We round to the bigger in magnitude of the two floats
                     post_round_mantissa = mantissa+1;
            end
            else begin
                 if(guard==1'b1 && sticky==1'b0) //It is equally away from both float numbers, we choose the one with even mantissa
                     post_round_mantissa = mantissa+1;    
                 else if(guard==1'b0 && sticky==1'b1) // We truncate because it is closer to the lesser of the two floats
                     post_round_mantissa = mantissa;
                 else if(guard==1'b1 && sticky==1'b1) // We round to the higher of the two floats
                     post_round_mantissa = mantissa+1;
            end   

         end

         away_zero: post_round_mantissa = mantissa+1;

         default: begin

            if(guard==1'b1 && sticky==1'b0) begin //it is equally away from both float numbers, we choose the one with even mantissa
                if(mantissa[0]==1'b0)
                    post_round_mantissa = mantissa;
                else
                    post_round_mantissa = mantissa+1;
            end
            else if(guard==1'b0 && sticky==1'b1) // we truncate because it is closer to the lesser of the two floats
                post_round_mantissa = mantissa;
            else if(guard==1'b1 && sticky==1'b1) // we round to the higher of the two floats
                post_round_mantissa = mantissa+1;
         end

      endcase
    
  end


  if(post_round_mantissa[24]==1) begin
      post_round_mantissa=post_round_mantissa>>1;
      post_round_exponent = norm_exponent+1;
  end
  else
      post_round_exponent = norm_exponent;
    
end

endmodule

