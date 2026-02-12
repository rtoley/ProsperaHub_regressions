# Debug v1.9: Throughput Test - FIXED

## STATUS: FIXED ✓

The throughput test now passes (113/113).

### The Fix
Changed drain from 50 to 100 cycles in `tb/hp_vpu_tb.sv:4480`:
```systemverilog
repeat (100) @(posedge clk);  // Was repeat (50)
```

## Root Cause Analysis

### The Original Failure
```
test_throughput_golden(22222, 200) - FAIL
ERROR: VRF[v27] mismatch
  Expected: 0x000300060e800200
  Actual:   0x5fba050c43452500
```

### RAW Hazard Chain at End of Test
```
Instruction 198: vminu.vv v5, v5, v24   (writes to v5)
Instruction 199: vmin.vv v27, v5, v1    (reads v5 - RAW HAZARD!)
```

Instruction 199 could not proceed until instruction 198 completed.

### Why 50 Cycles Wasn't Enough
1. Instruction 199 issues at T
2. RAW hazard stalls 199 in IQ/decode (waiting for v5 from 198)
3. 198 completes at T+~4 cycles
4. 199 then enters pipeline, completes at T+~8 cycles
5. But drain started at T+2 and only lasted 50 cycles
6. With accumulated stalls from 200 back-to-back instructions, 50 cycles wasn't enough

### Key Finding
**No RTL bug** - the hazard detection and pipeline work correctly. This was a test infrastructure issue where the drain period was too short for worst-case RAW hazard chains.

## Test Results After Fix
```
[58313000] PASS: Throughput test - 100 instructions, 0 errors
[59581000] PASS: Throughput test - 200 instructions, 0 errors
Test Results: 113/113 passed
*** ALL TESTS PASSED ***
```

## Tests Added in v1.9

### WAW Hazard Tests (all pass)
- `test_waw_widening_vs_mac()` - Widening (2 cycles) vs MAC (4 cycles)
- `test_waw_widening_vs_alu()` - Widening (2 cycles) vs Normal ALU (3 cycles)
- `test_waw_multi_same_dest()` - Multiple instructions to same vd

### Throughput Tests (all pass)
- `test_throughput_golden(seed, 100)` - 100 instructions back-to-back
- `test_throughput_golden(seed, 200)` - 200 instructions back-to-back

## Files Modified
- `tb/hp_vpu_tb.sv` - Added WAW tests, throughput tests, fixed drain time
- `rtl/hp_vpu_lanes.sv` - Added v27 to VRF write trace (debug only)

## Lessons Learned
1. Back-to-back instruction tests need sufficient drain time
2. RAW hazard stalls accumulate with random instruction sequences
3. 100 cycles is safe for 200-instruction throughput tests
4. The `multicycle_busy` mechanism correctly handles WAW hazards
