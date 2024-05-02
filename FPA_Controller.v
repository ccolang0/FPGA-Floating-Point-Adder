`timescale 1ns / 1ps

module FPA_Controller(
    input wire clk, clr, start,             // external timing inputs
    input wire add_except, norm_except,     // internal inputs from data path
               [4:0] mant,
    output reg load_en, add_en,             // outgoing signals to datapath
               norm_en, done_en,
               shift_right, norm_load
    ,output reg [2:0] pres, next
);

    // State variables and values
//    reg [2:0] pres, next;
    parameter idle = 3'b000, load = 3'b001, add = 3'b010, load_norm = 3'b011, norm = 3'b100, done = 3'b101;
    
    // State registers update block
    always @(negedge clk or posedge clr) begin
        if (clr)
            pres <= idle;
        else
            pres <= next;
    end
    
    // Next State combinational logic -- implementing state diagram
    always @(*) begin
        case (pres)
            idle:       next <= start ? load : idle;
            load:       next <= add;
            add:        next <= add_except ? idle : load_norm;
            load_norm:  next <= mant[4:3] == 2'b01 ? done : norm;
            norm:       next <= norm_except ? idle : (mant[4:3] == 2'b01 ? done : norm);
            done:       next <= idle;
        endcase
    end
    
    // Output combinational logic -- using Moore machine state diagram
    always @(*) begin
        load_en = 0; add_en = 0; done_en = 0; shift_right = 0; norm_load = 0;
        case (pres)
            idle:       norm_en <= 0;
            load:       begin
                            load_en <= 1;
                            norm_load <= 0;
                        end
            add:        begin
                            add_en <= 1;
                            norm_load <= 0;
                        end
            load_norm:  begin
                            norm_load <= 1;
                            norm_en <= 1;
//                            shift_right <= mant[4] == 1;
                        end
            norm:       begin
                            norm_en <= 1;
                            shift_right <= mant[4] == 1;
                        end
            done:       done_en <= 1;
        endcase
    end

endmodule
