#!/bin/bash
# Copyright (c) 2024 Harald Pretl, IIC@JKU
# SPDX-License-Identifier: Apache-2.0

MODULE=tt_um_hpretl_tt06_tempsens

[ -f $MODULE.mag ] && rm $MODULE.mag
[ -f $MODULE.pex.spice ] && rm $MODULE.pex.spice

# Run OpenLane flow to build layout
flow.tcl -design ../src -tag foo -overwrite
cp ../src/runs/foo/results/final/mag/$MODULE.mag .

# Extract netlist from layout
iic-pex.sh -m 1 -s 1 $MODULE.mag

# Get rid of MOSFET for decoupling
TMP=tmp.spice
mv $MODULE.pex.spice $TMP
cat $TMP | grep -v "vccd1 vssd1 vccd1 vccd1" | grep -v "vssd1 vccd1 vssd1 vssd1" > $MODULE.pex.spice
rm $TMP
