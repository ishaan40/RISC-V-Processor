module muldiv
(
    input logic clk,
    input logic rst,
    input logic start,
    input logic [2:0] muldivop,
    input logic [31:0] a,
    input logic [31:0] b,
    output logic muldiv_resp,
    output logic [31:0] result
);

// intermediate logic
logic [31:0] numerator;
logic [31:0] denominator;
logic [31:0] quotient;
logic [31:0] remainder;
logic [31:0] multiplicand;
logic [31:0] multiplier;
logic [63:0] product;
logic neg_bit;
logic mul_start;
logic mulh_start;
logic mulsu_start;
logic mulhu_start;
logic div_start;
logic divu_start;
logic rem_start;
logic remu_start;
logic mul_resp;
logic div_resp;

// assign start signals -- only start when:
// 1) mul/div/rem instruction is in execute stage
// 2) the instruction matches the start signal operation
assign mul_start = (start && muldivop == 7'd0) ? 1'b1 : 1'b0;
assign mulh_start = (start && muldivop == 7'd1) ? 1'b1 : 1'b0;
assign mulsu_start = (start && muldivop == 7'd2) ? 1'b1 : 1'b0;
assign mulhu_start = (start && muldivop == 7'd3) ? 1'b1 : 1'b0;
assign div_start = (start && muldivop == 7'd4) ? 1'b1 : 1'b0;
assign divu_start = (start && muldivop == 7'd5) ? 1'b1 : 1'b0;
assign rem_start = (start && muldivop == 7'd6) ? 1'b1 : 1'b0;
assign remu_start = (start && muldivop == 7'd7) ? 1'b1 : 1'b0;

// default inputs, outputs, and intermediate logic to 0
function void set_defaults();
    multiplicand = 0;
    multiplier = 0;
    numerator = 0;
    denominator = 0;
    neg_bit = 0;
    result = 0;
    muldiv_resp = 0;
endfunction

always_comb 
begin : result_logic
    // set default values to 0
    set_defaults();
    case(muldivop)
        // signed multiplication -- lower 32-bits -- ensure all inputs are positive, if not then flip bits and add 1, and check if product should be negative, if so then flip bits and add 1
        7'd0: begin
            multiplicand = (a[31] == 1'b1) ? (~a) + 32'd1 : a;
            multiplier = (b[31] == 1'b1) ? (~b) + 32'd1 : b;
            neg_bit = (a[31] ^ b[31]);
            result = (neg_bit) ? (~product[31:0]) + 32'd1 : product[31:0];
            muldiv_resp = mul_resp;
        end
        // signed multiplication -- upper 32-bits -- ensure all inputs are positive, if not then flip bits and add 1, and check if product should be negative, if so then flip bits and add 1
        7'd1: begin
            multiplicand = (a[31] == 1'b1) ? (~a) + 32'd1 : a;
            multiplier = (b[31] == 1'b1) ? (~b) + 32'd1 : b;
            neg_bit = (a[31] ^ b[31]);
            result = (neg_bit) ? (~product[63:32]) + 32'd1 : product[63:32];
            muldiv_resp = mul_resp;            
        end
        // signed x unsigned multiplication -- upser 32-bits -- ensure only the second input is positive, if not then flip bits and add 1, check if product should be negative, if so then flip bits and add 1
        7'd2: begin
            multiplicand = (a[31] == 1'b1) ? (~a) + 32'd1 : a;
            multiplier = b;
            neg_bit = a[31];
            result = (neg_bit) ? (~product[63:32]) + 32'd1 : product[63:32];
            muldiv_resp = mul_resp;          
        end
        // unsigned multiplication -- upper 32-bits -- perform as normal
        7'd3: begin
            multiplicand = a;
            multiplier = b;
            neg_bit = 1'b0;
            result = product[63:32];
            muldiv_resp = mul_resp;              
        end
        // signed division -- ensure all inputs are positive, if not then flip bits and add 1, and check if quotient should be negative, if so then flip bits and add 1
        7'd4: begin
            numerator = (a[31] == 1'b1) ? (~a) + 32'd1 : a;
            denominator = (b[31] == 1'b1) ? (~b) + 32'd1 : b;
            neg_bit = (a[31] ^ b[31]);
            result = (neg_bit) ? (~quotient) + 32'd1 : quotient;
            muldiv_resp = div_resp;
        end
        // unsigned division -- execute division as normal
        7'd5: begin
            numerator = a;
            denominator = b;
            neg_bit = 1'b0;
            result = quotient;
            muldiv_resp = div_resp;
        end
        // signed remainder -- ensure all inputs are positive, if not then flip bits and add 1, and check if remainder should be negative, if so then flip bits and add 1
        7'd6: begin
            numerator = (a[31] == 1'b1) ? (~a) + 32'd1 : a;
            denominator = (b[31] == 1'b1) ? (~b) + 32'd1 : b;
            neg_bit = a[31];
            result = (neg_bit) ? (~remainder) + 32'd1 : remainder;
            muldiv_resp = div_resp;
        end
        // unsigned remainder -- execute remainder as normal
        7'd7: begin
            numerator = a;
            denominator = b;
            neg_bit = 1'b0;
            result = remainder;
            muldiv_resp = div_resp;
        end
        default:;
    endcase
end

// multiplication module -- only start when instruction is a mul instruction
multiplier mul(
    .clk(clk),
    .rst(rst),
    .start(mul_start || mulh_start || mulsu_start || mulhu_start),
    .multiplicand(multiplicand),
    .multiplier(multiplier),
    .product(product),
    .mul_resp(mul_resp)
);

// divison module -- only start when instruction is a div/rem instruction
divider div(
    .clk(clk),
    .rst(rst),
    .start(div_start || divu_start || rem_start || remu_start),
    .numerator(numerator),
    .denominator(denominator),
    .quotient(quotient),
    .remainder(remainder),
    .div_resp(div_resp)
);

endmodule : muldiv