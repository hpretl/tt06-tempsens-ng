//	Copyright 2022-2023 Manuel Moser and Harald Pretl, IIC@JKU
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
//	This cell implements a voltage-mode DAC using the SKY130 EINVP cell.
//	Due to the special structure of this tri-state inverter this construction
//	is possible.
//
//  IMPORTANT: Make sure that the synthesis and optimization tools do not mess
//	with the resulting netlist, especially at the node `vout_ana_`!
//
//	CHANGES
//	2023-12-31 (HP) Rename net _notouch_ to _ana_
//	2023-12-31 (HP) Avoid constant in interface
//	2024-01-28 (HP) Reorder single and multicells to get better netnames in PEX

`ifndef __TEMPSENS_VDAC__
`define __TEMPSENS_VDAC__

`default_nettype none
`include "../src/tempsens_vdac_cell.v"

module tempsens_vdac #(parameter BITWIDTH = 6) (
	input wire [BITWIDTH-1:0]	i_data,
	input wire					i_enable,
	output wire					vout_ana_
);

	wire tie0;
	assign tie0 = 1'b0;

	// Single cell for transition from 011..11 to 100..00
	(* keep = "true" *) tempsens_vdac_cell #(.PARALLEL_CELLS(1)) vdac_single (
		.i_sign(tie0),
		.i_data(tie0),
		.i_enable(i_enable & (~i_data[BITWIDTH-1])),
		.vout_ana_(vout_ana_)
	);

	// Further cells
	genvar i;
	generate 
		for (i = 0; i<BITWIDTH-1; i=i+1) begin : parallel_cells
			(* keep = "true" *) tempsens_vdac_cell #(.PARALLEL_CELLS(2**i)) vdac_batch (
				.i_sign(i_data[BITWIDTH-1]),
				.i_data(i_data[i]),
				.i_enable(i_enable),
				.vout_ana_(vout_ana_)
			);
		end
	endgenerate
  
endmodule // tempsens_vdac
`endif
