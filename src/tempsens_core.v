//	Copyright 2022-2024 Manuel Moser and Harald Pretl, IIC@JKU
//
//	Licensed under the Apache License, Version 2.0 (the "License");
//	you may not use this file except in compliance with the License.
//	You may obtain a copy of the License at
//
//		http://www.apache.org/licenses/LICENSE-2.0
//
//	Unless required by applicable law or agreed to in writing, software
//	distributed under the License is distributed on an "AS IS" BASIS,
//	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//	See the License for the specific language governing permissions and
//	limitations under the License.
//
//	This cell implements a digitall-controlled delay cell (dcdel), which when
//	operated in subthreshold has a strong temperature dependcy of the delay time.
//	This effect can be used to implement e.g. a digital temperature sensor.
//
//	IMPORTANT: Make sure that the synthesis and optimization tools do not mess
//	with the resulting netlist, especially at the node `vout_ana_`!
//
//	CHANGES
//	2023-12-31 (HP) Rename net _notouch_ to _ana_
//    2024-01-04 (HP) Improve simulation model to provide better results
//    2024-01-12 (HP) Rename to tempsens_core
//    2024-01-13 (HP) Add clk input and synchronization of output signal

`ifndef __TEMPSENS_CORE__
`define __TEMPSENS_CORE__

`default_nettype none
`ifdef SIMULATION
`timescale 1ns/1ns
`endif
`ifndef SIMULATION
`include "tempsens_vdac.v"
`endif
//`include "/foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v"
//`include "/foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v"

module tempsens_core #( parameter DAC_RESOLUTION=6, parameter CAP_LOAD=16 )(
      input wire                          clk,
      input wire [DAC_RESOLUTION-1:0]     i_dac_data,
      input wire                          i_dac_en,
      input wire                          i_precharge_n,
`ifdef SIMULATION
      output reg                          o_tempdelay
`else
      output wire                         o_tempdelay
`endif
  );

      // during precharging and measurement, o_tempdelay stays high
      // a 1->0 transition marks the end of the measurement time

`ifdef SIMULATION
      wire dac0, dac1, dac_change;
      assign dac0 = ~|i_dac_data;
      assign dac1 = &i_dac_data;

      always @(*) begin
            if (i_dac_en == 1'b0) begin
                  #1 o_tempdelay = 1'bx;
            end else begin
                  if ((dac1 == 1'b1) && (i_precharge_n == 1'b0)) begin
                        // precharge
                        #1 o_tempdelay = 1'b1;
                  end

                  if ((dac0 == 1'b0) && (i_precharge_n == 1'b1)) begin
                        if (i_dac_data >25) begin
                              #10000 o_tempdelay = 1'b0;
                        end else if (i_dac_data < 25) begin
                              #200000 o_tempdelay = 1'b0;
                        end else #40000 o_tempdelay = 1'b0;
                  end
            end 
      end
`else
      // Voltage-mode digital-to-analog converter (VDAC)
      (* keep = "true" *) wire dac_vout_ana_;
      (* keep = "true" *) wire tempdelay_async;
      (* keep = "true" *) tempsens_vdac #(.BITWIDTH(DAC_RESOLUTION)) dac (
            .i_data(i_dac_data),
            .i_enable(i_dac_en),
            .vout_ana_(dac_vout_ana_)
      );

      // Digitally-controled delay cell (dcdel)
      wire tie0 = 1'b0;
      (* keep = "true" *) wire dcdel_capnode_ana_;
      (* keep = "true" *) wire dcdel_out_n;
      // verilator lint_off UNUSED
      (* keep = "true" *) wire [CAP_LOAD-1:0] dummy_ana_;
      // verilator lint_on UNSIGNED

      (* keep = "true" *) sky130_fd_sc_hd__einvp_1 dcdc (.A(i_precharge_n), .TE(dac_vout_ana_), .Z(dcdel_capnode_ana_));
      (* keep = "true" *) sky130_fd_sc_hd__inv_1 inv1 (.A(dcdel_capnode_ana_),.Y(dcdel_out_n));
      (* keep = "true" *) sky130_fd_sc_hd__inv_1 inv2 (.A(dcdel_out_n),.Y(tempdelay_async));

      genvar i;
	generate
		for (i=0; i < CAP_LOAD; i=i+1) begin : capload
			(* keep = "true" *) sky130_fd_sc_hd__nand2_1 cap (.B(dcdel_capnode_ana_), .A(tie0), .Y(dummy_ana_[i]));
		end
  	endgenerate

      // We need to sync-in the async. delayed signal, do on falling clk edge
      reg tempdelay_sync1, tempdelay_sync2;
      assign o_tempdelay = tempdelay_sync2;

      always @(negedge clk) begin
           tempdelay_sync2 <= tempdelay_sync1;
           tempdelay_sync1 <= tempdelay_async; 
      end

`endif

endmodule // tempsens_core
`endif
