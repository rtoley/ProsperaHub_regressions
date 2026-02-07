# Session Status: v1.8a Hazard Test Development

## Date: 2024-01-31

## Summary
Working on creating a standalone hazard pattern test to debug MAC/MUL pipeline hazards.

## Bug Being Investigated
- **File**: `docs/BUG_E1_HANDOFF_DUPLICATE.md`
- **Symptom**: Throughput test fails with VRF mismatch at `-t 500 -s 99999`
- **Root cause**: E1 handoff duplicate execution - instruction executes twice

## Fix Already Applied (partial)
The `e1_handoff_capture` fix from the bug document has been applied:
- `rtl/hp_vpu_lanes.sv`: Added `e1_handoff_capture_o` output (line 60, 1168-1169)
- `rtl/hp_vpu_top.sv`: Modified OF clearing condition (line 386), added wire (line 411), connected to lanes (line 462)

## Current Status

### Main Testbench (tb/hp_vpu_tb.sv)
- **Status**: COMPILES OK
- Removed broken hazard test task that was added during this session
- HAZARD_ONLY ifdef removed
- Original functionality preserved

### Standalone Hazard Test (tb/hp_vpu_hazard_test.sv)
- **Status**: DOES NOT COMPILE with iverilog
- **Issue**: iverilog 12.0 with `-g2012` flag has bugs with `reg [DLEN-1:0]` and `for` loops
- The test compiles without `-g2012`, but the RTL requires `-g2012` for SystemVerilog package support
- This is a known iverilog limitation

### Test Runner Script (run_hazard_test.sh)
- **Status**: Created but not functional (blocked by compile issue)

## Files Modified This Session
1. `tb/hp_vpu_tb.sv` - Removed broken hazard test task, removed HAZARD_ONLY ifdef
2. `tb/hp_vpu_hazard_test.sv` - Created (but doesn't compile)
3. `run_hazard_test.sh` - Created
4. `step1_vpu_rtl_validate.sh` - Added `-z/--hazard` option (not functional)

## Next Steps

### Option 1: Use Different Simulator
- Verilator or commercial simulator may not have this iverilog bug
- The hazard test code is correct, just needs a different tool

### Option 2: Integrate Hazard Test into Main Testbench
- Add hazard test as a task in the existing testbench (which already compiles)
- Call it via a plusarg like `+hazard_test=1`
- This approach matches how the existing tasks work

### Option 3: Simplify Hazard Test
- Remove parameterized widths, use hardcoded values
- May lose generality but would compile

## Recommended Next Session Approach
1. Start by running the original failing test to confirm bug still exists
2. Try Option 2 - add hazard test as task to main testbench
3. Run hazard test at various distances to find the failing case
4. Once canary test isolated, debug the RTL hazard logic
5. **BACKUP FREQUENTLY** - create tar after each successful change

## Commands for Next Session
```bash
# Check if original bug still exists
./step1_vpu_rtl_validate.sh -t 500 -s 99999

# Compile main testbench (should work)
iverilog -g2012 -DSIMULATION -I generated -o sim/test.vvp \
  generated/hp_vpu_pkg.sv rtl/*.sv tb/hp_vpu_tb.sv

# Create backup
tar -czf hyperplane_vpu_v1.8a_backup.tar.gz hyperplane_vpu_v1.8a/
```

## Key Insight from User
> "the hazard logic must address mac/mul instruction pipeline x other pipelines (r1/r2) for RAW and WAW hazards"
> "with dist = 2, the mac followed by a non-mac instruction was causing some corruption - this could be a canary in the coal mine"
