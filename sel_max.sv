`timescale 1ns/1ps
module sel_max#(
    parameter D_W = 16
)(
    input  logic [D_W-1:0] I_DATA [0:15],
    output logic [D_W-1:0] O_MAX
);
logic [D_W-1:0] stage_0 [0:7];
logic [D_W-1:0] stage_1 [0:3];
logic [D_W-1:0] stage_2 [0:1];
logic [D_W-1:0] stage_3      ;
generate 
    for(genvar i=0;i<8;i=i+1)begin
        assign stage_0[i] = ($signed(I_DATA[2*i]) > $signed(I_DATA[2*i+1])) ? I_DATA[2*i] :I_DATA[2*i+1];
    end
endgenerate

generate 
    for(genvar i=0;i<4;i=i+1)begin
        assign stage_1[i] = ($signed(stage_0[2*i]) > $signed(stage_0[2*i+1])) ? stage_0[2*i] :stage_0[2*i+1];
    end
endgenerate

generate 
    for(genvar i=0;i<2;i=i+1)begin
        assign stage_2[i] = ($signed(stage_1[2*i]) > $signed(stage_1[2*i+1])) ? stage_1[2*i] :stage_1[2*i+1];
    end
endgenerate

assign stage_3 = ($signed(stage_2[0]) > $signed(stage_2[1])) ? stage_2[0] :stage_2[1];
assign O_MAX = stage_3;
endmodule