# Synchronous FIFO

This project contains a parameterized synchronous FIFO implementation in
[`fifo.v`](./fifo.v).

## Features

- Configurable data width
- Configurable FIFO depth
- Active-low asynchronous reset
- Synchronous clear input
- Full and empty status flags
- Almost-full and almost-empty status flags
- Occupancy counter
- Protection against writes when full and reads when empty

## Module parameters

| Parameter | Default | Description |
| --- | ---: | --- |
| `WIDTH` | `32` | Width of each FIFO data word |
| `DEPTH` | `4` | Number of data words stored |
| `AW` | `2` | Address width for the read and write pointers |

For a power-of-two FIFO depth, `AW` is normally `log2(DEPTH)`.

## Interface

| Signal | Direction | Description |
| --- | --- | --- |
| `clk` | Input | Clock |
| `rst_n` | Input | Active-low asynchronous reset |
| `clr` | Input | Synchronous FIFO clear |
| `wr_en` | Input | Requests a write operation |
| `rd_en` | Input | Requests a read operation |
| `data_in` | Input | Data written into the FIFO |
| `data_out` | Output | Data at the current read location |
| `full` | Output | High when the FIFO contains `DEPTH` words |
| `empty` | Output | High when the FIFO contains no words |
| `almost_full` | Output | High when one location remains |
| `almost_empty` | Output | High when one word remains |
| `count` | Output | Current number of stored words |

## Operation

### Reset

When `rst_n` is low, the read pointer, write pointer, and `count` are reset
asynchronously. The FIFO becomes empty.

### Clear

When `clr` is high at a rising clock edge, the read pointer, write pointer,
and `count` are reset synchronously. The FIFO becomes empty.

### Write

A write is accepted when:

```text
wr_en = 1 and full = 0
```

When accepted, `data_in` is stored and the occupancy count increases by one.
Writes requested while the FIFO is full are ignored.

### Read

A read is accepted when:

```text
rd_en = 1 and empty = 0
```

When accepted, the read pointer advances and the occupancy count decreases by
one. Reads requested while the FIFO is empty are ignored.

### Simultaneous read and write

When both operations are accepted on the same rising clock edge, the read and
write pointers advance while `count` remains unchanged.

## Example instantiation

```verilog
fifo #(
    .WIDTH(32),
    .DEPTH(4),
    .AW(2)
) u_fifo (
    .clk          (clk),
    .rst_n        (rst_n),
    .clr          (clr),
    .wr_en        (wr_en),
    .rd_en        (rd_en),
    .data_in      (data_in),
    .data_out     (data_out),
    .full         (full),
    .empty        (empty),
    .almost_full  (almost_full),
    .almost_empty (almost_empty),
    .count        (count)
);
```

## Simulation

The testbench is in [`fifo_tb.v`](./fifo_tb.v). With Icarus Verilog installed,
compile and run it with:

```text
iverilog -g2012 -o fifo_tb.vvp fifo_tb.v
vvp fifo_tb.vvp
```

The testbench generates `fifo.vcd`, which can be opened in a waveform viewer
such as GTKWave.

## Simulation results

The FIFO testbench was compiled and simulated successfully with Icarus
Verilog:

```text
iverilog -o fifo_tb.vvp fifo_tb.v
vvp fifo_tb.vvp
```

Observed output:

```text
VCD info: dumpfile fifo.vcd opened for output.
-----------------------------------------
Checks run: 3018 | Full cycles: 414 | Empty cycles: 351 | Simul. R/W cycles: 714
PASS: all checks passed
fifo_tb.v:118: $finish called at 30180000 (1ps)
```

The simulation covered:

- 3018 checker cycles
- 414 cycles with the FIFO full
- 351 cycles with the FIFO empty
- 714 cycles with simultaneous read and write requests
- Overflow and underflow protection tests
- Randomized read/write activity with occasional clear operations

The GTKWave waveform confirms the clock, reset, read/write enables, FIFO
count, status flags, reference-model state, and data activity. The generated
waveform file is `fifo_tb.vcd`.
