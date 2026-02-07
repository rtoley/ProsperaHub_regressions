// VPU v0.3c - Modular Tests Master Include
// Total: 1272 tests across 15 categories
// NEW in v0.3c: mask, maskop, perm, wide, fixpt, int4

`include "tests_alu_vv.sv"
`include "tests_alu_vx.sv"
`include "tests_alu_vi.sv"
`include "tests_mul.sv"
`include "tests_mac.sv"
`include "tests_sat.sv"
`include "tests_cmp.sv"
`include "tests_red.sv"
`include "tests_lut.sv"
`include "tests_mask.sv"
`include "tests_maskop.sv"
`include "tests_perm.sv"
`include "tests_wide.sv"
`include "tests_fixpt.sv"
`include "tests_int4.sv"
`include "tests_known_fail.sv"

  // Run all passing tests
  task automatic run_full_tests;
    begin
      $display("");
      $display("========================================");
      $display("  FULL TEST SUITE (1272 tests)");
      $display("  VLEN=%0d, DLEN=%0d", VLEN, DLEN);
      $display("========================================");
      run_alu_vv_tests();
      run_alu_vx_tests();
      run_alu_vi_tests();
      run_mul_tests();
      run_mac_tests();
      run_sat_tests();
      run_cmp_tests();
      run_red_tests();
      run_lut_tests();
      run_mask_tests();
      run_maskop_tests();
      run_perm_tests();
      run_wide_tests();
      run_fixpt_tests();
      run_int4_tests();
      $display("FULL: 1272 tests completed");
    end
  endtask

  // Quick smoke test (one per category)
  task automatic run_quick_tests;
    begin
      $display("");
      $display("======== QUICK SMOKE TEST ========");
      test_vadd_vv_sew8_000();
      test_vadd_vx_sew8_000();
      test_vadd_vi_sew8_000();
      test_vmul_vv_sew8_000();
      test_vmacc_vv_sew8_000();
      test_vsaddu_vv_sew8_000();
      test_vmseq_vv_sew8_000();
      test_vredsum_vs_sew8_000();
      test_vexp_v_sew8_000();
      test_vmand_mm_000();
      test_vcpop_m_000();
      test_vmv_v_v_sew8_000();
      test_vwaddu_vv_sew8_000();
      test_vssrl_vv_sew8_000();
      test_vpack4_v_sew8_000();
      $display("QUICK: 15 tests completed");
    end
  endtask

  // Run everything including known-failing tests
  task automatic run_all_tests;
    begin
      run_full_tests();
      run_known_fail_tests();
    end
  endtask
