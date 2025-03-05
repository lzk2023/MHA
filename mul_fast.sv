module mul_fast#(
    parameter IN_DW = 16
)(
    input  logic [IN_DW-1:0]   I_IN1    ,
    input  logic [IN_DW-1:0]   I_IN2    ,
    output logic [IN_DW*2-1:0] O_MUL_OUT
);
integer i;
logic [IN_DW*2-1:0] input_1;
assign input_1 = {{IN_DW{I_IN1[IN_DW-1]}},I_IN1};
always_comb begin
    O_MUL_OUT = 0;
    for(i=0;i<IN_DW;i=i+1)begin
        if(i == IN_DW-1)
            O_MUL_OUT = O_MUL_OUT - ((I_IN2[i]) ? input_1 << i : 0);
        else 
            O_MUL_OUT = O_MUL_OUT + ((I_IN2[i]) ? input_1 << i : 0);
    end
end
endmodule