# Throughput Characterization Results

## Task 1: Randomized LLM-like Mix
**Goal**: Craft a RISC-V instruction run of ~500k instructions in a randomized way (LLM-like mix) and check coverage/throughput.

*   **Instruction Count**: 500,000
*   **Mix**: ~60% MACs (vmacc, vnmsac), ~10% LUTs (vexp, vgelu, etc.), ~30% ALU/Logic (vadd, vor, etc.)
*   **Result**:
    *   **Throughput**: **0.8189 IPC** (Instructions Per Cycle)
    *   **Cycles**: 610,573
    *   **Verification**: All registers matched golden model.
*   **Observation**: The pipeline sustains high IPC (0.82) for a mixed workload.
    *   The throughput is slightly lower than pure MAC because the random register selection occasionally picks destinations within the hazard window (approx. 9-10 cycles), causing stalls.

## Task 2: Long GEMV Kernel
**Goal**: Run a GEMV kernel of similar length and characterize throughput.

*   **Instruction Count**: 500,000 (16 accumulators * 31,250 iterations)
*   **Configuration**: 16 Accumulators (v0-v15), weights pre-loaded.
*   **Result**:
    *   **Throughput**: **0.9885 IPC**
    *   **Cycles**: 505,821
    *   **Utilization**: 98.85%
*   **Observation**:
    *   Using **16 accumulators** successfully hides the pipeline latency (D1->WB).
    *   With 16 accumulators, the machine sustains **~0.99 IPC**, essentially 1 vector instruction per cycle.
    *   Previous attempts with 8 accumulators yielded only ~0.33 IPC, indicating the effective hazard window is larger than 8 cycles (likely due to the deep 8-stage pipeline plus hazard detection latency).
    *   This confirms the "1 instruction per cycle" sustained throughput capability of the inorder pipeline when properly software-pipelined.
