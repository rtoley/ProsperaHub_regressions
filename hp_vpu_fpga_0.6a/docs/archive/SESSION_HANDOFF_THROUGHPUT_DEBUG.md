# Session Handoff: Throughput Test Debug

## Status
A throughput test using compliance infrastructure (golden model verification) was created and is detecting a potential bug.

## Test Results
- `test_throughput_golden(11111, 100)` - **PASS** (100 instructions back-to-back)
- `test_throughput_golden(22222, 200)` - **FAIL** (v27 mismatch)

## The Failure
```
ERROR: VRF[v27] mismatch
  Expected: 0x000300060e800200
  Actual:   0x5fba050c43452500
  Instructions writing to v27:
    [12] instr=0x53102dd7
    [64] instr=0xb78a2dd7
    [135] instr=0x97492dd7
    [153] instr=0xb7a42dd7
    [159] instr=0xbfd2add7
    [187] instr=0x2f860dd7
    [199] instr=0x16508dd7  <-- Last instruction to v27
```

## Decoded Instructions Writing to v27

| Index | Encoding    | funct6 | vs2 | vs1 | funct3 | Operation |
|-------|-------------|--------|-----|-----|--------|-----------|
| 12    | 0x53102dd7  | 20     | 17  | 0   | 2      | vmv.v.v (move) |
| 64    | 0xb78a2dd7  | 45     | 24  | 20  | 2      | vmacc.vv |
| 135   | 0x97492dd7  | 37     | 20  | 18  | 2      | vmul.vv |
| 153   | 0xb7a42dd7  | 45     | 26  | 8   | 2      | vmacc.vv |
| 159   | 0xbfd2add7  | 47     | 29  | 5   | 2      | vnmsac.vv |
| 187   | 0x2f860dd7  | 11     | 24  | 12  | 0      | vand.vv |
| 199   | 0x16508dd7  | 5      | 5   | 1   | 0      | vmin.vv |

## Last Instruction Analysis
The final instruction writing to v27 is:
- `vmin.vv v27, v5, v1` (signed minimum)
- Expected result: 0x000300060e800200
- Actual result: 0x5fba050c43452500

The actual value looks like it could be from an earlier instruction that wasn't supposed to be the final write.

## Key Observation
- Sequential tests (`test_random_pipeline`) with 1000 instructions pass with 0 errors
- Back-to-back throughput test with 200 instructions fails
- This suggests a **pipeline hazard bug** that only manifests under sustained pressure

## Hypothesis
The bug likely involves one of:
1. **WAW hazard** - instruction 199 (vmin, 3 cycles) could be getting overtaken by an earlier MAC (4 cycles)
2. **RAW hazard** - v5 or v1 not ready when vmin reads them
3. **VRF write ordering** - multiple writes happening out of order

## To Debug Next Session

1. Run with `-DHAZARD_ONLY` to verify WAW tests still pass:
   ```
   ./step1_vpu_rtl_validate.sh -z
   ```

2. Add VCD waveform dump to trace the exact timing:
   ```
   Enable VCD in config: "enable_vcd_dump": true
   ```

3. Add tracing around instruction 187-199 to see pipeline state when vmin.vv issues

4. Check if instruction 153 (vmacc v27) or 159 (vnmsac v27) is the one actually winning the race

## Files Modified This Session
- `tb/hp_vpu_tb.sv` - Added:
  - `test_waw_widening_vs_mac()` - WAW test for widening vs MAC
  - `test_waw_widening_vs_alu()` - WAW test for widening vs ALU
  - `test_waw_multi_same_dest()` - Multiple instrs to same vd
  - `test_throughput_golden()` - Back-to-back throughput test with golden model
  - Fixed `compute_golden_result()` to use `DLEN/8` instead of hardcoded 32

## Commands to Reproduce
```bash
cd hyperplane_vpu_v1.9
./step1_vpu_rtl_validate.sh    # Should show 112/113 pass, 1 fail
```

The failing test is `test_throughput_golden(22222, 200)`.
