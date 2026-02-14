#!/bin/bash
set -e

echo "Compiling GEMV Benchmark (Original TB)..."
g++ -I systemc/ \
    -o sim_main \
    systemc/hp_vpu_decode.cpp \
    systemc/hp_vpu_lanes.cpp \
    systemc/golden_model.cpp \
    systemc/tb_main.cpp \
    -lsystemc

echo "Compilation successful. Running simulation..."
./sim_main
