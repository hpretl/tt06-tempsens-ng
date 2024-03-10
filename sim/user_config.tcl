# Set design name
set ::env(DESIGN_NAME) "tt_um_hpretl_tt06_tempsens"
# Set Verilog source files
set ::env(VERILOG_FILES) [glob $::env(DESIGN_DIR)/tt_um_hpretl_tt06_tempsens.v]
# Interpret instantiated SKY130-Standardcells as blackbox
set ::env(SYNTH_READ_BLACKBOX_LIB) 1
# Rexeg to flag nets where buffers are not allowed (analog signals)
set ::env(RSZ_DONT_TOUCH_RX) "_ana_"
# No linting
set ::env(RUN_LINTER) 0
set ::env(QUIT_ON_SYNTH_CHECKS) 0
# Set die area
set ::env(DIE_AREA) "0 0 100 100"
