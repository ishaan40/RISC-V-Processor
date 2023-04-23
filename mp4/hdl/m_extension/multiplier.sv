module multiplier
(
    input logic clk,
    input logic rst,
    input logic start,
    input logic [31:0] multiplicand,
    input logic [31:0] multiplier,
    output logic [63:0] product,
    output logic mul_resp
);

// intermediate logic
logic [31:0] repeated_add;
logic [31:0] iteration;
logic [31:0] next_iteration;
logic [63:0] next_product;
logic [31:0] stop_case;

always_comb begin
    if(multiplicand > multiplier) begin
        stop_case = multiplier - 32'd1;
        repeated_add = multiplicand;
    end
    else begin
        stop_case = multiplicand - 32'd1;
        repeated_add = multiplier;
    end

end

// list of states
enum int unsigned {
    idle,
    add_shift,
    done
} state, next_state;

// next state logic
always_ff @(posedge clk)
begin : next_state_condition
    if(rst) begin
        state <= idle;
        iteration <= 32'd0;
        product <= 32'd0;
    end
    else begin
        state <= next_state;
        iteration <= next_iteration;
        product <= next_product;
    end
end

always_comb
begin : next_state_logic
    case(state)
        idle: begin
                if(start == 1'b1 && (multiplicand == 32'd0 || multiplier == 32'd0)) begin
                    next_state <= done;
                end
                else if(start == 1'b1)
                    next_state <= add_shift;
                else
                    next_state <= idle;
              end

        add_shift: begin
                    if(iteration == stop_case)
                        next_state <= done;
                    else
                        next_state <= add_shift;
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
                next_iteration <= 32'd0;
                next_product <= 32'd0;
                mul_resp <= 1'b0;
              end
        
        add_shift: begin
                    next_product = product + repeated_add;
                    next_iteration = iteration + 32'd1;
                    mul_resp <= 1'd0;
                   end

        done: begin
                next_iteration <= 32'd0;
                next_product <= 32'd0;             
                mul_resp <= 1'b1;
              end
              
        default: begin
                    next_iteration <= 32'd0;
                    next_product <= 32'd0;
                    mul_resp <= 1'b0;
                 end
    endcase
end
endmodule : multiplier