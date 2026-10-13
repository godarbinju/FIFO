module fifo #(
    parameter WIDTH = 32,
    parameter DEPTH = 4,
    parameter AW = 2
)(
    input wire clk,
    input wire rst_n, // async, active low
    input wire clr,
    input wire wr_en,
    input wire rd_en,
    input wire [WIDTH-1: 0] data_in,
    output wire [WIDTH-1: 0] data_out,
    output wire  full,
    output wire empty,
    output wire almost_full,
    output wire almost_empty,
    output reg [AW:0] count  
);

    reg [WIDTH-1:0] mem [0: DEPTH-1];
    reg [AW-1: 0] wr_ptr, rd_ptr;

    assign full = (count == DEPTH);
    assign empty = (count == 0);
    assign almost_full = (count == DEPTH-1);
    assign almost_empty = (count == 1);

    wire do_wr = wr_en && !full;
    wire do_rd = rd_en && !empty;

    assign data_out =  mem[rd_ptr];

    always @(posedge clk or negedge rst_n) begin
          if(!rst_n) begin
             wr_ptr <= 0;
             rd_ptr <= 0;
             count <= 0;

        end else if (clr) begin
             wr_ptr <= 0;
             rd_ptr <= 0;
             count <= 0;
        end else begin
            if(do_wr) begin
                mem[wr_ptr] <= data_in;
                wr_ptr <= wr_ptr + 1'b1;
            end
            if(do_rd)
               rd_ptr <= rd_ptr + 1'b1;
            
            case ({do_wr, do_rd})
               2'b10: count <= count + 1'b1;
               2'b01: count <= count - 1'b1;
               default : count <= count;
            endcase

        end
    end

    endmodule