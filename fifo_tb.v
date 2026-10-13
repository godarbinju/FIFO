`timescale 1ns/1ps
`include "fifo.v"

module fifo_tb;
   parameter WIDTH = 32;
   parameter DEPTH = 4;
   parameter AW = 2;

   reg   clk = 0; 
   reg rst_n = 0; 
   reg clr = 0; 
   reg wr_en = 0;
   reg rd_en = 0;
   reg [WIDTH-1:0] data_in = 0;
   wire [WIDTH-1:0] data_out;
   wire full,empty,almost_full, almost_empty;
   wire [AW:0]  count;


   fifo #(WIDTH, DEPTH, AW) uut (
        .clk(clk), .rst_n(rst_n), .clr(clr),
        .wr_en(wr_en), .rd_en(rd_en),.data_in(data_in),
        .data_out(data_out), .full(full), .empty(empty),
        .almost_full(almost_full), .almost_empty(almost_empty),
        .count(count)
   );

   always #5 clk = ~clk;

   reg [WIDTH-1:0] ref_mem [0: DEPTH-1];
   integer ref_rd = 0, ref_wr = 0, ref_cnt = 0;
   reg do_wr , do_r;

   always @(posedge clk) begin
       if(!rst_n || clr) begin
          ref_rd = 0; ref_wr =0; ref_cnt = 0;
       end else begin
        do_wr = wr_en && (ref_cnt<DEPTH);
        do_r = rd_en && (ref_cnt>0);
        if(do_wr) begin
            ref_mem[ref_wr] = data_in;
            ref_wr = (ref_wr + 1)%DEPTH;
            end
        if(do_r) ref_rd = (ref_rd +  1) % DEPTH;
        ref_cnt = ref_cnt + do_wr - do_r;
        end
    end

// ---------------- Checker (runs every negedge) ----------------
    integer errors = 0, checks = 0;
    integer full_seen = 0, empty_seen = 0, rw_both = 0;
 
    always @(negedge clk) begin
        checks = checks + 1;
        if (count !== ref_cnt) begin
            errors = errors + 1;
            $display("[%0t] FAIL count: dut=%0d ref=%0d", $time, count, ref_cnt);
        end
        if (empty !== (ref_cnt == 0)) begin
            errors = errors + 1;
            $display("[%0t] FAIL empty flag", $time);
        end
        if (full !== (ref_cnt == DEPTH)) begin
            errors = errors + 1;
            $display("[%0t] FAIL full flag", $time);
        end
        if (almost_full !== (ref_cnt == DEPTH-1)) begin
            errors = errors + 1;
            $display("[%0t] FAIL almost_full flag", $time);
        end
        if (almost_empty !== (ref_cnt == 1)) begin
            errors = errors + 1;
            $display("[%0t] FAIL almost_empty flag", $time);
        end
        if (ref_cnt > 0 && data_out !== ref_mem[ref_rd]) begin
            errors = errors + 1;
            $display("[%0t] FAIL data: dut=%h ref=%h", $time, data_out, ref_mem[ref_rd]);
        end
        // simple corner-case coverage counters
        if (ref_cnt == DEPTH) full_seen  = full_seen + 1;
        if (ref_cnt == 0)     empty_seen = empty_seen + 1;
        if (wr_en && rd_en)   rw_both    = rw_both + 1;
    end
 
    // ---------------- Stimulus ----------------
    integer i;
    initial begin
        $dumpfile("fifo.vcd");
        $dumpvars(0, fifo_tb);
 
        repeat (2) @(negedge clk);
        rst_n = 1;
 
    // ---1 Fill beyond capacity (tests overflow protection)--
        for (i = 0; i < DEPTH + 2; i = i + 1) begin
            @(negedge clk); wr_en = 1; rd_en = 0; data_in = $random;
        end
        // 2 Drain beyond empty (tests underflow protection)
        for (i = 0; i < DEPTH + 2; i = i + 1) begin
            @(negedge clk); wr_en = 0; rd_en = 1;
        end
        // 3 Randomized reads/writes with occasional clear
        for (i = 0; i < 3000; i = i + 1) begin
            @(negedge clk);
            wr_en   = $random & 1;
            rd_en   = $random & 1;
            data_in = $random;
            clr     = (($random & 255) == 0);
        end
        @(negedge clk); wr_en = 0; rd_en = 0; clr = 0;
        repeat (3) @(negedge clk);
 
        $display("-----------------------------------------");
        $display("Checks run: %0d | Full cycles: %0d | Empty cycles: %0d | Simul. R/W cycles: %0d",
                 checks, full_seen, empty_seen, rw_both);
        if (errors == 0) $display("PASS: all checks passed");
        else             $display("FAIL: %0d errors", errors);
        $finish;
    end
endmodule


   