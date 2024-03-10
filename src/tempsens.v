//	Copyright 2024 Harald Pretl, IIC@JKU
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
//	This cell combines the digital control of the temperature sensor
//  (which can be simulated digitally) with the analog part of the
//  temperature sensor that has to be simulated analog. In this way
//  a mixed-mode simulation can be setup efficiently.

`ifndef __TEMPSENS__
`define __TEMPSENS__

`default_nettype none
`include "../src/tempsens_ctrl.v"
`include "../src/tempsens_core.v"

module tempsens (
	// main inputs
	input wire 					reset,
	input wire 					clk,
	input wire [N_VDAC-1:0] 	i_dac_code,
	input wire [3:0] 			i_dbg_sel,
	input wire [1:0]			i_dbg_ts,
	// main outputs
	output wire [N_TEMP-1:0]	o_res,
	output wire [3:0] 			o_dbg
);

	localparam N_TEMP = 20;
	localparam N_VDAC = 6;
	localparam CAP_LOAD = 16;

	// local interconnect wires
	wire [N_VDAC-1:0]	ts_dat;
	wire 				ts_en;
	wire 				ts_tempdelay;
	wire 				ts_prechrgn;

	tempsens_ctrl #( .N_TEMP(N_TEMP), .N_VDAC(N_VDAC) ) ts_ctrl (
		.reset(reset),
		.clk(clk),
		.i_dac_code(i_dac_code),
		.i_dbg_sel(i_dbg_sel),
		.i_dbg_ts(i_dbg_ts),
		.o_res(o_res),
		.o_dbg(o_dbg),
		.i_ts_tempdelay(ts_tempdelay),
		.o_ts_en(ts_en),
		.o_ts_dat(ts_dat),
		.o_ts_prechrgn(ts_prechrgn)
	);

	tempsens_core #(.DAC_RESOLUTION(N_VDAC), .CAP_LOAD(CAP_LOAD)) ts_core (
		.clk(clk),
		.i_dac_data(ts_dat),
		.i_dac_en(ts_en),
		.i_precharge_n(ts_prechrgn),
		.o_tempdelay(ts_tempdelay)
	);

endmodule // tempsens
`endif
