#!/bin/bash
set -e

echo "Compiling SystemC Testbench..."
g++ -I systemc/ \
    -o sim_full \
    systemc/hp_vpu_decode.cpp \
    systemc/hp_vpu_lanes.cpp \
    systemc/golden_model.cpp \
    systemc/tb_full.cpp \
    -lsystemc

echo "Compilation successful. Running simulation..."
./sim_full
