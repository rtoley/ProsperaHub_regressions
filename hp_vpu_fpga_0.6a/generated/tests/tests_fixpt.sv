// VPU v0.3c - FIXPT Tests (30 tests)

  task automatic test_vssrl_vv_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'h80));
      vrf_write(5'd1, replicate_8(DLEN, 8'h1));
      issue(32'haa2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 8, 8'h40, "test_vssrl_vv_sew8_000");
    end
  endtask

  task automatic test_vssrl_vv_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'hff));
      vrf_write(5'd1, replicate_8(DLEN, 8'h2));
      issue(32'haa2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 8, 8'h40, "test_vssrl_vv_sew8_001");
    end
  endtask

  task automatic test_vssrl_vv_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'h7f));
      vrf_write(5'd1, replicate_8(DLEN, 8'h3));
      issue(32'haa2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 8, 8'h10, "test_vssrl_vv_sew8_002");
    end
  endtask

  task automatic test_vssrl_vv_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'h10));
      vrf_write(5'd1, replicate_8(DLEN, 8'h4));
      issue(32'haa2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 8, 8'h1, "test_vssrl_vv_sew8_003");
    end
  endtask

  task automatic test_vssrl_vv_sew8_004;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'hf0));
      vrf_write(5'd1, replicate_8(DLEN, 8'h1));
      issue(32'haa2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 8, 8'h78, "test_vssrl_vv_sew8_004");
    end
  endtask

  task automatic test_vssrl_vv_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'h80));
      vrf_write(5'd1, replicate_16(DLEN, 16'h1));
      issue(32'haa2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 16, 16'h40, "test_vssrl_vv_sew16_005");
    end
  endtask

  task automatic test_vssrl_vv_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'hff));
      vrf_write(5'd1, replicate_16(DLEN, 16'h2));
      issue(32'haa2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 16, 16'h40, "test_vssrl_vv_sew16_006");
    end
  endtask

  task automatic test_vssrl_vv_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'h7f));
      vrf_write(5'd1, replicate_16(DLEN, 16'h3));
      issue(32'haa2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 16, 16'h10, "test_vssrl_vv_sew16_007");
    end
  endtask

  task automatic test_vssrl_vv_sew16_008;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'h10));
      vrf_write(5'd1, replicate_16(DLEN, 16'h4));
      issue(32'haa2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 16, 16'h1, "test_vssrl_vv_sew16_008");
    end
  endtask

  task automatic test_vssrl_vv_sew16_009;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'hf0));
      vrf_write(5'd1, replicate_16(DLEN, 16'h1));
      issue(32'haa2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 16, 16'h78, "test_vssrl_vv_sew16_009");
    end
  endtask

  task automatic test_vssrl_vv_sew32_010;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN, 32'h80));
      vrf_write(5'd1, replicate_32(DLEN, 32'h1));
      issue(32'haa2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 32, 32'h40, "test_vssrl_vv_sew32_010");
    end
  endtask

  task automatic test_vssrl_vv_sew32_011;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN, 32'hff));
      vrf_write(5'd1, replicate_32(DLEN, 32'h2));
      issue(32'haa2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 32, 32'h40, "test_vssrl_vv_sew32_011");
    end
  endtask

  task automatic test_vssrl_vv_sew32_012;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN, 32'h7f));
      vrf_write(5'd1, replicate_32(DLEN, 32'h3));
      issue(32'haa2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 32, 32'h10, "test_vssrl_vv_sew32_012");
    end
  endtask

  task automatic test_vssrl_vv_sew32_013;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN, 32'h10));
      vrf_write(5'd1, replicate_32(DLEN, 32'h4));
      issue(32'haa2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 32, 32'h1, "test_vssrl_vv_sew32_013");
    end
  endtask

  task automatic test_vssrl_vv_sew32_014;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN, 32'hf0));
      vrf_write(5'd1, replicate_32(DLEN, 32'h1));
      issue(32'haa2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 32, 32'h78, "test_vssrl_vv_sew32_014");
    end
  endtask

  task automatic test_vssra_vv_sew8_015;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'h80));
      vrf_write(5'd1, replicate_8(DLEN, 8'h1));
      issue(32'hae2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 8, 8'hc0, "test_vssra_vv_sew8_015");
    end
  endtask

  task automatic test_vssra_vv_sew8_016;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'hff));
      vrf_write(5'd1, replicate_8(DLEN, 8'h2));
      issue(32'hae2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 8, 8'h0, "test_vssra_vv_sew8_016");
    end
  endtask

  task automatic test_vssra_vv_sew8_017;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'h7f));
      vrf_write(5'd1, replicate_8(DLEN, 8'h3));
      issue(32'hae2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 8, 8'h10, "test_vssra_vv_sew8_017");
    end
  endtask

  task automatic test_vssra_vv_sew8_018;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'h10));
      vrf_write(5'd1, replicate_8(DLEN, 8'h4));
      issue(32'hae2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 8, 8'h1, "test_vssra_vv_sew8_018");
    end
  endtask

  task automatic test_vssra_vv_sew8_019;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'hf0));
      vrf_write(5'd1, replicate_8(DLEN, 8'h1));
      issue(32'hae2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 8, 8'hf8, "test_vssra_vv_sew8_019");
    end
  endtask

  task automatic test_vssra_vv_sew16_020;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'h80));
      vrf_write(5'd1, replicate_16(DLEN, 16'h1));
      issue(32'hae2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 16, 16'h40, "test_vssra_vv_sew16_020");
    end
  endtask

  task automatic test_vssra_vv_sew16_021;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'hff));
      vrf_write(5'd1, replicate_16(DLEN, 16'h2));
      issue(32'hae2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 16, 16'h40, "test_vssra_vv_sew16_021");
    end
  endtask

  task automatic test_vssra_vv_sew16_022;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'h7f));
      vrf_write(5'd1, replicate_16(DLEN, 16'h3));
      issue(32'hae2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 16, 16'h10, "test_vssra_vv_sew16_022");
    end
  endtask

  task automatic test_vssra_vv_sew16_023;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'h10));
      vrf_write(5'd1, replicate_16(DLEN, 16'h4));
      issue(32'hae2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 16, 16'h1, "test_vssra_vv_sew16_023");
    end
  endtask

  task automatic test_vssra_vv_sew16_024;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'hf0));
      vrf_write(5'd1, replicate_16(DLEN, 16'h1));
      issue(32'hae2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 16, 16'h78, "test_vssra_vv_sew16_024");
    end
  endtask

  task automatic test_vssra_vv_sew32_025;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN, 32'h80));
      vrf_write(5'd1, replicate_32(DLEN, 32'h1));
      issue(32'hae2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 32, 32'h40, "test_vssra_vv_sew32_025");
    end
  endtask

  task automatic test_vssra_vv_sew32_026;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN, 32'hff));
      vrf_write(5'd1, replicate_32(DLEN, 32'h2));
      issue(32'hae2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 32, 32'h40, "test_vssra_vv_sew32_026");
    end
  endtask

  task automatic test_vssra_vv_sew32_027;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN, 32'h7f));
      vrf_write(5'd1, replicate_32(DLEN, 32'h3));
      issue(32'hae2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 32, 32'h10, "test_vssra_vv_sew32_027");
    end
  endtask

  task automatic test_vssra_vv_sew32_028;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN, 32'h10));
      vrf_write(5'd1, replicate_32(DLEN, 32'h4));
      issue(32'hae2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 32, 32'h1, "test_vssra_vv_sew32_028");
    end
  endtask

  task automatic test_vssra_vv_sew32_029;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN, 32'hf0));
      vrf_write(5'd1, replicate_32(DLEN, 32'h1));
      issue(32'hae2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 32, 32'h78, "test_vssra_vv_sew32_029");
    end
  endtask


  task automatic run_fixpt_tests;
    begin
      $display("=== FIXPT TESTS (30) ===");
      test_vssrl_vv_sew8_000();
      test_vssrl_vv_sew8_001();
      test_vssrl_vv_sew8_002();
      test_vssrl_vv_sew8_003();
      test_vssrl_vv_sew8_004();
      test_vssrl_vv_sew16_005();
      test_vssrl_vv_sew16_006();
      test_vssrl_vv_sew16_007();
      test_vssrl_vv_sew16_008();
      test_vssrl_vv_sew16_009();
      test_vssrl_vv_sew32_010();
      test_vssrl_vv_sew32_011();
      test_vssrl_vv_sew32_012();
      test_vssrl_vv_sew32_013();
      test_vssrl_vv_sew32_014();
      test_vssra_vv_sew8_015();
      test_vssra_vv_sew8_016();
      test_vssra_vv_sew8_017();
      test_vssra_vv_sew8_018();
      test_vssra_vv_sew8_019();
      test_vssra_vv_sew16_020();
      test_vssra_vv_sew16_021();
      test_vssra_vv_sew16_022();
      test_vssra_vv_sew16_023();
      test_vssra_vv_sew16_024();
      test_vssra_vv_sew32_025();
      test_vssra_vv_sew32_026();
      test_vssra_vv_sew32_027();
      test_vssra_vv_sew32_028();
      test_vssra_vv_sew32_029();
      $display("FIXPT: 30 tests done");
    end
  endtask
