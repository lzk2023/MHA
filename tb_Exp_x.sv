`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/18 10:51:16
// Design Name: 
// Module Name: tb_Exp_x
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_Exp_x(

    );
    logic signed[7:0] X;
    logic [7:0] EXP;
    bit [7:0]exp_x_compare;
    real exp_x_real;
    Exp_x #(
        .D_W(8)
    )u_Exp_x(
        .I_X  (X),
        .O_EXP(EXP)
    );
    task float_ex(
        input real X
    );
        real real_x = X/('d32);
        $display("the value of real_x is :%0f !",real_x);
        exp_x_real = $exp(real_x);
        exp_x_compare = (exp_x_real)*'d32;
    endtask
    
    //property check_exp_value;
    //    @(X)
    //    (exp_x_compare == EXP) |-> $display("value is right! EXP = %0d",exp_x_real);
    //endproperty
    initial begin
        #10 X = 8'b1_00_00000;//-4
        #10 X = 8'b1_00_10000;//-3.5
        #10 X = 8'b1_01_00000;//-3
        #10 X = 8'b1_01_10000;//-2.5
        #10 X = 8'b1_10_00000;//-2
        #10 X = 8'b1_10_10000;//-1.5
        #10 X = 8'b1_11_00000;//-1
        #10 X = 8'b1_11_10000;//-0.5
        #10 X = 8'b0_00_00000;//0
        #10 X = 8'b0_00_10000;//0.5
        #10 X = 8'b0_01_00000;//1
        #10 X = 8'b0_01_10000;//1.5
        #10 X = 8'b0_10_00000;//2
        #10 X = 8'b0_10_10000;//2.5
        #10 X = 8'b0_11_00000;//3
        #10 X = 8'b0_11_10000;//3.5
        #10 X = 8'b0_11_11111;//4
        #10 $finish;
    end
    
    initial begin
        while(1)
            @(X) float_ex(X);
    end
    always@(X) begin
        #1
        assert (EXP <= exp_x_compare+16'h0040 & EXP >= exp_x_compare-16'h0040) $display("value is right! EXP = %0f",exp_x_real);
        else $error("vlaue is not right!");
    end
endmodule
