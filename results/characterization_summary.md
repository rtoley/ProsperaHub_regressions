# Throughput Characterization Results

## Task 1: Randomized LLM-like Mix
**Goal**: Craft a RISC-V instruction run of ~500k instructions in a randomized way (LLM-like mix) and check coverage/throughput.

*   **Instruction Count**: 500,000
*   **Mix**: ~60% MACs (vmacc, vnmsac), ~10% LUTs (vexp, vgelu, etc.), ~30% ALU/Logic (vadd, vor, etc.)
*   **Result**:
    *   **Throughput**: **0.8189 IPC** (Instructions Per Cycle)
    *   **Cycles**: 610,573
    *   **Verification**: All registers matched golden model.
*   **Observation**: The pipeline sustains near 1 IPC (0.82) for a mixed workload. This indicates efficient pipelining where ALU operations can interleave with MAC operations, utilizing the separate execution paths (E1->E2 vs E1->E1m->E2) and filling bubbles. The deviations from 1.0 are likely due to:
    *   Structural hazards (e.g. transitions between MAC and Non-MAC where pipeline drain is sometimes needed).
    *   Data hazards (RAW/WAW) inherent in random register selection, despite the deep pipeline.

## Task 2: Long GEMV Kernel
**Goal**: Run a GEMV kernel of similar length and characterize throughput.

*   **Instruction Count**: 500,000 (8 accumulators * 62,500 iterations)
*   **Configuration**: 8 Accumulators (v0-v7), weights pre-loaded.
*   **Result**:
    *   **Throughput**: **0.3279 IPC**
    *   **Cycles**: 1,525,010
    *   **Utilization**: 32.79%
*   **Observation**: The sustained throughput for pure MAC operations saturates at ~0.33 IPC (1 MAC every 3 cycles).
    *   This aligns with the `BENCH_GEMV_RESULTS.md` documentation which states a theoretical peak of 0.333 vec MACs/cycle due to the "2 execution stages (E1 + E1m)" design point.
    *   Even though `mac_stall` wire is removed in RTL v0.6a, the structural or issue limitations for back-to-back MACs likely enforce this 3-cycle cadence to meet timing closure (2 GHz ASIC target).
    *   The randomized test achieved higher IPC because it mixes single-cycle ALU ops with multi-cycle MACs, allowing better overall pipeline utilization than a pure MAC stream.
