// VPU v0.3c - LUT Tests (37 tests)

  task automatic test_vexp_v_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      issue(32'h4a2021d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vexp_v_sew8_000");
    end
  endtask

  task automatic test_vexp_v_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h20));
      issue(32'h4a2021d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vexp_v_sew8_001");
    end
  endtask

  task automatic test_vexp_v_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      issue(32'h4a2021d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vexp_v_sew8_002");
    end
  endtask

  task automatic test_vexp_v_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hc0));
      issue(32'h4a2021d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vexp_v_sew8_003");
    end
  endtask

  task automatic test_vexp_v_sew8_004;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      issue(32'h4a2021d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vexp_v_sew8_004");
    end
  endtask

  task automatic test_vexp_v_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      issue(32'h4a2021d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vexp_v_sew16_005");
    end
  endtask

  task automatic test_vexp_v_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h20));
      issue(32'h4a2021d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vexp_v_sew16_006");
    end
  endtask

  task automatic test_vexp_v_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      issue(32'h4a2021d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vexp_v_sew16_007");
    end
  endtask

  task automatic test_vexp_v_sew16_008;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hc0));
      issue(32'h4a2021d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vexp_v_sew16_008");
    end
  endtask

  task automatic test_vexp_v_sew16_009;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      issue(32'h4a2021d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vexp_v_sew16_009");
    end
  endtask

  task automatic test_vrecip_v_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      issue(32'h4a20a1d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vrecip_v_sew8_000");
    end
  endtask

  task automatic test_vrecip_v_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hc0));
      issue(32'h4a20a1d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vrecip_v_sew8_001");
    end
  endtask

  task automatic test_vrecip_v_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      issue(32'h4a20a1d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vrecip_v_sew8_002");
    end
  endtask

  task automatic test_vrecip_v_sew16_003;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      issue(32'h4a20a1d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vrecip_v_sew16_003");
    end
  endtask

  task automatic test_vrecip_v_sew16_004;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h20));
      issue(32'h4a20a1d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vrecip_v_sew16_004");
    end
  endtask

  task automatic test_vrecip_v_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      issue(32'h4a20a1d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vrecip_v_sew16_005");
    end
  endtask

  task automatic test_vrecip_v_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hc0));
      issue(32'h4a20a1d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vrecip_v_sew16_006");
    end
  endtask

  task automatic test_vrecip_v_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      issue(32'h4a20a1d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vrecip_v_sew16_007");
    end
  endtask

  task automatic test_vrsqrt_v_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h20));
      issue(32'h4a2121d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vrsqrt_v_sew8_000");
    end
  endtask

  task automatic test_vrsqrt_v_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      issue(32'h4a2121d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vrsqrt_v_sew8_001");
    end
  endtask

  task automatic test_vrsqrt_v_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hc0));
      issue(32'h4a2121d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vrsqrt_v_sew8_002");
    end
  endtask

  task automatic test_vrsqrt_v_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      issue(32'h4a2121d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vrsqrt_v_sew8_003");
    end
  endtask

  task automatic test_vrsqrt_v_sew16_004;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      issue(32'h4a2121d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vrsqrt_v_sew16_004");
    end
  endtask

  task automatic test_vrsqrt_v_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h20));
      issue(32'h4a2121d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vrsqrt_v_sew16_005");
    end
  endtask

  task automatic test_vrsqrt_v_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      issue(32'h4a2121d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vrsqrt_v_sew16_006");
    end
  endtask

  task automatic test_vrsqrt_v_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hc0));
      issue(32'h4a2121d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vrsqrt_v_sew16_007");
    end
  endtask

  task automatic test_vrsqrt_v_sew16_008;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      issue(32'h4a2121d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vrsqrt_v_sew16_008");
    end
  endtask

  task automatic test_vgelu_v_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      issue(32'h4a21a1d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vgelu_v_sew8_000");
    end
  endtask

  task automatic test_vgelu_v_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h20));
      issue(32'h4a21a1d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vgelu_v_sew8_001");
    end
  endtask

  task automatic test_vgelu_v_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      issue(32'h4a21a1d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vgelu_v_sew8_002");
    end
  endtask

  task automatic test_vgelu_v_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hc0));
      issue(32'h4a21a1d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vgelu_v_sew8_003");
    end
  endtask

  task automatic test_vgelu_v_sew8_004;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      issue(32'h4a21a1d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vgelu_v_sew8_004");
    end
  endtask

  task automatic test_vgelu_v_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      issue(32'h4a21a1d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vgelu_v_sew16_005");
    end
  endtask

  task automatic test_vgelu_v_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h20));
      issue(32'h4a21a1d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vgelu_v_sew16_006");
    end
  endtask

  task automatic test_vgelu_v_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      issue(32'h4a21a1d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vgelu_v_sew16_007");
    end
  endtask

  task automatic test_vgelu_v_sew16_008;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hc0));
      issue(32'h4a21a1d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vgelu_v_sew16_008");
    end
  endtask

  task automatic test_vgelu_v_sew16_009;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      issue(32'h4a21a1d7); wait_done(200);
      check_vrf_nonzero(5'd3, "test_vgelu_v_sew16_009");
    end
  endtask


  task automatic run_lut_tests;
    begin
      $display("=== LUT TESTS (37) ===");
      test_vexp_v_sew8_000();
      test_vexp_v_sew8_001();
      test_vexp_v_sew8_002();
      test_vexp_v_sew8_003();
      test_vexp_v_sew8_004();
      test_vexp_v_sew16_005();
      test_vexp_v_sew16_006();
      test_vexp_v_sew16_007();
      test_vexp_v_sew16_008();
      test_vexp_v_sew16_009();
      test_vrecip_v_sew8_000();
      test_vrecip_v_sew8_001();
      test_vrecip_v_sew8_002();
      test_vrecip_v_sew16_003();
      test_vrecip_v_sew16_004();
      test_vrecip_v_sew16_005();
      test_vrecip_v_sew16_006();
      test_vrecip_v_sew16_007();
      test_vrsqrt_v_sew8_000();
      test_vrsqrt_v_sew8_001();
      test_vrsqrt_v_sew8_002();
      test_vrsqrt_v_sew8_003();
      test_vrsqrt_v_sew16_004();
      test_vrsqrt_v_sew16_005();
      test_vrsqrt_v_sew16_006();
      test_vrsqrt_v_sew16_007();
      test_vrsqrt_v_sew16_008();
      test_vgelu_v_sew8_000();
      test_vgelu_v_sew8_001();
      test_vgelu_v_sew8_002();
      test_vgelu_v_sew8_003();
      test_vgelu_v_sew8_004();
      test_vgelu_v_sew16_005();
      test_vgelu_v_sew16_006();
      test_vgelu_v_sew16_007();
      test_vgelu_v_sew16_008();
      test_vgelu_v_sew16_009();
      $display("LUT: 37 tests done");
    end
  endtask
