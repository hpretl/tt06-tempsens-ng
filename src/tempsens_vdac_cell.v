//  Copyright 2022-2023 Manuel Moser and Harald Pretl, IIC@JKU
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//		http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//	This cell implements a voltage-mode DAC using the SKY130 EINVP cell.
//	Due to the special structure of this tri-state inverter this construction
//	is possible.
//
//  IMPORTANT: Make sure that the synthesis and optimization tools do not mess
//	with the resulting netlist, especially at the node `vout_ana_`!
//
//	CHANGES
//	2023-12-31 (HP) Rename net _notouch_ to _ana_
//	2024-01-12 (HP) Rename cell

`ifndef __TEMPSENS_VDAC_CELL__
`define __TEMPSENS_VDAC_CELL__

`default_nettype none
/* verilator lint_off INCABSPATH */
/* verilator lint_off UNUSEDSIGNAL */
/* verilator lint_off DECLFILENAME */
//`include "/foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v"
//`include "/foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v"
/* verilator lint_on INCABSPATH */
/* verilator lint_on UNUSEDSIGNAL */
/* verilator lint_on DECLFILENAME */

module tempsens_vdac_cell #(parameter PARALLEL_CELLS = 4) (
	input wire	i_sign,
	input wire	i_data,
	input wire	i_enable,
	output wire	vout_ana_
);

	wire en_vref, en_pupd, npu_pd;

	// Control logic
	assign npu_pd  = ~i_data;
	assign en_pupd = i_enable & (~(i_sign^i_data));
	assign en_vref = i_enable & (i_sign^i_data);

	genvar i;
	generate
		for (i=0; i < PARALLEL_CELLS; i=i+1) begin : einvp_batch
			(* keep = "true" *) sky130_fd_sc_hd__einvp_1 pupd (.A(npu_pd), .TE(en_pupd), .Z(vout_ana_));
			(* keep = "true" *) sky130_fd_sc_hd__einvp_1 vref (.A(vout_ana_), .TE(en_vref), .Z(vout_ana_));
		end
  	endgenerate

endmodule // tempsens_vdac_cell
`endif
