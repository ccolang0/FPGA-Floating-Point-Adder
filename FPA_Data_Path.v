`timescale 1ns / 1ps

module FPA_Data_Path(
    input wire clk, clr,                    // external timing inputs
    input wire a_sign, b_sign,              // external data inputs
    input wire [3:0] a_exp, b_exp,          // external data inputs
    input wire [2:0] a_mant, b_mant,        // external data inputs
    input wire load_en, add_en,             // internal inputs from controller (reg enables)
               norm_en, done_en,                            // from controller (reg enables)
               shift_right, norm_load,                      // from controller (MUX selects)
    output wire add_except, norm_except,     // outgoing state data to controller (exceptions)
    output wire [4:0] mant,                 // outgoing state data to contoller
    output wire ans_sign,                   // outgoing data (external)
    output wire [3:0] ans_exp,              // outgoing data (external)
    output wire [2:0] ans_mant,             // outgoing data (external)
    output wire [3:0] ans_except            // outgoing data (external)
//    ,output wire sign_gt_d, sign_ls_d, sign_gt_q, sign_ls_q
//    ,output wire [3:0] exp_gt_d, exp_ls_d, exp_gt_q, exp_ls_q
//    ,output wire [4:0] mant_gt_d, mant_ls_d, mant_gt_q, mant_ls_q
);

    // LOAD stage wires
    wire sign_gt_d, sign_ls_d, sign_gt_q, sign_ls_q;
    wire [3:0] exp_gt_d, exp_ls_d, exp_gt_q, exp_ls_q;
    wire [4:0] mant_gt_d, mant_ls_d, mant_gt_q, mant_ls_q;
    
    // ADD stage wires
    wire [3:0] exp_add_d, exp_add_q;
    wire [4:0] mant_add_d, mant_add_q;
    // helper intermediates
    wire [3:0] exp_diff;
    wire [4:0] mant_ls_shift;
    wire add;
    
    // NORM stage wires
    wire [3:0] exp_norm_d, exp_norm_q;
    wire [4:0] mant_norm_d, mant_norm_q;
    // helper intermediates
    wire [3:0] exp_norm_shift;
    wire [4:0] mant_norm_shift;
    
    // EXCEPTION wires
    wire zero, except1, except2, except3;

    // LOAD inputs ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    assign sign_gt_d = (a_exp > b_exp || (a_exp == b_exp && a_mant >= b_mant)) ? a_sign : b_sign;
    assign sign_ls_d = (a_exp > b_exp || (a_exp == b_exp && a_mant >= b_mant)) ? b_sign : a_sign;
    assign exp_gt_d = (a_exp > b_exp || (a_exp == b_exp && a_mant >= b_mant)) ? a_exp : b_exp;
    assign exp_ls_d = (a_exp > b_exp || (a_exp == b_exp && a_mant >= b_mant)) ? b_exp : a_exp;
    assign mant_gt_d[4:3] = 2'b01;
    assign mant_ls_d[4:3] = 2'b01;
    assign mant_gt_d[2:0] = (a_exp >= b_exp || (a_exp >= b_exp && a_mant >= b_mant)) ? a_mant : b_mant;
    assign mant_ls_d[2:0] = (a_exp >= b_exp || (a_exp >= b_exp && a_mant >= b_mant)) ? b_mant : a_mant;
    
    assign ans_sign = sign_gt_q;
    
    D_Latch_Reg #(1) sign_gt_reg(.clk(clk),
                                 .clr(clr),
                                 .en(load_en),
                                 .d(sign_gt_d),
                                 .q(sign_gt_q));
                                 
    D_Latch_Reg #(1) sign_ls_reg(.clk(clk),
                                 .clr(clr),
                                 .en(load_en),
                                 .d(sign_ls_d),
                                 .q(sign_ls_q));
                                 
    D_Latch_Reg #(4) exp_gt_reg(.clk(clk),
                                .clr(clr),
                                .en(load_en),
                                .d(exp_gt_d),
                                .q(exp_gt_q));
                                
    D_Latch_Reg #(4) exp_ls_reg(.clk(clk),
                                .clr(clr),
                                .en(load_en),
                                .d(exp_ls_d),
                                .q(exp_ls_q));
                                
    D_Latch_Reg #(5) mant_gt_reg(.clk(clk),
                                 .clr(clr),
                                 .en(load_en),
                                 .d(mant_gt_d),
                                 .q(mant_gt_q));
                                 
    D_Latch_Reg #(5) mant_ls_reg(.clk(clk),
                                 .clr(clr),
                                 .en(load_en),
                                 .d(mant_ls_d),
                                 .q(mant_ls_q));
                                 
    // SHIFT and ADD stage ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // 1. assign intermediates
    assign exp_diff = exp_gt_q - exp_ls_q;
    assign add = sign_gt_q == sign_ls_q;
    assign mant_ls_shift = mant_ls_q >> exp_diff;
    
    // 2. assign latch inputs
    assign exp_add_d = exp_gt_q;
    assign mant_add_d = add ? mant_gt_q + mant_ls_shift : mant_gt_q - mant_ls_shift;
    
    // 3. create regs
    D_Latch_Reg #(4) exp_add_reg(.clk(clk),
                                 .clr(clr),
                                 .en(add_en),
                                 .d(exp_add_d),
                                 .q(exp_add_q));
                                
    D_Latch_Reg #(5) mant_add_reg(.clk(clk),
                                  .clr(clr),
                                  .en(add_en),
                                  .d(mant_add_d),
                                  .q(mant_add_q));
    
    // 4. check for exceptions:
    // --- ZERO
    assign zero = !add && (mant_gt_q == mant_ls_q);  // if subtracting and a == b
    // --- OVERFLOW
    assign except1 = add && (mant_gt_q > mant_add_q);
    // --- UNDERFLOW
    assign except2 = !add && (mant_gt_q < mant_add_q);
    // --> encode state data for controller
    assign add_except = zero || except1 || except2;
    
    // NORMALIZE ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // 1. assign intermediates
    assign exp_norm_shift = shift_right ? exp_norm_q + 1 : exp_norm_q - 1;
    assign mant_norm_shift = shift_right ? mant_norm_q >> 1 : mant_norm_q << 1;
    
    // 2. assign latch inputs
    assign exp_norm_d = norm_load ? exp_add_q : exp_norm_shift;
    assign mant_norm_d = norm_load ? mant_add_q : mant_norm_shift;
    
    // 3. create regs
    D_Latch_Reg #(4) exp_norm_reg(.clk(clk),
                                  .clr(clr),
                                  .en(norm_en),
                                  .d(exp_norm_d),
                                  .q(exp_norm_q));
                                
    D_Latch_Reg #(5) mant_norm_reg(.clk(clk),
                                   .clr(clr),
                                   .en(norm_en),
                                   .d(mant_norm_d),
                                   .q(mant_norm_q));
    
    // 4. check for exceptions:
    // --- INFINITIES or NaN
    assign except3 = exp_norm_q == 3'b111;
    // --> encode state data for controller
    assign norm_except = except3;
    
    // 5. assign outgoing computation data for controller
    assign mant = norm_en ? mant_norm_d : mant_add_q;
    
    // SEt FINAL OUTPUT ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    assign ans_except = {zero, except1, except2, except3};
    
    D_Latch_Reg #(4) exp_done_reg(.clk(clk),
                                  .clr(clr),
                                  .en(done_en),
                                  .d(exp_norm_q),
                                  .q(ans_exp));
                                
    D_Latch_Reg #(3) mant_done_reg(.clk(clk),
                                   .clr(clr),
                                   .en(done_en),
                                   .d(mant_norm_q[2:0]),
                                   .q(ans_mant[2:0]));
    
endmodule
