`timescale 1ns / 1ps

module T_FPA_Top;

    reg clk, clr, start;
    reg [7:0] a, b;
    wire [7:0] ans;
    wire [3:0] ans_except;
//    wire sign_gt_d, sign_ls_d, sign_gt_q, sign_ls_q;
//    wire [3:0] exp_gt_d, exp_ls_d, exp_gt_q, exp_ls_q;
//    wire [4:0] mant_gt_d, mant_ls_d, mant_gt_q, mant_ls_q;
    wire [2:0] pres, next;
    wire [4:0] mant;
    wire shift_right;
    wire shift_left;

    FPA_Top fpa(.clk(clk),
                .clr(clr),
                .start(start),
                .a(a),
                .b(b),
                .ans(ans),
                .ans_except(ans_except)
                ,.pres(pres)
                ,.next(next)
                ,.mant(mant)
                ,.shift_right(shift_right)
                ,.shift_left(shift_left)
                ,.load_en(load_en)
                ,.add_en(add_en)
                ,.norm_en(norm_en)
                ,.done_en(done_en)
                ,.norm_load(norm_load)
                );

    always #2 clk = ~clk;

    initial begin
        clk = 0; clr = 0; start = 0; a = 0; b = 0;
        
        #2  clr = 1;
        #2  clr = 0;
        
        #2  a = 8'b00111101;
            b = 8'b00110100;
            
        #2  start = 1;
        #5  start = 0;
    
        #50 $finish;
    end

endmodule
