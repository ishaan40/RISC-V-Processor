module divider
(
    input logic clk,
    input logic rst,
    input logic start,
    input logic [31:0] numerator,
    input logic [31:0] denominator,
    output logic [31:0] quotient,
    output logic [31:0] remainder,
    output logic div_resp
);

// intermediate logic
logic [31:0] iteration;
logic [31:0] next_quotient;
logic [31:0] next_remainder;
logic [31:0] next_iteration;

// list of states
enum int unsigned {
    idle,
    sub_shift,
    done
} state, next_state;

// next state logic
always_ff @(posedge clk)
begin : next_state_condition
    if(rst) begin
        state <= idle;
        quotient <= 32'd0;
        remainder <= 32'd0;
    end
    else begin
        state <= next_state;
        iteration <= next_iteration;
        quotient <= next_quotient;
        remainder <= next_remainder;
    end
end

always_comb
begin : next_state_logic
    case(state)
        idle: begin
                if(start == 1'b1 && (numerator == 32'd0 || denominator == 32'd0)) begin
                    next_state <= done;
                end
                else if(start == 1'b1)
                    next_state <= sub_shift;
                else
                    next_state <= idle;
              end

        sub_shift: begin
                    if(iteration == -32'd1)
                        next_state <= done;
                    else
                        next_state <= sub_shift;
                   end

        done: begin
                next_state <= idle;
              end
        default:;
    endcase
end

always_comb 
begin : state_output
    case(state)
        idle: begin
                next_iteration <= 32'd31;
                next_quotient <= 32'd0;
                next_remainder <= 32'd0;
                div_resp <= 1'b0;
              end
        
        sub_shift: begin
                    if(denominator <= remainder) begin
                        next_quotient[31:0] = {quotient[30:0], 1'b1};
                        if(iteration < 32'd32)
                            next_remainder = {remainder[30:0] - denominator[30:0], numerator[iteration]};
                        else
                            next_remainder = remainder - denominator;
                    end
                    else begin
                        next_quotient = {quotient[30:0], 1'b0};
                        if(iteration < 32'd32)
                            next_remainder = {remainder[30:0], numerator[iteration]};
                        else
                            next_remainder = remainder;
                    end
                    next_iteration <= iteration - 32'd1;
                    div_resp <= 1'b0;
                   end

        done: begin
                next_iteration <= 32'd31;
                next_quotient <= 32'd0;
                next_remainder <= 32'd0;                
                div_resp <= 1'b1;
              end
              
        default: begin
                    next_iteration <= 32'd31;
                    next_quotient <= 32'd0;
                    next_remainder <= 32'd0;
                    div_resp <= 1'b0;
                 end
    endcase
end
endmodule : divider