vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xil_defaultlib

vmap xil_defaultlib questa_lib/msim/xil_defaultlib

vlog -work xil_defaultlib -64 \
"../../../../Final_GarbageTrunk.srcs/sources_1/ip/xadc_wiz_1/xadc_wiz_1.v" \


vlog -work xil_defaultlib \
"glbl.v"

