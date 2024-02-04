/*
 * Copyright (c) 2024 Harald Pretl, IIC@JKU
 * SPDX-License-Identifier: Apache-2.0
 *
 * This wrapper puts the temperate sensor inside the TinyTapeout
 * harness adapting the IOs to the ones available.
 *
 * The asynchronous rst_n is synchronized on neg. clk edge, just
 * to be sure. Inside our circuits state machine runs on rising edge.
 */

`define default_netname none
`default_nettype none
`include "../src/tempsens.v"

module tt_um_hpretl_tt06_tempsens (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // Don't use (used for power gating)
    input  wire       clk,
    input  wire       rst_n     // Async to clk
);

  // All output pins must be assigned. If not used, assign to 0.
  assign uio_out[3:0] = 4'b0;
  assign uio_oe = 8'b11110000;

  /* verilator lint_off UNUSED */
  wire [3:0] dummy1 = uio_in[7:4];
  wire dummy2 = ena;
  /* verilator lint_on UNUSED */

  // Sync reset on falling clk edge
  reg res1_n, res2_n;

  always @(negedge clk) begin
    res1_n <= rst_n;
    res2_n <= res1_n;
  end

  wire reset = ~res2_n;
  wire [1:0] out_sel = ui_in[7:6];
  wire [5:0] dac_code = ui_in[5:0];
  wire [19:0] out_wide;

  assign uo_out = (out_sel == 2'b00) ? out_wide[7:0] :
                  (out_sel == 2'b01) ? out_wide[15:8] :
                  (out_sel == 2'b10) ? {4'b0,out_wide[19:16]} :
                  8'b01101001;

  tempsens ts (
		.reset(reset),
		.clk(clk),
		.i_dac_code(dac_code),
    .i_dbg_sel(uio_in[3:0]),
    .i_dbg_ts(out_sel),
		.o_res(out_wide),
		.o_dbg(uio_out[7:4])
	);

endmodule // tt_um_hpretl_tt06_tempsens
