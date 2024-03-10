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

`ifndef __TEMPSENS_CTRL__
`define __TEMPSENS_CTRL__

`default_nettype none

module tempsens_ctrl #( parameter N_TEMP=20, N_VDAC=6 )(
	// main inputs
	input wire reset,
	input wire clk,
	input wire [N_VDAC-1:0] i_dac_code,
	input wire [3:0] i_dbg_sel,
	input wire [1:0] i_dbg_ts,
	// main outputs
	output wire [N_TEMP-1:0] o_res,
	output wire [3:0] o_dbg,
	// I/F to tempsens_core
	input wire i_ts_tempdelay,
	output wire o_ts_en,
	output wire [N_VDAC-1:0] o_ts_dat,
	output wire o_ts_prechrgn
);

	localparam ST_INIT = 3'd0;
	localparam ST_PRECHARGE = 3'd1;
	localparam ST_TRANSITION_PH1 = 3'd2;
	localparam ST_TRANSITION_PH2 = 3'd3;
	localparam ST_MEASURE = 3'd4;
	localparam ST_DONE = 3'd5;

	reg [N_TEMP-1:0] temp_ctr, tempsens_final;
	reg [2:0] state;

	// debug I/F
	reg [3:0] dbg;


	// definition of external outputs
	assign o_res = tempsens_final;
	assign o_dbg = dbg;


	always @(posedge clk or posedge reset) begin
		if (reset == 1'b1) begin
			state <= ST_INIT;
			temp_ctr <= {N_TEMP{1'b0}};
			tempsens_final <= {N_TEMP{1'b0}};
		end else begin
			if (state == ST_INIT)			state <= ST_PRECHARGE;
			if (state == ST_INIT)			temp_ctr <= {N_TEMP{1'b0}};
			if (state == ST_PRECHARGE)		state <= ST_TRANSITION_PH1;
			if (state == ST_TRANSITION_PH1)	state <= ST_TRANSITION_PH2;
			if (state == ST_TRANSITION_PH2)	state <= ST_MEASURE;

			if (state == ST_MEASURE)		temp_ctr <= temp_ctr + 1'b1;

			if ((state == ST_MEASURE) && (i_ts_tempdelay == 1'b0)) begin
											state <= ST_DONE;
											tempsens_final <= temp_ctr;
			end
		end
	end


	// VDAC max and min value
	localparam VMAX = {N_VDAC{1'b1}};
	localparam VMIN = {N_VDAC{1'b0}};


	// create state signals based on state of state machine
	wire in_reset = (state == ST_INIT);
	wire in_precharge = (state == ST_PRECHARGE);
	wire in_transition_ph1 = (state == ST_TRANSITION_PH1);
	wire in_transition_ph2 = (state == ST_TRANSITION_PH2);
	wire in_transition = in_transition_ph1 || in_transition_ph2;
	wire in_measurement = (state == ST_MEASURE);
	wire is_done = (state == ST_DONE);
	wire in_debug = (i_dbg_sel == 4'd15);

	// signals going in and out of temperature-dependent delay line
    wire tempsens_en, tempsens_measure;
	wire [N_VDAC-1:0] tempsens_dat;

	// create temperature sensor input signal based on state signals
	// debug mode 15 allows direct control of tempsensor core from outside
	assign tempsens_en = 		in_debug ? i_dbg_ts[0] :
								(in_precharge || in_transition || in_measurement) ? 1'b1 : 1'b0;
	
	assign tempsens_dat =		in_debug 			? i_dac_code :
								in_precharge		? VMAX :
								in_transition		? VMIN :
								in_measurement		? i_dac_code : VMAX;

	assign tempsens_measure =	in_debug 			? i_dbg_ts[1] :
								in_precharge		? 1'b0 :
								in_transition_ph1	? 1'b0 :
								in_transition_ph2	? 1'b1 :
								in_measurement 		? 1'b1 : 1'b0;


	// debug vectors
	always @(*) begin
		case(i_dbg_sel)
			4'd00: dbg = {in_reset,in_precharge,in_transition, in_measurement};
			4'd01: dbg = {is_done,state};
			4'd02: dbg = temp_ctr[03:00];
			4'd03: dbg = temp_ctr[07:04];
			4'd04: dbg = temp_ctr[11:08];
			4'd05: dbg = temp_ctr[15:12];
			4'd06: dbg = temp_ctr[19:16];
			4'd07: dbg = tempsens_dat[3:0];
			4'd08: dbg = {tempsens_measure,tempsens_en,tempsens_dat[5:4]};
			4'd09: dbg = {3'b0,i_ts_tempdelay};
			4'd10: dbg = tempsens_final[03:00];
			4'd11: dbg = tempsens_final[07:04];
			4'd12: dbg = tempsens_final[11:08];
			4'd13: dbg = tempsens_final[15:12];
			4'd14: dbg = tempsens_final[19:16];
			4'd15: dbg = {1'b0,o_ts_en,o_ts_prechrgn,i_ts_tempdelay};
		endcase
	end


	// wire signals to tempsens_core
	assign o_ts_dat = tempsens_dat;
	assign o_ts_en = tempsens_en;
	assign o_ts_prechrgn = tempsens_measure; 

endmodule // tempsens_ctrl
`endif 
