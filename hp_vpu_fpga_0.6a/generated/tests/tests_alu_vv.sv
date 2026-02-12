// VPU v0.3c - ALU .vv Tests (234 tests)

  task automatic test_vadd_vv_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      issue(32'h022081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vadd_vv_sew8_000");
    end
  endtask

  task automatic test_vadd_vv_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h022081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h2,"test_vadd_vv_sew8_001");
    end
  endtask

  task automatic test_vadd_vv_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h022081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vadd_vv_sew8_002");
    end
  endtask

  task automatic test_vadd_vv_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      issue(32'h022081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hff,"test_vadd_vv_sew8_003");
    end
  endtask

  task automatic test_vadd_vv_sew8_004;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h80));
      issue(32'h022081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hff,"test_vadd_vv_sew8_004");
    end
  endtask

  task automatic test_vadd_vv_sew8_005;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h55));
      vrf_write(5'd1, replicate_8(DLEN,8'haa));
      issue(32'h022081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hff,"test_vadd_vv_sew8_005");
    end
  endtask

  task automatic test_vadd_vv_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      issue(32'h022081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vadd_vv_sew16_006");
    end
  endtask

  task automatic test_vadd_vv_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h022081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h2,"test_vadd_vv_sew16_007");
    end
  endtask

  task automatic test_vadd_vv_sew16_008;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h022081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h100,"test_vadd_vv_sew16_008");
    end
  endtask

  task automatic test_vadd_vv_sew16_009;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      issue(32'h022081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hff,"test_vadd_vv_sew16_009");
    end
  endtask

  task automatic test_vadd_vv_sew16_010;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h80));
      issue(32'h022081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hff,"test_vadd_vv_sew16_010");
    end
  endtask

  task automatic test_vadd_vv_sew16_011;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h55));
      vrf_write(5'd1, replicate_16(DLEN,16'haa));
      issue(32'h022081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hff,"test_vadd_vv_sew16_011");
    end
  endtask

  task automatic test_vadd_vv_sew32_012;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      issue(32'h022081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vadd_vv_sew32_012");
    end
  endtask

  task automatic test_vadd_vv_sew32_013;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h022081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h2,"test_vadd_vv_sew32_013");
    end
  endtask

  task automatic test_vadd_vv_sew32_014;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h022081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h100,"test_vadd_vv_sew32_014");
    end
  endtask

  task automatic test_vadd_vv_sew32_015;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      issue(32'h022081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hff,"test_vadd_vv_sew32_015");
    end
  endtask

  task automatic test_vadd_vv_sew32_016;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h80));
      issue(32'h022081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hff,"test_vadd_vv_sew32_016");
    end
  endtask

  task automatic test_vadd_vv_sew32_017;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h55));
      vrf_write(5'd1, replicate_32(DLEN,32'haa));
      issue(32'h022081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hff,"test_vadd_vv_sew32_017");
    end
  endtask

  task automatic test_vsub_vv_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      issue(32'h0a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vsub_vv_sew8_000");
    end
  endtask

  task automatic test_vsub_vv_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h0a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vsub_vv_sew8_001");
    end
  endtask

  task automatic test_vsub_vv_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h0a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hfe,"test_vsub_vv_sew8_002");
    end
  endtask

  task automatic test_vsub_vv_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      issue(32'h0a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h1,"test_vsub_vv_sew8_003");
    end
  endtask

  task automatic test_vsub_vv_sew8_004;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h80));
      issue(32'h0a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hff,"test_vsub_vv_sew8_004");
    end
  endtask

  task automatic test_vsub_vv_sew8_005;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h55));
      vrf_write(5'd1, replicate_8(DLEN,8'haa));
      issue(32'h0a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hab,"test_vsub_vv_sew8_005");
    end
  endtask

  task automatic test_vsub_vv_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      issue(32'h0a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vsub_vv_sew16_006");
    end
  endtask

  task automatic test_vsub_vv_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h0a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vsub_vv_sew16_007");
    end
  endtask

  task automatic test_vsub_vv_sew16_008;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h0a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hfe,"test_vsub_vv_sew16_008");
    end
  endtask

  task automatic test_vsub_vv_sew16_009;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      issue(32'h0a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h1,"test_vsub_vv_sew16_009");
    end
  endtask

  task automatic test_vsub_vv_sew16_010;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h80));
      issue(32'h0a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hffff,"test_vsub_vv_sew16_010");
    end
  endtask

  task automatic test_vsub_vv_sew16_011;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h55));
      vrf_write(5'd1, replicate_16(DLEN,16'haa));
      issue(32'h0a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hffab,"test_vsub_vv_sew16_011");
    end
  endtask

  task automatic test_vsub_vv_sew32_012;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      issue(32'h0a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vsub_vv_sew32_012");
    end
  endtask

  task automatic test_vsub_vv_sew32_013;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h0a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vsub_vv_sew32_013");
    end
  endtask

  task automatic test_vsub_vv_sew32_014;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h0a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hfe,"test_vsub_vv_sew32_014");
    end
  endtask

  task automatic test_vsub_vv_sew32_015;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      issue(32'h0a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h1,"test_vsub_vv_sew32_015");
    end
  endtask

  task automatic test_vsub_vv_sew32_016;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h80));
      issue(32'h0a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hffffffff,"test_vsub_vv_sew32_016");
    end
  endtask

  task automatic test_vsub_vv_sew32_017;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h55));
      vrf_write(5'd1, replicate_32(DLEN,32'haa));
      issue(32'h0a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hffffffab,"test_vsub_vv_sew32_017");
    end
  endtask

  task automatic test_vrsub_vv_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      issue(32'h0e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vrsub_vv_sew8_000");
    end
  endtask

  task automatic test_vrsub_vv_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h0e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vrsub_vv_sew8_001");
    end
  endtask

  task automatic test_vrsub_vv_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h0e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h2,"test_vrsub_vv_sew8_002");
    end
  endtask

  task automatic test_vrsub_vv_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      issue(32'h0e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hff,"test_vrsub_vv_sew8_003");
    end
  endtask

  task automatic test_vrsub_vv_sew8_004;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h80));
      issue(32'h0e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h1,"test_vrsub_vv_sew8_004");
    end
  endtask

  task automatic test_vrsub_vv_sew8_005;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h55));
      vrf_write(5'd1, replicate_8(DLEN,8'haa));
      issue(32'h0e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h55,"test_vrsub_vv_sew8_005");
    end
  endtask

  task automatic test_vrsub_vv_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      issue(32'h0e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vrsub_vv_sew16_006");
    end
  endtask

  task automatic test_vrsub_vv_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h0e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vrsub_vv_sew16_007");
    end
  endtask

  task automatic test_vrsub_vv_sew16_008;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h0e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hff02,"test_vrsub_vv_sew16_008");
    end
  endtask

  task automatic test_vrsub_vv_sew16_009;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      issue(32'h0e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hffff,"test_vrsub_vv_sew16_009");
    end
  endtask

  task automatic test_vrsub_vv_sew16_010;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h80));
      issue(32'h0e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h1,"test_vrsub_vv_sew16_010");
    end
  endtask

  task automatic test_vrsub_vv_sew16_011;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h55));
      vrf_write(5'd1, replicate_16(DLEN,16'haa));
      issue(32'h0e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h55,"test_vrsub_vv_sew16_011");
    end
  endtask

  task automatic test_vrsub_vv_sew32_012;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      issue(32'h0e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vrsub_vv_sew32_012");
    end
  endtask

  task automatic test_vrsub_vv_sew32_013;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h0e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vrsub_vv_sew32_013");
    end
  endtask

  task automatic test_vrsub_vv_sew32_014;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h0e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hffffff02,"test_vrsub_vv_sew32_014");
    end
  endtask

  task automatic test_vrsub_vv_sew32_015;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      issue(32'h0e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hffffffff,"test_vrsub_vv_sew32_015");
    end
  endtask

  task automatic test_vrsub_vv_sew32_016;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h80));
      issue(32'h0e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h1,"test_vrsub_vv_sew32_016");
    end
  endtask

  task automatic test_vrsub_vv_sew32_017;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h55));
      vrf_write(5'd1, replicate_32(DLEN,32'haa));
      issue(32'h0e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h55,"test_vrsub_vv_sew32_017");
    end
  endtask

  task automatic test_vand_vv_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      issue(32'h262081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vand_vv_sew8_000");
    end
  endtask

  task automatic test_vand_vv_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h262081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h1,"test_vand_vv_sew8_001");
    end
  endtask

  task automatic test_vand_vv_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h262081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h1,"test_vand_vv_sew8_002");
    end
  endtask

  task automatic test_vand_vv_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      issue(32'h262081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vand_vv_sew8_003");
    end
  endtask

  task automatic test_vand_vv_sew8_004;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h80));
      issue(32'h262081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vand_vv_sew8_004");
    end
  endtask

  task automatic test_vand_vv_sew8_005;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h55));
      vrf_write(5'd1, replicate_8(DLEN,8'haa));
      issue(32'h262081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vand_vv_sew8_005");
    end
  endtask

  task automatic test_vand_vv_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      issue(32'h262081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vand_vv_sew16_006");
    end
  endtask

  task automatic test_vand_vv_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h262081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h1,"test_vand_vv_sew16_007");
    end
  endtask

  task automatic test_vand_vv_sew16_008;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h262081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h1,"test_vand_vv_sew16_008");
    end
  endtask

  task automatic test_vand_vv_sew16_009;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      issue(32'h262081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vand_vv_sew16_009");
    end
  endtask

  task automatic test_vand_vv_sew16_010;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h80));
      issue(32'h262081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vand_vv_sew16_010");
    end
  endtask

  task automatic test_vand_vv_sew16_011;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h55));
      vrf_write(5'd1, replicate_16(DLEN,16'haa));
      issue(32'h262081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vand_vv_sew16_011");
    end
  endtask

  task automatic test_vand_vv_sew32_012;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      issue(32'h262081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vand_vv_sew32_012");
    end
  endtask

  task automatic test_vand_vv_sew32_013;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h262081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h1,"test_vand_vv_sew32_013");
    end
  endtask

  task automatic test_vand_vv_sew32_014;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h262081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h1,"test_vand_vv_sew32_014");
    end
  endtask

  task automatic test_vand_vv_sew32_015;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      issue(32'h262081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vand_vv_sew32_015");
    end
  endtask

  task automatic test_vand_vv_sew32_016;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h80));
      issue(32'h262081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vand_vv_sew32_016");
    end
  endtask

  task automatic test_vand_vv_sew32_017;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h55));
      vrf_write(5'd1, replicate_32(DLEN,32'haa));
      issue(32'h262081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vand_vv_sew32_017");
    end
  endtask

  task automatic test_vor_vv_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      issue(32'h2a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vor_vv_sew8_000");
    end
  endtask

  task automatic test_vor_vv_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h2a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h1,"test_vor_vv_sew8_001");
    end
  endtask

  task automatic test_vor_vv_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h2a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hff,"test_vor_vv_sew8_002");
    end
  endtask

  task automatic test_vor_vv_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      issue(32'h2a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hff,"test_vor_vv_sew8_003");
    end
  endtask

  task automatic test_vor_vv_sew8_004;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h80));
      issue(32'h2a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hff,"test_vor_vv_sew8_004");
    end
  endtask

  task automatic test_vor_vv_sew8_005;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h55));
      vrf_write(5'd1, replicate_8(DLEN,8'haa));
      issue(32'h2a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hff,"test_vor_vv_sew8_005");
    end
  endtask

  task automatic test_vor_vv_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      issue(32'h2a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vor_vv_sew16_006");
    end
  endtask

  task automatic test_vor_vv_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h2a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h1,"test_vor_vv_sew16_007");
    end
  endtask

  task automatic test_vor_vv_sew16_008;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h2a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hff,"test_vor_vv_sew16_008");
    end
  endtask

  task automatic test_vor_vv_sew16_009;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      issue(32'h2a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hff,"test_vor_vv_sew16_009");
    end
  endtask

  task automatic test_vor_vv_sew16_010;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h80));
      issue(32'h2a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hff,"test_vor_vv_sew16_010");
    end
  endtask

  task automatic test_vor_vv_sew16_011;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h55));
      vrf_write(5'd1, replicate_16(DLEN,16'haa));
      issue(32'h2a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hff,"test_vor_vv_sew16_011");
    end
  endtask

  task automatic test_vor_vv_sew32_012;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      issue(32'h2a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vor_vv_sew32_012");
    end
  endtask

  task automatic test_vor_vv_sew32_013;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h2a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h1,"test_vor_vv_sew32_013");
    end
  endtask

  task automatic test_vor_vv_sew32_014;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h2a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hff,"test_vor_vv_sew32_014");
    end
  endtask

  task automatic test_vor_vv_sew32_015;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      issue(32'h2a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hff,"test_vor_vv_sew32_015");
    end
  endtask

  task automatic test_vor_vv_sew32_016;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h80));
      issue(32'h2a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hff,"test_vor_vv_sew32_016");
    end
  endtask

  task automatic test_vor_vv_sew32_017;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h55));
      vrf_write(5'd1, replicate_32(DLEN,32'haa));
      issue(32'h2a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hff,"test_vor_vv_sew32_017");
    end
  endtask

  task automatic test_vxor_vv_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      issue(32'h2e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vxor_vv_sew8_000");
    end
  endtask

  task automatic test_vxor_vv_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h2e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vxor_vv_sew8_001");
    end
  endtask

  task automatic test_vxor_vv_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h2e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hfe,"test_vxor_vv_sew8_002");
    end
  endtask

  task automatic test_vxor_vv_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      issue(32'h2e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hff,"test_vxor_vv_sew8_003");
    end
  endtask

  task automatic test_vxor_vv_sew8_004;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h80));
      issue(32'h2e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hff,"test_vxor_vv_sew8_004");
    end
  endtask

  task automatic test_vxor_vv_sew8_005;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h55));
      vrf_write(5'd1, replicate_8(DLEN,8'haa));
      issue(32'h2e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hff,"test_vxor_vv_sew8_005");
    end
  endtask

  task automatic test_vxor_vv_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      issue(32'h2e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vxor_vv_sew16_006");
    end
  endtask

  task automatic test_vxor_vv_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h2e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vxor_vv_sew16_007");
    end
  endtask

  task automatic test_vxor_vv_sew16_008;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h2e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hfe,"test_vxor_vv_sew16_008");
    end
  endtask

  task automatic test_vxor_vv_sew16_009;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      issue(32'h2e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hff,"test_vxor_vv_sew16_009");
    end
  endtask

  task automatic test_vxor_vv_sew16_010;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h80));
      issue(32'h2e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hff,"test_vxor_vv_sew16_010");
    end
  endtask

  task automatic test_vxor_vv_sew16_011;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h55));
      vrf_write(5'd1, replicate_16(DLEN,16'haa));
      issue(32'h2e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hff,"test_vxor_vv_sew16_011");
    end
  endtask

  task automatic test_vxor_vv_sew32_012;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      issue(32'h2e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vxor_vv_sew32_012");
    end
  endtask

  task automatic test_vxor_vv_sew32_013;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h2e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vxor_vv_sew32_013");
    end
  endtask

  task automatic test_vxor_vv_sew32_014;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h2e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hfe,"test_vxor_vv_sew32_014");
    end
  endtask

  task automatic test_vxor_vv_sew32_015;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      issue(32'h2e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hff,"test_vxor_vv_sew32_015");
    end
  endtask

  task automatic test_vxor_vv_sew32_016;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h80));
      issue(32'h2e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hff,"test_vxor_vv_sew32_016");
    end
  endtask

  task automatic test_vxor_vv_sew32_017;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h55));
      vrf_write(5'd1, replicate_32(DLEN,32'haa));
      issue(32'h2e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hff,"test_vxor_vv_sew32_017");
    end
  endtask

  task automatic test_vsll_vv_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      issue(32'h962081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vsll_vv_sew8_000");
    end
  endtask

  task automatic test_vsll_vv_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h962081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h2,"test_vsll_vv_sew8_001");
    end
  endtask

  task automatic test_vsll_vv_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h962081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hfe,"test_vsll_vv_sew8_002");
    end
  endtask

  task automatic test_vsll_vv_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      issue(32'h962081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vsll_vv_sew8_003");
    end
  endtask

  task automatic test_vsll_vv_sew8_004;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h80));
      issue(32'h962081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h7f,"test_vsll_vv_sew8_004");
    end
  endtask

  task automatic test_vsll_vv_sew8_005;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h55));
      vrf_write(5'd1, replicate_8(DLEN,8'haa));
      issue(32'h962081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h54,"test_vsll_vv_sew8_005");
    end
  endtask

  task automatic test_vsll_vv_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      issue(32'h962081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vsll_vv_sew16_006");
    end
  endtask

  task automatic test_vsll_vv_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h962081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h2,"test_vsll_vv_sew16_007");
    end
  endtask

  task automatic test_vsll_vv_sew16_008;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h962081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h1fe,"test_vsll_vv_sew16_008");
    end
  endtask

  task automatic test_vsll_vv_sew16_009;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      issue(32'h962081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vsll_vv_sew16_009");
    end
  endtask

  task automatic test_vsll_vv_sew16_010;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h80));
      issue(32'h962081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h7f,"test_vsll_vv_sew16_010");
    end
  endtask

  task automatic test_vsll_vv_sew16_011;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h55));
      vrf_write(5'd1, replicate_16(DLEN,16'haa));
      issue(32'h962081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h5400,"test_vsll_vv_sew16_011");
    end
  endtask

  task automatic test_vsll_vv_sew32_012;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      issue(32'h962081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vsll_vv_sew32_012");
    end
  endtask

  task automatic test_vsll_vv_sew32_013;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h962081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h2,"test_vsll_vv_sew32_013");
    end
  endtask

  task automatic test_vsll_vv_sew32_014;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h962081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h1fe,"test_vsll_vv_sew32_014");
    end
  endtask

  task automatic test_vsll_vv_sew32_015;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      issue(32'h962081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vsll_vv_sew32_015");
    end
  endtask

  task automatic test_vsll_vv_sew32_016;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h80));
      issue(32'h962081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h7f,"test_vsll_vv_sew32_016");
    end
  endtask

  task automatic test_vsll_vv_sew32_017;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h55));
      vrf_write(5'd1, replicate_32(DLEN,32'haa));
      issue(32'h962081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h15400,"test_vsll_vv_sew32_017");
    end
  endtask

  task automatic test_vsrl_vv_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      issue(32'ha22081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vsrl_vv_sew8_000");
    end
  endtask

  task automatic test_vsrl_vv_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'ha22081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vsrl_vv_sew8_001");
    end
  endtask

  task automatic test_vsrl_vv_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'ha22081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h7f,"test_vsrl_vv_sew8_002");
    end
  endtask

  task automatic test_vsrl_vv_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      issue(32'ha22081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h1,"test_vsrl_vv_sew8_003");
    end
  endtask

  task automatic test_vsrl_vv_sew8_004;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h80));
      issue(32'ha22081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h7f,"test_vsrl_vv_sew8_004");
    end
  endtask

  task automatic test_vsrl_vv_sew8_005;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h55));
      vrf_write(5'd1, replicate_8(DLEN,8'haa));
      issue(32'ha22081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h15,"test_vsrl_vv_sew8_005");
    end
  endtask

  task automatic test_vsrl_vv_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      issue(32'ha22081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vsrl_vv_sew16_006");
    end
  endtask

  task automatic test_vsrl_vv_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'ha22081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vsrl_vv_sew16_007");
    end
  endtask

  task automatic test_vsrl_vv_sew16_008;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'ha22081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h7f,"test_vsrl_vv_sew16_008");
    end
  endtask

  task automatic test_vsrl_vv_sew16_009;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      issue(32'ha22081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vsrl_vv_sew16_009");
    end
  endtask

  task automatic test_vsrl_vv_sew16_010;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h80));
      issue(32'ha22081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h7f,"test_vsrl_vv_sew16_010");
    end
  endtask

  task automatic test_vsrl_vv_sew16_011;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h55));
      vrf_write(5'd1, replicate_16(DLEN,16'haa));
      issue(32'ha22081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vsrl_vv_sew16_011");
    end
  endtask

  task automatic test_vsrl_vv_sew32_012;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      issue(32'ha22081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vsrl_vv_sew32_012");
    end
  endtask

  task automatic test_vsrl_vv_sew32_013;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'ha22081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vsrl_vv_sew32_013");
    end
  endtask

  task automatic test_vsrl_vv_sew32_014;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'ha22081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h7f,"test_vsrl_vv_sew32_014");
    end
  endtask

  task automatic test_vsrl_vv_sew32_015;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      issue(32'ha22081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vsrl_vv_sew32_015");
    end
  endtask

  task automatic test_vsrl_vv_sew32_016;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h80));
      issue(32'ha22081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h7f,"test_vsrl_vv_sew32_016");
    end
  endtask

  task automatic test_vsrl_vv_sew32_017;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h55));
      vrf_write(5'd1, replicate_32(DLEN,32'haa));
      issue(32'ha22081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vsrl_vv_sew32_017");
    end
  endtask

  task automatic test_vsra_vv_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      issue(32'ha62081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vsra_vv_sew8_000");
    end
  endtask

  task automatic test_vsra_vv_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'ha62081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vsra_vv_sew8_001");
    end
  endtask

  task automatic test_vsra_vv_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'ha62081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hff,"test_vsra_vv_sew8_002");
    end
  endtask

  task automatic test_vsra_vv_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      issue(32'ha62081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hff,"test_vsra_vv_sew8_003");
    end
  endtask

  task automatic test_vsra_vv_sew8_004;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h80));
      issue(32'ha62081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h7f,"test_vsra_vv_sew8_004");
    end
  endtask

  task automatic test_vsra_vv_sew8_005;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h55));
      vrf_write(5'd1, replicate_8(DLEN,8'haa));
      issue(32'ha62081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h15,"test_vsra_vv_sew8_005");
    end
  endtask

  task automatic test_vsra_vv_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      issue(32'ha62081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vsra_vv_sew16_006");
    end
  endtask

  task automatic test_vsra_vv_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'ha62081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vsra_vv_sew16_007");
    end
  endtask

  task automatic test_vsra_vv_sew16_008;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'ha62081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h7f,"test_vsra_vv_sew16_008");
    end
  endtask

  task automatic test_vsra_vv_sew16_009;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      issue(32'ha62081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vsra_vv_sew16_009");
    end
  endtask

  task automatic test_vsra_vv_sew16_010;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h80));
      issue(32'ha62081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h7f,"test_vsra_vv_sew16_010");
    end
  endtask

  task automatic test_vsra_vv_sew16_011;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h55));
      vrf_write(5'd1, replicate_16(DLEN,16'haa));
      issue(32'ha62081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vsra_vv_sew16_011");
    end
  endtask

  task automatic test_vsra_vv_sew32_012;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      issue(32'ha62081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vsra_vv_sew32_012");
    end
  endtask

  task automatic test_vsra_vv_sew32_013;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'ha62081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vsra_vv_sew32_013");
    end
  endtask

  task automatic test_vsra_vv_sew32_014;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'ha62081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h7f,"test_vsra_vv_sew32_014");
    end
  endtask

  task automatic test_vsra_vv_sew32_015;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      issue(32'ha62081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vsra_vv_sew32_015");
    end
  endtask

  task automatic test_vsra_vv_sew32_016;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h80));
      issue(32'ha62081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h7f,"test_vsra_vv_sew32_016");
    end
  endtask

  task automatic test_vsra_vv_sew32_017;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h55));
      vrf_write(5'd1, replicate_32(DLEN,32'haa));
      issue(32'ha62081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vsra_vv_sew32_017");
    end
  endtask

  task automatic test_vmin_vv_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      issue(32'h162081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vmin_vv_sew8_000");
    end
  endtask

  task automatic test_vmin_vv_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h162081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h1,"test_vmin_vv_sew8_001");
    end
  endtask

  task automatic test_vmin_vv_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h162081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hff,"test_vmin_vv_sew8_002");
    end
  endtask

  task automatic test_vmin_vv_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      issue(32'h162081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h80,"test_vmin_vv_sew8_003");
    end
  endtask

  task automatic test_vmin_vv_sew8_004;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h80));
      issue(32'h162081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h80,"test_vmin_vv_sew8_004");
    end
  endtask

  task automatic test_vmin_vv_sew8_005;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h55));
      vrf_write(5'd1, replicate_8(DLEN,8'haa));
      issue(32'h162081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'haa,"test_vmin_vv_sew8_005");
    end
  endtask

  task automatic test_vmin_vv_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      issue(32'h162081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vmin_vv_sew16_006");
    end
  endtask

  task automatic test_vmin_vv_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h162081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h1,"test_vmin_vv_sew16_007");
    end
  endtask

  task automatic test_vmin_vv_sew16_008;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h162081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h1,"test_vmin_vv_sew16_008");
    end
  endtask

  task automatic test_vmin_vv_sew16_009;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      issue(32'h162081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h7f,"test_vmin_vv_sew16_009");
    end
  endtask

  task automatic test_vmin_vv_sew16_010;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h80));
      issue(32'h162081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h7f,"test_vmin_vv_sew16_010");
    end
  endtask

  task automatic test_vmin_vv_sew16_011;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h55));
      vrf_write(5'd1, replicate_16(DLEN,16'haa));
      issue(32'h162081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h55,"test_vmin_vv_sew16_011");
    end
  endtask

  task automatic test_vmin_vv_sew32_012;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      issue(32'h162081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vmin_vv_sew32_012");
    end
  endtask

  task automatic test_vmin_vv_sew32_013;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h162081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h1,"test_vmin_vv_sew32_013");
    end
  endtask

  task automatic test_vmin_vv_sew32_014;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h162081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h1,"test_vmin_vv_sew32_014");
    end
  endtask

  task automatic test_vmin_vv_sew32_015;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      issue(32'h162081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h7f,"test_vmin_vv_sew32_015");
    end
  endtask

  task automatic test_vmin_vv_sew32_016;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h80));
      issue(32'h162081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h7f,"test_vmin_vv_sew32_016");
    end
  endtask

  task automatic test_vmin_vv_sew32_017;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h55));
      vrf_write(5'd1, replicate_32(DLEN,32'haa));
      issue(32'h162081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h55,"test_vmin_vv_sew32_017");
    end
  endtask

  task automatic test_vmax_vv_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      issue(32'h1e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vmax_vv_sew8_000");
    end
  endtask

  task automatic test_vmax_vv_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h1e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h1,"test_vmax_vv_sew8_001");
    end
  endtask

  task automatic test_vmax_vv_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h1e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h1,"test_vmax_vv_sew8_002");
    end
  endtask

  task automatic test_vmax_vv_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      issue(32'h1e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h7f,"test_vmax_vv_sew8_003");
    end
  endtask

  task automatic test_vmax_vv_sew8_004;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h80));
      issue(32'h1e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h7f,"test_vmax_vv_sew8_004");
    end
  endtask

  task automatic test_vmax_vv_sew8_005;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h55));
      vrf_write(5'd1, replicate_8(DLEN,8'haa));
      issue(32'h1e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h55,"test_vmax_vv_sew8_005");
    end
  endtask

  task automatic test_vmax_vv_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      issue(32'h1e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vmax_vv_sew16_006");
    end
  endtask

  task automatic test_vmax_vv_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h1e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h1,"test_vmax_vv_sew16_007");
    end
  endtask

  task automatic test_vmax_vv_sew16_008;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h1e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hff,"test_vmax_vv_sew16_008");
    end
  endtask

  task automatic test_vmax_vv_sew16_009;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      issue(32'h1e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h80,"test_vmax_vv_sew16_009");
    end
  endtask

  task automatic test_vmax_vv_sew16_010;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h80));
      issue(32'h1e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h80,"test_vmax_vv_sew16_010");
    end
  endtask

  task automatic test_vmax_vv_sew16_011;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h55));
      vrf_write(5'd1, replicate_16(DLEN,16'haa));
      issue(32'h1e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'haa,"test_vmax_vv_sew16_011");
    end
  endtask

  task automatic test_vmax_vv_sew32_012;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      issue(32'h1e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vmax_vv_sew32_012");
    end
  endtask

  task automatic test_vmax_vv_sew32_013;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h1e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h1,"test_vmax_vv_sew32_013");
    end
  endtask

  task automatic test_vmax_vv_sew32_014;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h1e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hff,"test_vmax_vv_sew32_014");
    end
  endtask

  task automatic test_vmax_vv_sew32_015;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      issue(32'h1e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h80,"test_vmax_vv_sew32_015");
    end
  endtask

  task automatic test_vmax_vv_sew32_016;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h80));
      issue(32'h1e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h80,"test_vmax_vv_sew32_016");
    end
  endtask

  task automatic test_vmax_vv_sew32_017;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h55));
      vrf_write(5'd1, replicate_32(DLEN,32'haa));
      issue(32'h1e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'haa,"test_vmax_vv_sew32_017");
    end
  endtask

  task automatic test_vminu_vv_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      issue(32'h122081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vminu_vv_sew8_000");
    end
  endtask

  task automatic test_vminu_vv_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h122081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h1,"test_vminu_vv_sew8_001");
    end
  endtask

  task automatic test_vminu_vv_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h122081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h1,"test_vminu_vv_sew8_002");
    end
  endtask

  task automatic test_vminu_vv_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      issue(32'h122081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h7f,"test_vminu_vv_sew8_003");
    end
  endtask

  task automatic test_vminu_vv_sew8_004;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h80));
      issue(32'h122081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h7f,"test_vminu_vv_sew8_004");
    end
  endtask

  task automatic test_vminu_vv_sew8_005;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h55));
      vrf_write(5'd1, replicate_8(DLEN,8'haa));
      issue(32'h122081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h55,"test_vminu_vv_sew8_005");
    end
  endtask

  task automatic test_vminu_vv_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      issue(32'h122081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vminu_vv_sew16_006");
    end
  endtask

  task automatic test_vminu_vv_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h122081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h1,"test_vminu_vv_sew16_007");
    end
  endtask

  task automatic test_vminu_vv_sew16_008;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h122081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h1,"test_vminu_vv_sew16_008");
    end
  endtask

  task automatic test_vminu_vv_sew16_009;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      issue(32'h122081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h7f,"test_vminu_vv_sew16_009");
    end
  endtask

  task automatic test_vminu_vv_sew16_010;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h80));
      issue(32'h122081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h7f,"test_vminu_vv_sew16_010");
    end
  endtask

  task automatic test_vminu_vv_sew16_011;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h55));
      vrf_write(5'd1, replicate_16(DLEN,16'haa));
      issue(32'h122081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h55,"test_vminu_vv_sew16_011");
    end
  endtask

  task automatic test_vminu_vv_sew32_012;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      issue(32'h122081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vminu_vv_sew32_012");
    end
  endtask

  task automatic test_vminu_vv_sew32_013;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h122081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h1,"test_vminu_vv_sew32_013");
    end
  endtask

  task automatic test_vminu_vv_sew32_014;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h122081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h1,"test_vminu_vv_sew32_014");
    end
  endtask

  task automatic test_vminu_vv_sew32_015;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      issue(32'h122081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h7f,"test_vminu_vv_sew32_015");
    end
  endtask

  task automatic test_vminu_vv_sew32_016;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h80));
      issue(32'h122081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h7f,"test_vminu_vv_sew32_016");
    end
  endtask

  task automatic test_vminu_vv_sew32_017;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h55));
      vrf_write(5'd1, replicate_32(DLEN,32'haa));
      issue(32'h122081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h55,"test_vminu_vv_sew32_017");
    end
  endtask

  task automatic test_vmaxu_vv_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      issue(32'h1a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vmaxu_vv_sew8_000");
    end
  endtask

  task automatic test_vmaxu_vv_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h1a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h1,"test_vmaxu_vv_sew8_001");
    end
  endtask

  task automatic test_vmaxu_vv_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h1a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hff,"test_vmaxu_vv_sew8_002");
    end
  endtask

  task automatic test_vmaxu_vv_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      issue(32'h1a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h80,"test_vmaxu_vv_sew8_003");
    end
  endtask

  task automatic test_vmaxu_vv_sew8_004;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h80));
      issue(32'h1a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h80,"test_vmaxu_vv_sew8_004");
    end
  endtask

  task automatic test_vmaxu_vv_sew8_005;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h55));
      vrf_write(5'd1, replicate_8(DLEN,8'haa));
      issue(32'h1a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'haa,"test_vmaxu_vv_sew8_005");
    end
  endtask

  task automatic test_vmaxu_vv_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      issue(32'h1a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vmaxu_vv_sew16_006");
    end
  endtask

  task automatic test_vmaxu_vv_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h1a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h1,"test_vmaxu_vv_sew16_007");
    end
  endtask

  task automatic test_vmaxu_vv_sew16_008;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h1a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hff,"test_vmaxu_vv_sew16_008");
    end
  endtask

  task automatic test_vmaxu_vv_sew16_009;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      issue(32'h1a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h80,"test_vmaxu_vv_sew16_009");
    end
  endtask

  task automatic test_vmaxu_vv_sew16_010;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h80));
      issue(32'h1a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h80,"test_vmaxu_vv_sew16_010");
    end
  endtask

  task automatic test_vmaxu_vv_sew16_011;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h55));
      vrf_write(5'd1, replicate_16(DLEN,16'haa));
      issue(32'h1a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'haa,"test_vmaxu_vv_sew16_011");
    end
  endtask

  task automatic test_vmaxu_vv_sew32_012;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      issue(32'h1a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vmaxu_vv_sew32_012");
    end
  endtask

  task automatic test_vmaxu_vv_sew32_013;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h1a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h1,"test_vmaxu_vv_sew32_013");
    end
  endtask

  task automatic test_vmaxu_vv_sew32_014;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h1a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hff,"test_vmaxu_vv_sew32_014");
    end
  endtask

  task automatic test_vmaxu_vv_sew32_015;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      issue(32'h1a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h80,"test_vmaxu_vv_sew32_015");
    end
  endtask

  task automatic test_vmaxu_vv_sew32_016;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h80));
      issue(32'h1a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h80,"test_vmaxu_vv_sew32_016");
    end
  endtask

  task automatic test_vmaxu_vv_sew32_017;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h55));
      vrf_write(5'd1, replicate_32(DLEN,32'haa));
      issue(32'h1a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'haa,"test_vmaxu_vv_sew32_017");
    end
  endtask


  task automatic run_alu_vv_tests;
    begin
      $display("=== ALU .VV TESTS (234) ===");
      test_vadd_vv_sew8_000();
      test_vadd_vv_sew8_001();
      test_vadd_vv_sew8_002();
      test_vadd_vv_sew8_003();
      test_vadd_vv_sew8_004();
      test_vadd_vv_sew8_005();
      test_vadd_vv_sew16_006();
      test_vadd_vv_sew16_007();
      test_vadd_vv_sew16_008();
      test_vadd_vv_sew16_009();
      test_vadd_vv_sew16_010();
      test_vadd_vv_sew16_011();
      test_vadd_vv_sew32_012();
      test_vadd_vv_sew32_013();
      test_vadd_vv_sew32_014();
      test_vadd_vv_sew32_015();
      test_vadd_vv_sew32_016();
      test_vadd_vv_sew32_017();
      test_vsub_vv_sew8_000();
      test_vsub_vv_sew8_001();
      test_vsub_vv_sew8_002();
      test_vsub_vv_sew8_003();
      test_vsub_vv_sew8_004();
      test_vsub_vv_sew8_005();
      test_vsub_vv_sew16_006();
      test_vsub_vv_sew16_007();
      test_vsub_vv_sew16_008();
      test_vsub_vv_sew16_009();
      test_vsub_vv_sew16_010();
      test_vsub_vv_sew16_011();
      test_vsub_vv_sew32_012();
      test_vsub_vv_sew32_013();
      test_vsub_vv_sew32_014();
      test_vsub_vv_sew32_015();
      test_vsub_vv_sew32_016();
      test_vsub_vv_sew32_017();
      test_vrsub_vv_sew8_000();
      test_vrsub_vv_sew8_001();
      test_vrsub_vv_sew8_002();
      test_vrsub_vv_sew8_003();
      test_vrsub_vv_sew8_004();
      test_vrsub_vv_sew8_005();
      test_vrsub_vv_sew16_006();
      test_vrsub_vv_sew16_007();
      test_vrsub_vv_sew16_008();
      test_vrsub_vv_sew16_009();
      test_vrsub_vv_sew16_010();
      test_vrsub_vv_sew16_011();
      test_vrsub_vv_sew32_012();
      test_vrsub_vv_sew32_013();
      test_vrsub_vv_sew32_014();
      test_vrsub_vv_sew32_015();
      test_vrsub_vv_sew32_016();
      test_vrsub_vv_sew32_017();
      test_vand_vv_sew8_000();
      test_vand_vv_sew8_001();
      test_vand_vv_sew8_002();
      test_vand_vv_sew8_003();
      test_vand_vv_sew8_004();
      test_vand_vv_sew8_005();
      test_vand_vv_sew16_006();
      test_vand_vv_sew16_007();
      test_vand_vv_sew16_008();
      test_vand_vv_sew16_009();
      test_vand_vv_sew16_010();
      test_vand_vv_sew16_011();
      test_vand_vv_sew32_012();
      test_vand_vv_sew32_013();
      test_vand_vv_sew32_014();
      test_vand_vv_sew32_015();
      test_vand_vv_sew32_016();
      test_vand_vv_sew32_017();
      test_vor_vv_sew8_000();
      test_vor_vv_sew8_001();
      test_vor_vv_sew8_002();
      test_vor_vv_sew8_003();
      test_vor_vv_sew8_004();
      test_vor_vv_sew8_005();
      test_vor_vv_sew16_006();
      test_vor_vv_sew16_007();
      test_vor_vv_sew16_008();
      test_vor_vv_sew16_009();
      test_vor_vv_sew16_010();
      test_vor_vv_sew16_011();
      test_vor_vv_sew32_012();
      test_vor_vv_sew32_013();
      test_vor_vv_sew32_014();
      test_vor_vv_sew32_015();
      test_vor_vv_sew32_016();
      test_vor_vv_sew32_017();
      test_vxor_vv_sew8_000();
      test_vxor_vv_sew8_001();
      test_vxor_vv_sew8_002();
      test_vxor_vv_sew8_003();
      test_vxor_vv_sew8_004();
      test_vxor_vv_sew8_005();
      test_vxor_vv_sew16_006();
      test_vxor_vv_sew16_007();
      test_vxor_vv_sew16_008();
      test_vxor_vv_sew16_009();
      test_vxor_vv_sew16_010();
      test_vxor_vv_sew16_011();
      test_vxor_vv_sew32_012();
      test_vxor_vv_sew32_013();
      test_vxor_vv_sew32_014();
      test_vxor_vv_sew32_015();
      test_vxor_vv_sew32_016();
      test_vxor_vv_sew32_017();
      test_vsll_vv_sew8_000();
      test_vsll_vv_sew8_001();
      test_vsll_vv_sew8_002();
      test_vsll_vv_sew8_003();
      test_vsll_vv_sew8_004();
      test_vsll_vv_sew8_005();
      test_vsll_vv_sew16_006();
      test_vsll_vv_sew16_007();
      test_vsll_vv_sew16_008();
      test_vsll_vv_sew16_009();
      test_vsll_vv_sew16_010();
      test_vsll_vv_sew16_011();
      test_vsll_vv_sew32_012();
      test_vsll_vv_sew32_013();
      test_vsll_vv_sew32_014();
      test_vsll_vv_sew32_015();
      test_vsll_vv_sew32_016();
      test_vsll_vv_sew32_017();
      test_vsrl_vv_sew8_000();
      test_vsrl_vv_sew8_001();
      test_vsrl_vv_sew8_002();
      test_vsrl_vv_sew8_003();
      test_vsrl_vv_sew8_004();
      test_vsrl_vv_sew8_005();
      test_vsrl_vv_sew16_006();
      test_vsrl_vv_sew16_007();
      test_vsrl_vv_sew16_008();
      test_vsrl_vv_sew16_009();
      test_vsrl_vv_sew16_010();
      test_vsrl_vv_sew16_011();
      test_vsrl_vv_sew32_012();
      test_vsrl_vv_sew32_013();
      test_vsrl_vv_sew32_014();
      test_vsrl_vv_sew32_015();
      test_vsrl_vv_sew32_016();
      test_vsrl_vv_sew32_017();
      test_vsra_vv_sew8_000();
      test_vsra_vv_sew8_001();
      test_vsra_vv_sew8_002();
      test_vsra_vv_sew8_003();
      test_vsra_vv_sew8_004();
      test_vsra_vv_sew8_005();
      test_vsra_vv_sew16_006();
      test_vsra_vv_sew16_007();
      test_vsra_vv_sew16_008();
      test_vsra_vv_sew16_009();
      test_vsra_vv_sew16_010();
      test_vsra_vv_sew16_011();
      test_vsra_vv_sew32_012();
      test_vsra_vv_sew32_013();
      test_vsra_vv_sew32_014();
      test_vsra_vv_sew32_015();
      test_vsra_vv_sew32_016();
      test_vsra_vv_sew32_017();
      test_vmin_vv_sew8_000();
      test_vmin_vv_sew8_001();
      test_vmin_vv_sew8_002();
      test_vmin_vv_sew8_003();
      test_vmin_vv_sew8_004();
      test_vmin_vv_sew8_005();
      test_vmin_vv_sew16_006();
      test_vmin_vv_sew16_007();
      test_vmin_vv_sew16_008();
      test_vmin_vv_sew16_009();
      test_vmin_vv_sew16_010();
      test_vmin_vv_sew16_011();
      test_vmin_vv_sew32_012();
      test_vmin_vv_sew32_013();
      test_vmin_vv_sew32_014();
      test_vmin_vv_sew32_015();
      test_vmin_vv_sew32_016();
      test_vmin_vv_sew32_017();
      test_vmax_vv_sew8_000();
      test_vmax_vv_sew8_001();
      test_vmax_vv_sew8_002();
      test_vmax_vv_sew8_003();
      test_vmax_vv_sew8_004();
      test_vmax_vv_sew8_005();
      test_vmax_vv_sew16_006();
      test_vmax_vv_sew16_007();
      test_vmax_vv_sew16_008();
      test_vmax_vv_sew16_009();
      test_vmax_vv_sew16_010();
      test_vmax_vv_sew16_011();
      test_vmax_vv_sew32_012();
      test_vmax_vv_sew32_013();
      test_vmax_vv_sew32_014();
      test_vmax_vv_sew32_015();
      test_vmax_vv_sew32_016();
      test_vmax_vv_sew32_017();
      test_vminu_vv_sew8_000();
      test_vminu_vv_sew8_001();
      test_vminu_vv_sew8_002();
      test_vminu_vv_sew8_003();
      test_vminu_vv_sew8_004();
      test_vminu_vv_sew8_005();
      test_vminu_vv_sew16_006();
      test_vminu_vv_sew16_007();
      test_vminu_vv_sew16_008();
      test_vminu_vv_sew16_009();
      test_vminu_vv_sew16_010();
      test_vminu_vv_sew16_011();
      test_vminu_vv_sew32_012();
      test_vminu_vv_sew32_013();
      test_vminu_vv_sew32_014();
      test_vminu_vv_sew32_015();
      test_vminu_vv_sew32_016();
      test_vminu_vv_sew32_017();
      test_vmaxu_vv_sew8_000();
      test_vmaxu_vv_sew8_001();
      test_vmaxu_vv_sew8_002();
      test_vmaxu_vv_sew8_003();
      test_vmaxu_vv_sew8_004();
      test_vmaxu_vv_sew8_005();
      test_vmaxu_vv_sew16_006();
      test_vmaxu_vv_sew16_007();
      test_vmaxu_vv_sew16_008();
      test_vmaxu_vv_sew16_009();
      test_vmaxu_vv_sew16_010();
      test_vmaxu_vv_sew16_011();
      test_vmaxu_vv_sew32_012();
      test_vmaxu_vv_sew32_013();
      test_vmaxu_vv_sew32_014();
      test_vmaxu_vv_sew32_015();
      test_vmaxu_vv_sew32_016();
      test_vmaxu_vv_sew32_017();
      $display("ALU .vv: 234 tests done");
    end
  endtask
