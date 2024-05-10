`timescale 1ns / 1ps

module FPA_Top(
    input wire clk, clr, start,
    input wire [7:0] a, b,
    output wire [7:0] ans, [3:0] ans_except
//    ,output wire sign_gt_d, sign_ls_d, sign_gt_q, sign_ls_q
//    ,output wire [3:0] exp_gt_d, exp_ls_d, exp_gt_q, exp_ls_q
//    ,output wire [4:0] mant_gt_d, mant_ls_d, mant_gt_q, mant_ls_q
//    ,output wire [2:0] pres, next
//    ,output wire [4:0] mant
//    ,output wire shift_right, shift_left
//    ,output wire load_en, add_en, norm_en, done_en, norm_load
);

    wire add_except, norm_except;
    wire [4:0] mant;
    wire load_en, add_en, norm_en, done_en, 
         shift_right, 
         shift_left,
         norm_load;

    FPA_Controller controller(.clk(clk),
                              .clr(clr),
                              .start(start),
                              .add_except(add_except),
                              .norm_except(norm_except),
                              .mant(mant),
                              .load_en(load_en),
                              .add_en(add_en),
                              .norm_en(norm_en),
                              .done_en(done_en),
                              .shift_right(shift_right),
                              .shift_left(shift_left),
                              .norm_load(norm_load)
//                              ,.pres(pres)
//                              ,.next(next)
                              );
                              
    FPA_Data_Path data_path(.clk(clk),
                            .clr(clr),
                            .a_sign(a[7]),
                            .b_sign(b[7]),
                            .a_exp(a[6:3]),
                            .b_exp(b[6:3]),
                            .a_mant(a[2:0]),
                            .b_mant(b[2:0]),
                            .load_en(load_en),
                            .add_en(add_en),
                            .norm_en(norm_en),
                            .done_en(done_en),
                            .shift_right(shift_right),
                            .shift_left(shift_left),
                            .norm_load(norm_load),
                            .add_except(add_except),
                            .norm_except(norm_except),
                            .mant(mant),
                            .ans_sign(ans[7]),
                            .ans_exp(ans[6:3]),
                            .ans_mant(ans[2:0]),
                            .ans_except(ans_except)
//                            ,.sign_gt_d(sign_gt_d)
//                            ,.sign_ls_d(sign_ls_d)
//                            ,.exp_gt_d(exp_gt_d)
//                            ,.exp_ls_d(exp_ls_d)
//                            ,.mant_gt_d(mant_gt_d)
//                            ,.mant_ls_d(mant_ls_d)
                            );

endmodule
