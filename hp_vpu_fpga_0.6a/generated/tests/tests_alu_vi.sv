// VPU v0.3c - ALU .vi Tests (96 tests)

  task automatic test_vadd_vi_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h10));
      issue(32'h022031d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h10,"test_vadd_vi_sew8_000");
    end
  endtask

  task automatic test_vadd_vi_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      issue(32'h0220b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vadd_vi_sew8_001");
    end
  endtask

  task automatic test_vadd_vi_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      issue(32'h022231d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h84,"test_vadd_vi_sew8_002");
    end
  endtask

  task automatic test_vadd_vi_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      issue(32'h0223b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h86,"test_vadd_vi_sew8_003");
    end
  endtask

  task automatic test_vadd_vi_sew16_004;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h10));
      issue(32'h022031d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h10,"test_vadd_vi_sew16_004");
    end
  endtask

  task automatic test_vadd_vi_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      issue(32'h0220b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h100,"test_vadd_vi_sew16_005");
    end
  endtask

  task automatic test_vadd_vi_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      issue(32'h022231d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h84,"test_vadd_vi_sew16_006");
    end
  endtask

  task automatic test_vadd_vi_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      issue(32'h0223b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h86,"test_vadd_vi_sew16_007");
    end
  endtask

  task automatic test_vadd_vi_sew32_008;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h10));
      issue(32'h022031d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h10,"test_vadd_vi_sew32_008");
    end
  endtask

  task automatic test_vadd_vi_sew32_009;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      issue(32'h0220b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h100,"test_vadd_vi_sew32_009");
    end
  endtask

  task automatic test_vadd_vi_sew32_010;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      issue(32'h022231d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h84,"test_vadd_vi_sew32_010");
    end
  endtask

  task automatic test_vadd_vi_sew32_011;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      issue(32'h0223b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h86,"test_vadd_vi_sew32_011");
    end
  endtask

  task automatic test_vrsub_vi_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h10));
      issue(32'h0e2031d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hf0,"test_vrsub_vi_sew8_000");
    end
  endtask

  task automatic test_vrsub_vi_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      issue(32'h0e20b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h2,"test_vrsub_vi_sew8_001");
    end
  endtask

  task automatic test_vrsub_vi_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      issue(32'h0e2231d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h84,"test_vrsub_vi_sew8_002");
    end
  endtask

  task automatic test_vrsub_vi_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      issue(32'h0e23b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h88,"test_vrsub_vi_sew8_003");
    end
  endtask

  task automatic test_vrsub_vi_sew16_004;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h10));
      issue(32'h0e2031d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hfff0,"test_vrsub_vi_sew16_004");
    end
  endtask

  task automatic test_vrsub_vi_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      issue(32'h0e20b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hff02,"test_vrsub_vi_sew16_005");
    end
  endtask

  task automatic test_vrsub_vi_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      issue(32'h0e2231d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hff84,"test_vrsub_vi_sew16_006");
    end
  endtask

  task automatic test_vrsub_vi_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      issue(32'h0e23b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hff88,"test_vrsub_vi_sew16_007");
    end
  endtask

  task automatic test_vrsub_vi_sew32_008;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h10));
      issue(32'h0e2031d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hfffffff0,"test_vrsub_vi_sew32_008");
    end
  endtask

  task automatic test_vrsub_vi_sew32_009;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      issue(32'h0e20b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hffffff02,"test_vrsub_vi_sew32_009");
    end
  endtask

  task automatic test_vrsub_vi_sew32_010;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      issue(32'h0e2231d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hffffff84,"test_vrsub_vi_sew32_010");
    end
  endtask

  task automatic test_vrsub_vi_sew32_011;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      issue(32'h0e23b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hffffff88,"test_vrsub_vi_sew32_011");
    end
  endtask

  task automatic test_vand_vi_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h10));
      issue(32'h262031d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vand_vi_sew8_000");
    end
  endtask

  task automatic test_vand_vi_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      issue(32'h2620b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h1,"test_vand_vi_sew8_001");
    end
  endtask

  task automatic test_vand_vi_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      issue(32'h262231d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vand_vi_sew8_002");
    end
  endtask

  task automatic test_vand_vi_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      issue(32'h2623b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h7,"test_vand_vi_sew8_003");
    end
  endtask

  task automatic test_vand_vi_sew16_004;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h10));
      issue(32'h262031d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vand_vi_sew16_004");
    end
  endtask

  task automatic test_vand_vi_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      issue(32'h2620b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h1,"test_vand_vi_sew16_005");
    end
  endtask

  task automatic test_vand_vi_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      issue(32'h262231d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vand_vi_sew16_006");
    end
  endtask

  task automatic test_vand_vi_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      issue(32'h2623b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h7,"test_vand_vi_sew16_007");
    end
  endtask

  task automatic test_vand_vi_sew32_008;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h10));
      issue(32'h262031d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vand_vi_sew32_008");
    end
  endtask

  task automatic test_vand_vi_sew32_009;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      issue(32'h2620b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h1,"test_vand_vi_sew32_009");
    end
  endtask

  task automatic test_vand_vi_sew32_010;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      issue(32'h262231d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vand_vi_sew32_010");
    end
  endtask

  task automatic test_vand_vi_sew32_011;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      issue(32'h2623b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h7,"test_vand_vi_sew32_011");
    end
  endtask

  task automatic test_vor_vi_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h10));
      issue(32'h2a2031d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h10,"test_vor_vi_sew8_000");
    end
  endtask

  task automatic test_vor_vi_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      issue(32'h2a20b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hff,"test_vor_vi_sew8_001");
    end
  endtask

  task automatic test_vor_vi_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      issue(32'h2a2231d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h84,"test_vor_vi_sew8_002");
    end
  endtask

  task automatic test_vor_vi_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      issue(32'h2a23b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h7f,"test_vor_vi_sew8_003");
    end
  endtask

  task automatic test_vor_vi_sew16_004;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h10));
      issue(32'h2a2031d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h10,"test_vor_vi_sew16_004");
    end
  endtask

  task automatic test_vor_vi_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      issue(32'h2a20b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hff,"test_vor_vi_sew16_005");
    end
  endtask

  task automatic test_vor_vi_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      issue(32'h2a2231d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h84,"test_vor_vi_sew16_006");
    end
  endtask

  task automatic test_vor_vi_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      issue(32'h2a23b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h7f,"test_vor_vi_sew16_007");
    end
  endtask

  task automatic test_vor_vi_sew32_008;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h10));
      issue(32'h2a2031d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h10,"test_vor_vi_sew32_008");
    end
  endtask

  task automatic test_vor_vi_sew32_009;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      issue(32'h2a20b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hff,"test_vor_vi_sew32_009");
    end
  endtask

  task automatic test_vor_vi_sew32_010;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      issue(32'h2a2231d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h84,"test_vor_vi_sew32_010");
    end
  endtask

  task automatic test_vor_vi_sew32_011;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      issue(32'h2a23b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h7f,"test_vor_vi_sew32_011");
    end
  endtask

  task automatic test_vxor_vi_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h10));
      issue(32'h2e2031d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h10,"test_vxor_vi_sew8_000");
    end
  endtask

  task automatic test_vxor_vi_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      issue(32'h2e20b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hfe,"test_vxor_vi_sew8_001");
    end
  endtask

  task automatic test_vxor_vi_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      issue(32'h2e2231d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h84,"test_vxor_vi_sew8_002");
    end
  endtask

  task automatic test_vxor_vi_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      issue(32'h2e23b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h78,"test_vxor_vi_sew8_003");
    end
  endtask

  task automatic test_vxor_vi_sew16_004;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h10));
      issue(32'h2e2031d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h10,"test_vxor_vi_sew16_004");
    end
  endtask

  task automatic test_vxor_vi_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      issue(32'h2e20b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hfe,"test_vxor_vi_sew16_005");
    end
  endtask

  task automatic test_vxor_vi_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      issue(32'h2e2231d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h84,"test_vxor_vi_sew16_006");
    end
  endtask

  task automatic test_vxor_vi_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      issue(32'h2e23b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h78,"test_vxor_vi_sew16_007");
    end
  endtask

  task automatic test_vxor_vi_sew32_008;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h10));
      issue(32'h2e2031d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h10,"test_vxor_vi_sew32_008");
    end
  endtask

  task automatic test_vxor_vi_sew32_009;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      issue(32'h2e20b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hfe,"test_vxor_vi_sew32_009");
    end
  endtask

  task automatic test_vxor_vi_sew32_010;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      issue(32'h2e2231d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h84,"test_vxor_vi_sew32_010");
    end
  endtask

  task automatic test_vxor_vi_sew32_011;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      issue(32'h2e23b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h78,"test_vxor_vi_sew32_011");
    end
  endtask

  task automatic test_vsll_vi_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h10));
      issue(32'h962031d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h10,"test_vsll_vi_sew8_000");
    end
  endtask

  task automatic test_vsll_vi_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      issue(32'h9620b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hfe,"test_vsll_vi_sew8_001");
    end
  endtask

  task automatic test_vsll_vi_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      issue(32'h962231d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vsll_vi_sew8_002");
    end
  endtask

  task automatic test_vsll_vi_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      issue(32'h9623b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h80,"test_vsll_vi_sew8_003");
    end
  endtask

  task automatic test_vsll_vi_sew16_004;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h10));
      issue(32'h962031d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h10,"test_vsll_vi_sew16_004");
    end
  endtask

  task automatic test_vsll_vi_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      issue(32'h9620b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h1fe,"test_vsll_vi_sew16_005");
    end
  endtask

  task automatic test_vsll_vi_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      issue(32'h962231d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h800,"test_vsll_vi_sew16_006");
    end
  endtask

  task automatic test_vsll_vi_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      issue(32'h9623b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h3f80,"test_vsll_vi_sew16_007");
    end
  endtask

  task automatic test_vsll_vi_sew32_008;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h10));
      issue(32'h962031d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h10,"test_vsll_vi_sew32_008");
    end
  endtask

  task automatic test_vsll_vi_sew32_009;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      issue(32'h9620b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h1fe,"test_vsll_vi_sew32_009");
    end
  endtask

  task automatic test_vsll_vi_sew32_010;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      issue(32'h962231d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h800,"test_vsll_vi_sew32_010");
    end
  endtask

  task automatic test_vsll_vi_sew32_011;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      issue(32'h9623b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h3f80,"test_vsll_vi_sew32_011");
    end
  endtask

  task automatic test_vsrl_vi_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h10));
      issue(32'ha22031d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h10,"test_vsrl_vi_sew8_000");
    end
  endtask

  task automatic test_vsrl_vi_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      issue(32'ha220b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h7f,"test_vsrl_vi_sew8_001");
    end
  endtask

  task automatic test_vsrl_vi_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      issue(32'ha22231d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h8,"test_vsrl_vi_sew8_002");
    end
  endtask

  task automatic test_vsrl_vi_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      issue(32'ha223b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vsrl_vi_sew8_003");
    end
  endtask

  task automatic test_vsrl_vi_sew16_004;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h10));
      issue(32'ha22031d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h10,"test_vsrl_vi_sew16_004");
    end
  endtask

  task automatic test_vsrl_vi_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      issue(32'ha220b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h7f,"test_vsrl_vi_sew16_005");
    end
  endtask

  task automatic test_vsrl_vi_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      issue(32'ha22231d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h8,"test_vsrl_vi_sew16_006");
    end
  endtask

  task automatic test_vsrl_vi_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      issue(32'ha223b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vsrl_vi_sew16_007");
    end
  endtask

  task automatic test_vsrl_vi_sew32_008;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h10));
      issue(32'ha22031d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h10,"test_vsrl_vi_sew32_008");
    end
  endtask

  task automatic test_vsrl_vi_sew32_009;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      issue(32'ha220b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h7f,"test_vsrl_vi_sew32_009");
    end
  endtask

  task automatic test_vsrl_vi_sew32_010;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      issue(32'ha22231d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h8,"test_vsrl_vi_sew32_010");
    end
  endtask

  task automatic test_vsrl_vi_sew32_011;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      issue(32'ha223b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vsrl_vi_sew32_011");
    end
  endtask

  task automatic test_vsra_vi_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h10));
      issue(32'ha62031d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h10,"test_vsra_vi_sew8_000");
    end
  endtask

  task automatic test_vsra_vi_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      issue(32'ha620b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hff,"test_vsra_vi_sew8_001");
    end
  endtask

  task automatic test_vsra_vi_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      issue(32'ha62231d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hf8,"test_vsra_vi_sew8_002");
    end
  endtask

  task automatic test_vsra_vi_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      issue(32'ha623b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vsra_vi_sew8_003");
    end
  endtask

  task automatic test_vsra_vi_sew16_004;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h10));
      issue(32'ha62031d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h10,"test_vsra_vi_sew16_004");
    end
  endtask

  task automatic test_vsra_vi_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      issue(32'ha620b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h7f,"test_vsra_vi_sew16_005");
    end
  endtask

  task automatic test_vsra_vi_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      issue(32'ha62231d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h8,"test_vsra_vi_sew16_006");
    end
  endtask

  task automatic test_vsra_vi_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      issue(32'ha623b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vsra_vi_sew16_007");
    end
  endtask

  task automatic test_vsra_vi_sew32_008;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h10));
      issue(32'ha62031d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h10,"test_vsra_vi_sew32_008");
    end
  endtask

  task automatic test_vsra_vi_sew32_009;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      issue(32'ha620b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h7f,"test_vsra_vi_sew32_009");
    end
  endtask

  task automatic test_vsra_vi_sew32_010;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      issue(32'ha62231d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h8,"test_vsra_vi_sew32_010");
    end
  endtask

  task automatic test_vsra_vi_sew32_011;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      issue(32'ha623b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vsra_vi_sew32_011");
    end
  endtask


  task automatic run_alu_vi_tests;
    begin
      $display("=== ALU .VI TESTS (96) ===");
      test_vadd_vi_sew8_000();
      test_vadd_vi_sew8_001();
      test_vadd_vi_sew8_002();
      test_vadd_vi_sew8_003();
      test_vadd_vi_sew16_004();
      test_vadd_vi_sew16_005();
      test_vadd_vi_sew16_006();
      test_vadd_vi_sew16_007();
      test_vadd_vi_sew32_008();
      test_vadd_vi_sew32_009();
      test_vadd_vi_sew32_010();
      test_vadd_vi_sew32_011();
      test_vrsub_vi_sew8_000();
      test_vrsub_vi_sew8_001();
      test_vrsub_vi_sew8_002();
      test_vrsub_vi_sew8_003();
      test_vrsub_vi_sew16_004();
      test_vrsub_vi_sew16_005();
      test_vrsub_vi_sew16_006();
      test_vrsub_vi_sew16_007();
      test_vrsub_vi_sew32_008();
      test_vrsub_vi_sew32_009();
      test_vrsub_vi_sew32_010();
      test_vrsub_vi_sew32_011();
      test_vand_vi_sew8_000();
      test_vand_vi_sew8_001();
      test_vand_vi_sew8_002();
      test_vand_vi_sew8_003();
      test_vand_vi_sew16_004();
      test_vand_vi_sew16_005();
      test_vand_vi_sew16_006();
      test_vand_vi_sew16_007();
      test_vand_vi_sew32_008();
      test_vand_vi_sew32_009();
      test_vand_vi_sew32_010();
      test_vand_vi_sew32_011();
      test_vor_vi_sew8_000();
      test_vor_vi_sew8_001();
      test_vor_vi_sew8_002();
      test_vor_vi_sew8_003();
      test_vor_vi_sew16_004();
      test_vor_vi_sew16_005();
      test_vor_vi_sew16_006();
      test_vor_vi_sew16_007();
      test_vor_vi_sew32_008();
      test_vor_vi_sew32_009();
      test_vor_vi_sew32_010();
      test_vor_vi_sew32_011();
      test_vxor_vi_sew8_000();
      test_vxor_vi_sew8_001();
      test_vxor_vi_sew8_002();
      test_vxor_vi_sew8_003();
      test_vxor_vi_sew16_004();
      test_vxor_vi_sew16_005();
      test_vxor_vi_sew16_006();
      test_vxor_vi_sew16_007();
      test_vxor_vi_sew32_008();
      test_vxor_vi_sew32_009();
      test_vxor_vi_sew32_010();
      test_vxor_vi_sew32_011();
      test_vsll_vi_sew8_000();
      test_vsll_vi_sew8_001();
      test_vsll_vi_sew8_002();
      test_vsll_vi_sew8_003();
      test_vsll_vi_sew16_004();
      test_vsll_vi_sew16_005();
      test_vsll_vi_sew16_006();
      test_vsll_vi_sew16_007();
      test_vsll_vi_sew32_008();
      test_vsll_vi_sew32_009();
      test_vsll_vi_sew32_010();
      test_vsll_vi_sew32_011();
      test_vsrl_vi_sew8_000();
      test_vsrl_vi_sew8_001();
      test_vsrl_vi_sew8_002();
      test_vsrl_vi_sew8_003();
      test_vsrl_vi_sew16_004();
      test_vsrl_vi_sew16_005();
      test_vsrl_vi_sew16_006();
      test_vsrl_vi_sew16_007();
      test_vsrl_vi_sew32_008();
      test_vsrl_vi_sew32_009();
      test_vsrl_vi_sew32_010();
      test_vsrl_vi_sew32_011();
      test_vsra_vi_sew8_000();
      test_vsra_vi_sew8_001();
      test_vsra_vi_sew8_002();
      test_vsra_vi_sew8_003();
      test_vsra_vi_sew16_004();
      test_vsra_vi_sew16_005();
      test_vsra_vi_sew16_006();
      test_vsra_vi_sew16_007();
      test_vsra_vi_sew32_008();
      test_vsra_vi_sew32_009();
      test_vsra_vi_sew32_010();
      test_vsra_vi_sew32_011();
      $display("ALU .vi: 96 tests done");
    end
  endtask
