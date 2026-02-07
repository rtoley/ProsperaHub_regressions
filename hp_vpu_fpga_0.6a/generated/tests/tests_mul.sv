// VPU v0.3c - MUL Tests (60 tests)

  task automatic test_vmul_vv_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h2));
      vrf_write(5'd1, replicate_8(DLEN,8'h3));
      issue(32'h9620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h6,"test_vmul_vv_sew8_000");
    end
  endtask

  task automatic test_vmul_vv_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h10));
      vrf_write(5'd1, replicate_8(DLEN,8'h10));
      issue(32'h9620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vmul_vv_sew8_001");
    end
  endtask

  task automatic test_vmul_vv_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h2));
      issue(32'h9620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hfe,"test_vmul_vv_sew8_002");
    end
  endtask

  task automatic test_vmul_vv_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h2));
      issue(32'h9620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hfe,"test_vmul_vv_sew8_003");
    end
  endtask

  task automatic test_vmul_vv_sew8_004;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h2));
      issue(32'h9620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vmul_vv_sew8_004");
    end
  endtask

  task automatic test_vmul_vv_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h2));
      vrf_write(5'd1, replicate_16(DLEN,16'h3));
      issue(32'h9620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h6,"test_vmul_vv_sew16_005");
    end
  endtask

  task automatic test_vmul_vv_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h10));
      vrf_write(5'd1, replicate_16(DLEN,16'h10));
      issue(32'h9620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h100,"test_vmul_vv_sew16_006");
    end
  endtask

  task automatic test_vmul_vv_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h2));
      issue(32'h9620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h1fe,"test_vmul_vv_sew16_007");
    end
  endtask

  task automatic test_vmul_vv_sew16_008;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h2));
      issue(32'h9620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hfe,"test_vmul_vv_sew16_008");
    end
  endtask

  task automatic test_vmul_vv_sew16_009;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h2));
      issue(32'h9620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h100,"test_vmul_vv_sew16_009");
    end
  endtask

  task automatic test_vmul_vv_sew32_010;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h2));
      vrf_write(5'd1, replicate_32(DLEN,32'h3));
      issue(32'h9620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h6,"test_vmul_vv_sew32_010");
    end
  endtask

  task automatic test_vmul_vv_sew32_011;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h10));
      vrf_write(5'd1, replicate_32(DLEN,32'h10));
      issue(32'h9620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h100,"test_vmul_vv_sew32_011");
    end
  endtask

  task automatic test_vmul_vv_sew32_012;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h2));
      issue(32'h9620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h1fe,"test_vmul_vv_sew32_012");
    end
  endtask

  task automatic test_vmul_vv_sew32_013;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h2));
      issue(32'h9620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hfe,"test_vmul_vv_sew32_013");
    end
  endtask

  task automatic test_vmul_vv_sew32_014;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h2));
      issue(32'h9620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h100,"test_vmul_vv_sew32_014");
    end
  endtask

  task automatic test_vmulh_vv_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h2));
      vrf_write(5'd1, replicate_8(DLEN,8'h3));
      issue(32'h9e20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vmulh_vv_sew8_000");
    end
  endtask

  task automatic test_vmulh_vv_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h10));
      vrf_write(5'd1, replicate_8(DLEN,8'h10));
      issue(32'h9e20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h1,"test_vmulh_vv_sew8_001");
    end
  endtask

  task automatic test_vmulh_vv_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h2));
      issue(32'h9e20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hff,"test_vmulh_vv_sew8_002");
    end
  endtask

  task automatic test_vmulh_vv_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h2));
      issue(32'h9e20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vmulh_vv_sew8_003");
    end
  endtask

  task automatic test_vmulh_vv_sew8_004;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h2));
      issue(32'h9e20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hff,"test_vmulh_vv_sew8_004");
    end
  endtask

  task automatic test_vmulh_vv_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h2));
      vrf_write(5'd1, replicate_16(DLEN,16'h3));
      issue(32'h9e20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vmulh_vv_sew16_005");
    end
  endtask

  task automatic test_vmulh_vv_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h10));
      vrf_write(5'd1, replicate_16(DLEN,16'h10));
      issue(32'h9e20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vmulh_vv_sew16_006");
    end
  endtask

  task automatic test_vmulh_vv_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h2));
      issue(32'h9e20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vmulh_vv_sew16_007");
    end
  endtask

  task automatic test_vmulh_vv_sew16_008;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h2));
      issue(32'h9e20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vmulh_vv_sew16_008");
    end
  endtask

  task automatic test_vmulh_vv_sew16_009;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h2));
      issue(32'h9e20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vmulh_vv_sew16_009");
    end
  endtask

  task automatic test_vmulh_vv_sew32_010;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h2));
      vrf_write(5'd1, replicate_32(DLEN,32'h3));
      issue(32'h9e20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vmulh_vv_sew32_010");
    end
  endtask

  task automatic test_vmulh_vv_sew32_011;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h10));
      vrf_write(5'd1, replicate_32(DLEN,32'h10));
      issue(32'h9e20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vmulh_vv_sew32_011");
    end
  endtask

  task automatic test_vmulh_vv_sew32_012;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h2));
      issue(32'h9e20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vmulh_vv_sew32_012");
    end
  endtask

  task automatic test_vmulh_vv_sew32_013;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h2));
      issue(32'h9e20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vmulh_vv_sew32_013");
    end
  endtask

  task automatic test_vmulh_vv_sew32_014;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h2));
      issue(32'h9e20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vmulh_vv_sew32_014");
    end
  endtask

  task automatic test_vmulhu_vv_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h2));
      vrf_write(5'd1, replicate_8(DLEN,8'h3));
      issue(32'h9220a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vmulhu_vv_sew8_000");
    end
  endtask

  task automatic test_vmulhu_vv_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h10));
      vrf_write(5'd1, replicate_8(DLEN,8'h10));
      issue(32'h9220a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h1,"test_vmulhu_vv_sew8_001");
    end
  endtask

  task automatic test_vmulhu_vv_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h2));
      issue(32'h9220a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h1,"test_vmulhu_vv_sew8_002");
    end
  endtask

  task automatic test_vmulhu_vv_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h2));
      issue(32'h9220a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vmulhu_vv_sew8_003");
    end
  endtask

  task automatic test_vmulhu_vv_sew8_004;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h2));
      issue(32'h9220a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h1,"test_vmulhu_vv_sew8_004");
    end
  endtask

  task automatic test_vmulhu_vv_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h2));
      vrf_write(5'd1, replicate_16(DLEN,16'h3));
      issue(32'h9220a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vmulhu_vv_sew16_005");
    end
  endtask

  task automatic test_vmulhu_vv_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h10));
      vrf_write(5'd1, replicate_16(DLEN,16'h10));
      issue(32'h9220a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vmulhu_vv_sew16_006");
    end
  endtask

  task automatic test_vmulhu_vv_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h2));
      issue(32'h9220a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vmulhu_vv_sew16_007");
    end
  endtask

  task automatic test_vmulhu_vv_sew16_008;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h2));
      issue(32'h9220a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vmulhu_vv_sew16_008");
    end
  endtask

  task automatic test_vmulhu_vv_sew16_009;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h2));
      issue(32'h9220a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vmulhu_vv_sew16_009");
    end
  endtask

  task automatic test_vmulhu_vv_sew32_010;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h2));
      vrf_write(5'd1, replicate_32(DLEN,32'h3));
      issue(32'h9220a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vmulhu_vv_sew32_010");
    end
  endtask

  task automatic test_vmulhu_vv_sew32_011;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h10));
      vrf_write(5'd1, replicate_32(DLEN,32'h10));
      issue(32'h9220a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vmulhu_vv_sew32_011");
    end
  endtask

  task automatic test_vmulhu_vv_sew32_012;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h2));
      issue(32'h9220a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vmulhu_vv_sew32_012");
    end
  endtask

  task automatic test_vmulhu_vv_sew32_013;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h2));
      issue(32'h9220a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vmulhu_vv_sew32_013");
    end
  endtask

  task automatic test_vmulhu_vv_sew32_014;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h2));
      issue(32'h9220a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vmulhu_vv_sew32_014");
    end
  endtask

  task automatic test_vmulhsu_vv_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h2));
      vrf_write(5'd1, replicate_8(DLEN,8'h3));
      issue(32'h9a20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vmulhsu_vv_sew8_000");
    end
  endtask

  task automatic test_vmulhsu_vv_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h10));
      vrf_write(5'd1, replicate_8(DLEN,8'h10));
      issue(32'h9a20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h1,"test_vmulhsu_vv_sew8_001");
    end
  endtask

  task automatic test_vmulhsu_vv_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h2));
      issue(32'h9a20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hff,"test_vmulhsu_vv_sew8_002");
    end
  endtask

  task automatic test_vmulhsu_vv_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h2));
      issue(32'h9a20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vmulhsu_vv_sew8_003");
    end
  endtask

  task automatic test_vmulhsu_vv_sew8_004;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h2));
      issue(32'h9a20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hff,"test_vmulhsu_vv_sew8_004");
    end
  endtask

  task automatic test_vmulhsu_vv_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h2));
      vrf_write(5'd1, replicate_16(DLEN,16'h3));
      issue(32'h9a20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vmulhsu_vv_sew16_005");
    end
  endtask

  task automatic test_vmulhsu_vv_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h10));
      vrf_write(5'd1, replicate_16(DLEN,16'h10));
      issue(32'h9a20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vmulhsu_vv_sew16_006");
    end
  endtask

  task automatic test_vmulhsu_vv_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h2));
      issue(32'h9a20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vmulhsu_vv_sew16_007");
    end
  endtask

  task automatic test_vmulhsu_vv_sew16_008;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h2));
      issue(32'h9a20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vmulhsu_vv_sew16_008");
    end
  endtask

  task automatic test_vmulhsu_vv_sew16_009;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h2));
      issue(32'h9a20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vmulhsu_vv_sew16_009");
    end
  endtask

  task automatic test_vmulhsu_vv_sew32_010;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h2));
      vrf_write(5'd1, replicate_32(DLEN,32'h3));
      issue(32'h9a20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vmulhsu_vv_sew32_010");
    end
  endtask

  task automatic test_vmulhsu_vv_sew32_011;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h10));
      vrf_write(5'd1, replicate_32(DLEN,32'h10));
      issue(32'h9a20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vmulhsu_vv_sew32_011");
    end
  endtask

  task automatic test_vmulhsu_vv_sew32_012;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h2));
      issue(32'h9a20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vmulhsu_vv_sew32_012");
    end
  endtask

  task automatic test_vmulhsu_vv_sew32_013;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h2));
      issue(32'h9a20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vmulhsu_vv_sew32_013");
    end
  endtask

  task automatic test_vmulhsu_vv_sew32_014;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h2));
      issue(32'h9a20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vmulhsu_vv_sew32_014");
    end
  endtask


  task automatic run_mul_tests;
    begin
      $display("=== MUL TESTS (60) ===");
      test_vmul_vv_sew8_000();
      test_vmul_vv_sew8_001();
      test_vmul_vv_sew8_002();
      test_vmul_vv_sew8_003();
      test_vmul_vv_sew8_004();
      test_vmul_vv_sew16_005();
      test_vmul_vv_sew16_006();
      test_vmul_vv_sew16_007();
      test_vmul_vv_sew16_008();
      test_vmul_vv_sew16_009();
      test_vmul_vv_sew32_010();
      test_vmul_vv_sew32_011();
      test_vmul_vv_sew32_012();
      test_vmul_vv_sew32_013();
      test_vmul_vv_sew32_014();
      test_vmulh_vv_sew8_000();
      test_vmulh_vv_sew8_001();
      test_vmulh_vv_sew8_002();
      test_vmulh_vv_sew8_003();
      test_vmulh_vv_sew8_004();
      test_vmulh_vv_sew16_005();
      test_vmulh_vv_sew16_006();
      test_vmulh_vv_sew16_007();
      test_vmulh_vv_sew16_008();
      test_vmulh_vv_sew16_009();
      test_vmulh_vv_sew32_010();
      test_vmulh_vv_sew32_011();
      test_vmulh_vv_sew32_012();
      test_vmulh_vv_sew32_013();
      test_vmulh_vv_sew32_014();
      test_vmulhu_vv_sew8_000();
      test_vmulhu_vv_sew8_001();
      test_vmulhu_vv_sew8_002();
      test_vmulhu_vv_sew8_003();
      test_vmulhu_vv_sew8_004();
      test_vmulhu_vv_sew16_005();
      test_vmulhu_vv_sew16_006();
      test_vmulhu_vv_sew16_007();
      test_vmulhu_vv_sew16_008();
      test_vmulhu_vv_sew16_009();
      test_vmulhu_vv_sew32_010();
      test_vmulhu_vv_sew32_011();
      test_vmulhu_vv_sew32_012();
      test_vmulhu_vv_sew32_013();
      test_vmulhu_vv_sew32_014();
      test_vmulhsu_vv_sew8_000();
      test_vmulhsu_vv_sew8_001();
      test_vmulhsu_vv_sew8_002();
      test_vmulhsu_vv_sew8_003();
      test_vmulhsu_vv_sew8_004();
      test_vmulhsu_vv_sew16_005();
      test_vmulhsu_vv_sew16_006();
      test_vmulhsu_vv_sew16_007();
      test_vmulhsu_vv_sew16_008();
      test_vmulhsu_vv_sew16_009();
      test_vmulhsu_vv_sew32_010();
      test_vmulhsu_vv_sew32_011();
      test_vmulhsu_vv_sew32_012();
      test_vmulhsu_vv_sew32_013();
      test_vmulhsu_vv_sew32_014();
      $display("MUL: 60 tests done");
    end
  endtask
