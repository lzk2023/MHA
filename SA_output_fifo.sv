`timescale 1ns/1ps

module SA_output_fifo#(
    DATA_WIDTH = 8,
    FIFO_DEPTH = 16
)(
    input  logic                  I_CLK                      ,
    input  logic                  I_RST_N                    ,
    input  logic                  I_PUSH_EN                  ,
    input  logic [DATA_WIDTH-1:0] I_PUSH_DATA                ,
    output logic [DATA_WIDTH-1:0] O_ALL_DATA [FIFO_DEPTH-1:0],
    output logic [DATA_WIDTH-1:0] O_POP_DATA                 ,
    output logic                  O_PUSH_EN                  ,
    output logic                  O_FULL                     
);
integer i;
logic [7:0] cnt;
logic  full_ena;
assign O_POP_DATA = O_ALL_DATA[FIFO_DEPTH-1];
always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        O_ALL_DATA <= '{default:'b0};
    end else begin
        for(i=0;i<FIFO_DEPTH;i=i+1)begin
            if(i==0)begin
                O_ALL_DATA[0] <= I_PUSH_DATA;
            end else begin
                O_ALL_DATA[i] <= O_ALL_DATA[i-1];
            end
        end
    end
end

always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        O_PUSH_EN <= 1'b0;
    end else if(I_PUSH_EN)begin
        O_PUSH_EN <= 1'b1;
    end else begin
        O_PUSH_EN <= 1'b0;
    end
end

always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        O_FULL   <= 1'b0;
        cnt      <= 8'd0;
        full_ena <= 1'b0;
    end else if(I_PUSH_EN)begin
        O_FULL   <= 1'b0;
        cnt      <= 8'd1;
        full_ena <= 1'b1;
    end else begin
        if(full_ena)begin
            if(cnt == FIFO_DEPTH-1)begin
                O_FULL <= 1'b1;
                cnt    <= cnt  ;
                full_ena <= 1'b0;
            end else begin
                O_FULL <= 1'b0   ;
                cnt    <= cnt + 1;
            end
        end else begin
            O_FULL   <= 1'b0;
            cnt      <= 8'd0;
        end
    end
end
endmodule