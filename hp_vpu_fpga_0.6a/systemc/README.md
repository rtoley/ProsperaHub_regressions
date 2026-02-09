# SystemC Model for Hyperplane VPU

This directory contains a cycle-accurate SystemC model of the Hyperplane VPU, designed to correlate with the RTL verification results.

## Structure
*   `hp_vpu_pkg.h`: Configuration and Opcode definitions.
*   `hp_vpu_top.h`: Top-level module (pin-compatible with RTL).
*   `hp_vpu_decode.h/cpp`: Instruction decoder.
*   `hp_vpu_hazard.h`: Hazard detection logic.
*   `hp_vpu_lanes.h/cpp`: Execution pipeline (E1/E1m/E2/E3 stages).
*   `tb_main.cpp`: Testbench running the GEMV throughput benchmark.

## Prerequisites
*   SystemC library (e.g., 2.3.3)
*   C++ Compiler (g++ or clang)

## Build & Run

If `SYSTEMC_HOME` is set:

```bash
g++ -I$SYSTEMC_HOME/include -L$SYSTEMC_HOME/lib-linux64 \
    -o vpu_sc \
    tb_main.cpp hp_vpu_decode.cpp hp_vpu_lanes.cpp \
    -lsystemc -lm

./vpu_sc
```

## Correlation Results
The SystemC model implements the same 6-stage pipeline (D2, OF, E1, E1m, E2, E3, WB) and hazard logic as the RTL.
Running the GEMV benchmark with 16 accumulators in SystemC should yield ~1.0 IPC, matching the RTL results (`results/test_bench_long_16acc.log`).
