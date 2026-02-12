// VPU v0.3c - ALU .vx Tests (108 tests)

  task automatic test_vadd_vx_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      issue(32'h0220c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vadd_vx_sew8_000");
    end
  endtask

  task automatic test_vadd_vx_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      issue(32'h0220c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h80,"test_vadd_vx_sew8_001");
    end
  endtask

  task automatic test_vadd_vx_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      issue(32'h0220c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hff,"test_vadd_vx_sew8_002");
    end
  endtask

  task automatic test_vadd_vx_sew16_003;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      issue(32'h0220c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vadd_vx_sew16_003");
    end
  endtask

  task automatic test_vadd_vx_sew16_004;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      issue(32'h0220c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h80,"test_vadd_vx_sew16_004");
    end
  endtask

  task automatic test_vadd_vx_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      issue(32'h0220c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hff,"test_vadd_vx_sew16_005");
    end
  endtask

  task automatic test_vadd_vx_sew32_006;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      issue(32'h0220c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vadd_vx_sew32_006");
    end
  endtask

  task automatic test_vadd_vx_sew32_007;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      issue(32'h0220c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h80,"test_vadd_vx_sew32_007");
    end
  endtask

  task automatic test_vadd_vx_sew32_008;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      issue(32'h0220c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hff,"test_vadd_vx_sew32_008");
    end
  endtask

  task automatic test_vsub_vx_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      issue(32'h0a20c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vsub_vx_sew8_000");
    end
  endtask

  task automatic test_vsub_vx_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      issue(32'h0a20c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h7e,"test_vsub_vx_sew8_001");
    end
  endtask

  task automatic test_vsub_vx_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      issue(32'h0a20c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h1,"test_vsub_vx_sew8_002");
    end
  endtask

  task automatic test_vsub_vx_sew16_003;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      issue(32'h0a20c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vsub_vx_sew16_003");
    end
  endtask

  task automatic test_vsub_vx_sew16_004;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      issue(32'h0a20c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h7e,"test_vsub_vx_sew16_004");
    end
  endtask

  task automatic test_vsub_vx_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      issue(32'h0a20c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h1,"test_vsub_vx_sew16_005");
    end
  endtask

  task automatic test_vsub_vx_sew32_006;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      issue(32'h0a20c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vsub_vx_sew32_006");
    end
  endtask

  task automatic test_vsub_vx_sew32_007;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      issue(32'h0a20c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h7e,"test_vsub_vx_sew32_007");
    end
  endtask

  task automatic test_vsub_vx_sew32_008;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      issue(32'h0a20c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h1,"test_vsub_vx_sew32_008");
    end
  endtask

  task automatic test_vand_vx_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      issue(32'h2620c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vand_vx_sew8_000");
    end
  endtask

  task automatic test_vand_vx_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      issue(32'h2620c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h1,"test_vand_vx_sew8_001");
    end
  endtask

  task automatic test_vand_vx_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      issue(32'h2620c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vand_vx_sew8_002");
    end
  endtask

  task automatic test_vand_vx_sew16_003;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      issue(32'h2620c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vand_vx_sew16_003");
    end
  endtask

  task automatic test_vand_vx_sew16_004;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      issue(32'h2620c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h1,"test_vand_vx_sew16_004");
    end
  endtask

  task automatic test_vand_vx_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      issue(32'h2620c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vand_vx_sew16_005");
    end
  endtask

  task automatic test_vand_vx_sew32_006;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      issue(32'h2620c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vand_vx_sew32_006");
    end
  endtask

  task automatic test_vand_vx_sew32_007;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      issue(32'h2620c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h1,"test_vand_vx_sew32_007");
    end
  endtask

  task automatic test_vand_vx_sew32_008;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      issue(32'h2620c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vand_vx_sew32_008");
    end
  endtask

  task automatic test_vor_vx_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      issue(32'h2a20c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vor_vx_sew8_000");
    end
  endtask

  task automatic test_vor_vx_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      issue(32'h2a20c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h7f,"test_vor_vx_sew8_001");
    end
  endtask

  task automatic test_vor_vx_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      issue(32'h2a20c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hff,"test_vor_vx_sew8_002");
    end
  endtask

  task automatic test_vor_vx_sew16_003;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      issue(32'h2a20c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vor_vx_sew16_003");
    end
  endtask

  task automatic test_vor_vx_sew16_004;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      issue(32'h2a20c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h7f,"test_vor_vx_sew16_004");
    end
  endtask

  task automatic test_vor_vx_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      issue(32'h2a20c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hff,"test_vor_vx_sew16_005");
    end
  endtask

  task automatic test_vor_vx_sew32_006;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      issue(32'h2a20c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vor_vx_sew32_006");
    end
  endtask

  task automatic test_vor_vx_sew32_007;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      issue(32'h2a20c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h7f,"test_vor_vx_sew32_007");
    end
  endtask

  task automatic test_vor_vx_sew32_008;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      issue(32'h2a20c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hff,"test_vor_vx_sew32_008");
    end
  endtask

  task automatic test_vxor_vx_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      issue(32'h2e20c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vxor_vx_sew8_000");
    end
  endtask

  task automatic test_vxor_vx_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      issue(32'h2e20c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h7e,"test_vxor_vx_sew8_001");
    end
  endtask

  task automatic test_vxor_vx_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      issue(32'h2e20c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hff,"test_vxor_vx_sew8_002");
    end
  endtask

  task automatic test_vxor_vx_sew16_003;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      issue(32'h2e20c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vxor_vx_sew16_003");
    end
  endtask

  task automatic test_vxor_vx_sew16_004;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      issue(32'h2e20c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h7e,"test_vxor_vx_sew16_004");
    end
  endtask

  task automatic test_vxor_vx_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      issue(32'h2e20c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hff,"test_vxor_vx_sew16_005");
    end
  endtask

  task automatic test_vxor_vx_sew32_006;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      issue(32'h2e20c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vxor_vx_sew32_006");
    end
  endtask

  task automatic test_vxor_vx_sew32_007;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      issue(32'h2e20c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h7e,"test_vxor_vx_sew32_007");
    end
  endtask

  task automatic test_vxor_vx_sew32_008;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      issue(32'h2e20c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hff,"test_vxor_vx_sew32_008");
    end
  endtask

  task automatic test_vsll_vx_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      issue(32'h9620c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vsll_vx_sew8_000");
    end
  endtask

  task automatic test_vsll_vx_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      issue(32'h9620c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hfe,"test_vsll_vx_sew8_001");
    end
  endtask

  task automatic test_vsll_vx_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      issue(32'h9620c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vsll_vx_sew8_002");
    end
  endtask

  task automatic test_vsll_vx_sew16_003;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      issue(32'h9620c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vsll_vx_sew16_003");
    end
  endtask

  task automatic test_vsll_vx_sew16_004;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      issue(32'h9620c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hfe,"test_vsll_vx_sew16_004");
    end
  endtask

  task automatic test_vsll_vx_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      issue(32'h9620c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vsll_vx_sew16_005");
    end
  endtask

  task automatic test_vsll_vx_sew32_006;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      issue(32'h9620c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vsll_vx_sew32_006");
    end
  endtask

  task automatic test_vsll_vx_sew32_007;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      issue(32'h9620c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hfe,"test_vsll_vx_sew32_007");
    end
  endtask

  task automatic test_vsll_vx_sew32_008;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      issue(32'h9620c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vsll_vx_sew32_008");
    end
  endtask

  task automatic test_vsrl_vx_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      issue(32'ha220c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vsrl_vx_sew8_000");
    end
  endtask

  task automatic test_vsrl_vx_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      issue(32'ha220c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h3f,"test_vsrl_vx_sew8_001");
    end
  endtask

  task automatic test_vsrl_vx_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      issue(32'ha220c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h1,"test_vsrl_vx_sew8_002");
    end
  endtask

  task automatic test_vsrl_vx_sew16_003;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      issue(32'ha220c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vsrl_vx_sew16_003");
    end
  endtask

  task automatic test_vsrl_vx_sew16_004;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      issue(32'ha220c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h3f,"test_vsrl_vx_sew16_004");
    end
  endtask

  task automatic test_vsrl_vx_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      issue(32'ha220c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vsrl_vx_sew16_005");
    end
  endtask

  task automatic test_vsrl_vx_sew32_006;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      issue(32'ha220c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vsrl_vx_sew32_006");
    end
  endtask

  task automatic test_vsrl_vx_sew32_007;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      issue(32'ha220c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h3f,"test_vsrl_vx_sew32_007");
    end
  endtask

  task automatic test_vsrl_vx_sew32_008;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      issue(32'ha220c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vsrl_vx_sew32_008");
    end
  endtask

  task automatic test_vsra_vx_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      issue(32'ha620c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vsra_vx_sew8_000");
    end
  endtask

  task automatic test_vsra_vx_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      issue(32'ha620c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h3f,"test_vsra_vx_sew8_001");
    end
  endtask

  task automatic test_vsra_vx_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      issue(32'ha620c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hff,"test_vsra_vx_sew8_002");
    end
  endtask

  task automatic test_vsra_vx_sew16_003;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      issue(32'ha620c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vsra_vx_sew16_003");
    end
  endtask

  task automatic test_vsra_vx_sew16_004;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      issue(32'ha620c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h3f,"test_vsra_vx_sew16_004");
    end
  endtask

  task automatic test_vsra_vx_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      issue(32'ha620c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vsra_vx_sew16_005");
    end
  endtask

  task automatic test_vsra_vx_sew32_006;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      issue(32'ha620c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vsra_vx_sew32_006");
    end
  endtask

  task automatic test_vsra_vx_sew32_007;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      issue(32'ha620c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h3f,"test_vsra_vx_sew32_007");
    end
  endtask

  task automatic test_vsra_vx_sew32_008;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      issue(32'ha620c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vsra_vx_sew32_008");
    end
  endtask

  task automatic test_vmin_vx_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      issue(32'h1620c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vmin_vx_sew8_000");
    end
  endtask

  task automatic test_vmin_vx_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      issue(32'h1620c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h1,"test_vmin_vx_sew8_001");
    end
  endtask

  task automatic test_vmin_vx_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      issue(32'h1620c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h80,"test_vmin_vx_sew8_002");
    end
  endtask

  task automatic test_vmin_vx_sew16_003;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      issue(32'h1620c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vmin_vx_sew16_003");
    end
  endtask

  task automatic test_vmin_vx_sew16_004;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      issue(32'h1620c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h1,"test_vmin_vx_sew16_004");
    end
  endtask

  task automatic test_vmin_vx_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      issue(32'h1620c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h7f,"test_vmin_vx_sew16_005");
    end
  endtask

  task automatic test_vmin_vx_sew32_006;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      issue(32'h1620c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vmin_vx_sew32_006");
    end
  endtask

  task automatic test_vmin_vx_sew32_007;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      issue(32'h1620c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h1,"test_vmin_vx_sew32_007");
    end
  endtask

  task automatic test_vmin_vx_sew32_008;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      issue(32'h1620c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h7f,"test_vmin_vx_sew32_008");
    end
  endtask

  task automatic test_vmax_vx_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      issue(32'h1e20c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vmax_vx_sew8_000");
    end
  endtask

  task automatic test_vmax_vx_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      issue(32'h1e20c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h7f,"test_vmax_vx_sew8_001");
    end
  endtask

  task automatic test_vmax_vx_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      issue(32'h1e20c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h7f,"test_vmax_vx_sew8_002");
    end
  endtask

  task automatic test_vmax_vx_sew16_003;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      issue(32'h1e20c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vmax_vx_sew16_003");
    end
  endtask

  task automatic test_vmax_vx_sew16_004;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      issue(32'h1e20c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h7f,"test_vmax_vx_sew16_004");
    end
  endtask

  task automatic test_vmax_vx_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      issue(32'h1e20c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h80,"test_vmax_vx_sew16_005");
    end
  endtask

  task automatic test_vmax_vx_sew32_006;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      issue(32'h1e20c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vmax_vx_sew32_006");
    end
  endtask

  task automatic test_vmax_vx_sew32_007;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      issue(32'h1e20c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h7f,"test_vmax_vx_sew32_007");
    end
  endtask

  task automatic test_vmax_vx_sew32_008;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      issue(32'h1e20c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h80,"test_vmax_vx_sew32_008");
    end
  endtask

  task automatic test_vminu_vx_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      issue(32'h1220c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vminu_vx_sew8_000");
    end
  endtask

  task automatic test_vminu_vx_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      issue(32'h1220c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h1,"test_vminu_vx_sew8_001");
    end
  endtask

  task automatic test_vminu_vx_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      issue(32'h1220c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h7f,"test_vminu_vx_sew8_002");
    end
  endtask

  task automatic test_vminu_vx_sew16_003;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      issue(32'h1220c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vminu_vx_sew16_003");
    end
  endtask

  task automatic test_vminu_vx_sew16_004;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      issue(32'h1220c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h1,"test_vminu_vx_sew16_004");
    end
  endtask

  task automatic test_vminu_vx_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      issue(32'h1220c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h7f,"test_vminu_vx_sew16_005");
    end
  endtask

  task automatic test_vminu_vx_sew32_006;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      issue(32'h1220c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vminu_vx_sew32_006");
    end
  endtask

  task automatic test_vminu_vx_sew32_007;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      issue(32'h1220c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h1,"test_vminu_vx_sew32_007");
    end
  endtask

  task automatic test_vminu_vx_sew32_008;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      issue(32'h1220c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h7f,"test_vminu_vx_sew32_008");
    end
  endtask

  task automatic test_vmaxu_vx_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      issue(32'h1a20c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vmaxu_vx_sew8_000");
    end
  endtask

  task automatic test_vmaxu_vx_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      issue(32'h1a20c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h7f,"test_vmaxu_vx_sew8_001");
    end
  endtask

  task automatic test_vmaxu_vx_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      issue(32'h1a20c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h80,"test_vmaxu_vx_sew8_002");
    end
  endtask

  task automatic test_vmaxu_vx_sew16_003;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      issue(32'h1a20c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vmaxu_vx_sew16_003");
    end
  endtask

  task automatic test_vmaxu_vx_sew16_004;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      issue(32'h1a20c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h7f,"test_vmaxu_vx_sew16_004");
    end
  endtask

  task automatic test_vmaxu_vx_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      issue(32'h1a20c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h80,"test_vmaxu_vx_sew16_005");
    end
  endtask

  task automatic test_vmaxu_vx_sew32_006;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      issue(32'h1a20c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vmaxu_vx_sew32_006");
    end
  endtask

  task automatic test_vmaxu_vx_sew32_007;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      issue(32'h1a20c1d7, 32'h00000001); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h7f,"test_vmaxu_vx_sew32_007");
    end
  endtask

  task automatic test_vmaxu_vx_sew32_008;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      issue(32'h1a20c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h80,"test_vmaxu_vx_sew32_008");
    end
  endtask


  task automatic run_alu_vx_tests;
    begin
      $display("=== ALU .VX TESTS (108) ===");
      test_vadd_vx_sew8_000();
      test_vadd_vx_sew8_001();
      test_vadd_vx_sew8_002();
      test_vadd_vx_sew16_003();
      test_vadd_vx_sew16_004();
      test_vadd_vx_sew16_005();
      test_vadd_vx_sew32_006();
      test_vadd_vx_sew32_007();
      test_vadd_vx_sew32_008();
      test_vsub_vx_sew8_000();
      test_vsub_vx_sew8_001();
      test_vsub_vx_sew8_002();
      test_vsub_vx_sew16_003();
      test_vsub_vx_sew16_004();
      test_vsub_vx_sew16_005();
      test_vsub_vx_sew32_006();
      test_vsub_vx_sew32_007();
      test_vsub_vx_sew32_008();
      test_vand_vx_sew8_000();
      test_vand_vx_sew8_001();
      test_vand_vx_sew8_002();
      test_vand_vx_sew16_003();
      test_vand_vx_sew16_004();
      test_vand_vx_sew16_005();
      test_vand_vx_sew32_006();
      test_vand_vx_sew32_007();
      test_vand_vx_sew32_008();
      test_vor_vx_sew8_000();
      test_vor_vx_sew8_001();
      test_vor_vx_sew8_002();
      test_vor_vx_sew16_003();
      test_vor_vx_sew16_004();
      test_vor_vx_sew16_005();
      test_vor_vx_sew32_006();
      test_vor_vx_sew32_007();
      test_vor_vx_sew32_008();
      test_vxor_vx_sew8_000();
      test_vxor_vx_sew8_001();
      test_vxor_vx_sew8_002();
      test_vxor_vx_sew16_003();
      test_vxor_vx_sew16_004();
      test_vxor_vx_sew16_005();
      test_vxor_vx_sew32_006();
      test_vxor_vx_sew32_007();
      test_vxor_vx_sew32_008();
      test_vsll_vx_sew8_000();
      test_vsll_vx_sew8_001();
      test_vsll_vx_sew8_002();
      test_vsll_vx_sew16_003();
      test_vsll_vx_sew16_004();
      test_vsll_vx_sew16_005();
      test_vsll_vx_sew32_006();
      test_vsll_vx_sew32_007();
      test_vsll_vx_sew32_008();
      test_vsrl_vx_sew8_000();
      test_vsrl_vx_sew8_001();
      test_vsrl_vx_sew8_002();
      test_vsrl_vx_sew16_003();
      test_vsrl_vx_sew16_004();
      test_vsrl_vx_sew16_005();
      test_vsrl_vx_sew32_006();
      test_vsrl_vx_sew32_007();
      test_vsrl_vx_sew32_008();
      test_vsra_vx_sew8_000();
      test_vsra_vx_sew8_001();
      test_vsra_vx_sew8_002();
      test_vsra_vx_sew16_003();
      test_vsra_vx_sew16_004();
      test_vsra_vx_sew16_005();
      test_vsra_vx_sew32_006();
      test_vsra_vx_sew32_007();
      test_vsra_vx_sew32_008();
      test_vmin_vx_sew8_000();
      test_vmin_vx_sew8_001();
      test_vmin_vx_sew8_002();
      test_vmin_vx_sew16_003();
      test_vmin_vx_sew16_004();
      test_vmin_vx_sew16_005();
      test_vmin_vx_sew32_006();
      test_vmin_vx_sew32_007();
      test_vmin_vx_sew32_008();
      test_vmax_vx_sew8_000();
      test_vmax_vx_sew8_001();
      test_vmax_vx_sew8_002();
      test_vmax_vx_sew16_003();
      test_vmax_vx_sew16_004();
      test_vmax_vx_sew16_005();
      test_vmax_vx_sew32_006();
      test_vmax_vx_sew32_007();
      test_vmax_vx_sew32_008();
      test_vminu_vx_sew8_000();
      test_vminu_vx_sew8_001();
      test_vminu_vx_sew8_002();
      test_vminu_vx_sew16_003();
      test_vminu_vx_sew16_004();
      test_vminu_vx_sew16_005();
      test_vminu_vx_sew32_006();
      test_vminu_vx_sew32_007();
      test_vminu_vx_sew32_008();
      test_vmaxu_vx_sew8_000();
      test_vmaxu_vx_sew8_001();
      test_vmaxu_vx_sew8_002();
      test_vmaxu_vx_sew16_003();
      test_vmaxu_vx_sew16_004();
      test_vmaxu_vx_sew16_005();
      test_vmaxu_vx_sew32_006();
      test_vmaxu_vx_sew32_007();
      test_vmaxu_vx_sew32_008();
      $display("ALU .vx: 108 tests done");
    end
  endtask
