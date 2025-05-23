`timescale 1ns/1ps

module SA_input_fifo#(
    DATA_WIDTH = 8,
    FIFO_DEPTH = 16
)(
    input  logic                  I_CLK                       ,
    input  logic                  I_RST_N                     ,
    input  logic                  I_LOAD_EN                   ,
    input  logic [DATA_WIDTH-1:0] I_LOAD_DATA [0:FIFO_DEPTH-1],
    output logic [DATA_WIDTH-1:0] O_DATA                      ,
    output logic                  O_LOAD_EN                   ,
    output logic                  O_EMPTY                     
);
integer i;
logic [DATA_WIDTH-1:0] fifo_reg [0:FIFO_DEPTH-1];
logic [7:0] cnt;
assign O_DATA = fifo_reg[FIFO_DEPTH-1];
always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        fifo_reg <= '{default:'b0};
    end else if(I_LOAD_EN)begin
        fifo_reg <= I_LOAD_DATA;
    end else begin
        for(i=0;i<FIFO_DEPTH;i=i+1)begin
            if(i==0)begin
                fifo_reg[0] <= 'b0;
            end else begin
                fifo_reg[i] <= fifo_reg[i-1];
            end
        end
    end
end

always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        O_LOAD_EN <= 1'b0;
    end else if(I_LOAD_EN)begin
        O_LOAD_EN <= 1'b1;
    end else begin
        O_LOAD_EN <= 1'b0;
    end
end

always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        O_EMPTY <= 1'b0;
        cnt     <= 8'b0;
    end else if(I_LOAD_EN)begin
        O_EMPTY <= 1'b0;
        cnt     <= 8'b0;
    end else begin
        if(cnt == FIFO_DEPTH-1)begin
            O_EMPTY <= 1'b1;
            cnt     <= cnt;
        end else begin
            O_EMPTY <= 1'b0;
            cnt     <= cnt + 1;
        end
    end
end
endmodule