# Session Handoff — v0.3e Hazard Audit + Docs Cleanup

**Date:** 2026-02-05
**From:** Claude session 2 (picked up from interrupted session 1)
**Base:** v0.3e (R2A/R2B pipeline split for 300 MHz timing)

---

## What Was Requested (3 items)

1. **Stress tests for new R2A/R2B pipe stage** — NOT DONE. 8 test scenarios identified in `docs/AUDIT_R2AB_HAZARD.md`. No SV code written yet.

2. **Hazard detection audit (RAW + WAW for changed R-pipe depth)** — DONE. Full findings in `docs/AUDIT_R2AB_HAZARD.md`. Summary:
   - RAW for R2A/R2B: correct, dedicated ports wired through
   - WAW: no explicit detection, relies on multicycle_busy serialization (works but fragile)
   - R3 stage: 1-cycle gap, safe only because of multicycle_busy
   - Pipeline depths: E=7, R=8, W=6 (unbalanced)

3. **Docs cleanup (consolidate to 3-4 main docs)** — NOT DONE. Plan below.

4. **Pipeline balancing question** — Answered in audit doc. R pipe is deepest (8), W is shallowest (6). Recommendation: leave as-is while multicycle_busy serializes, balance E to 8 when/if overlapped execution is needed.

---

## Docs Cleanup Plan

User wants 3 main documents + cleanup. Current state: 28 .md files in docs/, most are session handoffs and bug reports that are now resolved.

### Keep and update:
| Doc | Current | Action |
|-----|---------|--------|
| `RVV_COMPLIANCE.md` | 558 lines, good | Update for v0.3e (add R2A/R2B pipeline note) |
| `VPU_ARCHITECTURE.md` | 640 lines, good | Update pipeline diagram for 8-stage R pipe |
| `SCALING.md` | 443 lines | Merge with `PERFORMANCE.md` into single SCALING_AND_PERFORMANCE.md |
| `PERFORMANCE.md` | 635 lines | Merge into above |

### Archive (move to docs/archive/):
Everything else — these are historical session notes and resolved bug reports:
- `BUG_*.md` (3 files) — all fixed
- `HANDOFF_*.md` (4 files) — old sessions
- `SESSION_*.md` (4 files) — old sessions
- `COVERAGE_*.md` (3 files) — superseded by compliance doc
- `NEXT_SESSION*.md` (4 files) — stale TODO lists
- `DEBUG_v1.9.md` — resolved
- `WAW_HAZARD_FIX_PLAN.md` — executed
- `MAC_TIMING_FIX_STATUS.md` — done
- `COMPLIANCE_TEST_ANALYSIS.md` — folded into RVV_COMPLIANCE
- `TEST_INFRASTRUCTURE.md` — fold key info into architecture doc
- `SYNTH_CONFIGS.md` — fold into architecture doc
- `INTEGRATION_GUIDE.md` — keep as 4th doc or fold into architecture

### Final docs/ structure:
```
docs/
  VPU_ARCHITECTURE.md          ← pipeline, blocks, hazard logic, config
  RVV_COMPLIANCE.md            ← instruction coverage, known failures
  SCALING_AND_PERFORMANCE.md   ← timing, throughput, ASIC projections
  INTEGRATION_GUIDE.md         ← CV-X-IF, FPGA, memory interface
  KNOWN_FAILURES.md            ← living doc of open test issues
  AUDIT_R2AB_HAZARD.md         ← this session's findings (move to archive after stress tests pass)
  archive/                     ← everything else
```

---

## Next Session TODO (priority order)

1. **Write 8 stress tests** from `AUDIT_R2AB_HAZARD.md` table — SV testbench, run against VLEN=256/NLANES=4
2. **Decide on pipeline balancing** — if adding dummy E-pipe stage, do it before stress tests
3. **Execute docs cleanup** — move files, merge PERFORMANCE + SCALING, update ARCHITECTURE pipeline diagram
4. **Add `ifdef SPLIT_REDUCTION_PIPELINE`** — Known Issue #3, currently always active
5. **Fix test naming** — Known Issue #4, `make red`/`make cmp` task name mismatches

---

## Files Modified This Session

| File | Change |
|------|--------|
| `docs/AUDIT_R2AB_HAZARD.md` | NEW — hazard audit findings |
| `docs/HANDOFF_v0.3e_session2.md` | NEW — this file |

No RTL changes this session. Audit only.

---

## Original Context Document

The original status document provided at session start is `STATUS_v0.3e.md` (also in project root). It describes the R2→R2A+R2B split, Jules session fixes, test results (1351/1356 pass), and known issues.
