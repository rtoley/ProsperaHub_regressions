// VPU v0.3c - PERM Tests (54 tests)

  task automatic test_vmv_v_v_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd1, replicate_8(DLEN, 8'h0));
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e0081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 8, 8'h0, "test_vmv_v_v_sew8_000");
    end
  endtask

  task automatic test_vmv_v_v_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd1, replicate_8(DLEN, 8'h55));
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e0081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 8, 8'h55, "test_vmv_v_v_sew8_001");
    end
  endtask

  task automatic test_vmv_v_v_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd1, replicate_8(DLEN, 8'haa));
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e0081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 8, 8'haa, "test_vmv_v_v_sew8_002");
    end
  endtask

  task automatic test_vmv_v_v_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd1, replicate_8(DLEN, 8'hff));
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e0081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 8, 8'hff, "test_vmv_v_v_sew8_003");
    end
  endtask

  task automatic test_vmv_v_v_sew16_004;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd1, replicate_16(DLEN, 16'h0));
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e0081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 16, 16'h0, "test_vmv_v_v_sew16_004");
    end
  endtask

  task automatic test_vmv_v_v_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd1, replicate_16(DLEN, 16'h55));
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e0081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 16, 16'h55, "test_vmv_v_v_sew16_005");
    end
  endtask

  task automatic test_vmv_v_v_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd1, replicate_16(DLEN, 16'haa));
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e0081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 16, 16'haa, "test_vmv_v_v_sew16_006");
    end
  endtask

  task automatic test_vmv_v_v_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd1, replicate_16(DLEN, 16'hff));
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e0081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 16, 16'hff, "test_vmv_v_v_sew16_007");
    end
  endtask

  task automatic test_vmv_v_v_sew32_008;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd1, replicate_32(DLEN, 32'h0));
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e0081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 32, 32'h0, "test_vmv_v_v_sew32_008");
    end
  endtask

  task automatic test_vmv_v_v_sew32_009;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd1, replicate_32(DLEN, 32'h55));
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e0081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 32, 32'h55, "test_vmv_v_v_sew32_009");
    end
  endtask

  task automatic test_vmv_v_v_sew32_010;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd1, replicate_32(DLEN, 32'haa));
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e0081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 32, 32'haa, "test_vmv_v_v_sew32_010");
    end
  endtask

  task automatic test_vmv_v_v_sew32_011;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd1, replicate_32(DLEN, 32'hff));
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e0081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 32, 32'hff, "test_vmv_v_v_sew32_011");
    end
  endtask

  task automatic test_vmv_v_x_sew8_012;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e00c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3, 8, 8'h0, "test_vmv_v_x_sew8_012");
    end
  endtask

  task automatic test_vmv_v_x_sew8_013;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e00c1d7, 32'h00000012); wait_done(100);
      check_vrf_elem0_sew(5'd3, 8, 8'h12, "test_vmv_v_x_sew8_013");
    end
  endtask

  task automatic test_vmv_v_x_sew8_014;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e00c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3, 8, 8'h7f, "test_vmv_v_x_sew8_014");
    end
  endtask

  task automatic test_vmv_v_x_sew8_015;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e00c1d7, 32'h00000080); wait_done(100);
      check_vrf_elem0_sew(5'd3, 8, 8'h80, "test_vmv_v_x_sew8_015");
    end
  endtask

  task automatic test_vmv_v_x_sew8_016;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e00c1d7, 32'h000000ff); wait_done(100);
      check_vrf_elem0_sew(5'd3, 8, 8'hff, "test_vmv_v_x_sew8_016");
    end
  endtask

  task automatic test_vmv_v_x_sew16_017;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e00c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3, 16, 16'h0, "test_vmv_v_x_sew16_017");
    end
  endtask

  task automatic test_vmv_v_x_sew16_018;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e00c1d7, 32'h00000012); wait_done(100);
      check_vrf_elem0_sew(5'd3, 16, 16'h12, "test_vmv_v_x_sew16_018");
    end
  endtask

  task automatic test_vmv_v_x_sew16_019;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e00c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3, 16, 16'h7f, "test_vmv_v_x_sew16_019");
    end
  endtask

  task automatic test_vmv_v_x_sew16_020;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e00c1d7, 32'h00000080); wait_done(100);
      check_vrf_elem0_sew(5'd3, 16, 16'h80, "test_vmv_v_x_sew16_020");
    end
  endtask

  task automatic test_vmv_v_x_sew16_021;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e00c1d7, 32'h000000ff); wait_done(100);
      check_vrf_elem0_sew(5'd3, 16, 16'hff, "test_vmv_v_x_sew16_021");
    end
  endtask

  task automatic test_vmv_v_x_sew32_022;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e00c1d7, 32'h00000000); wait_done(100);
      check_vrf_elem0_sew(5'd3, 32, 32'h0, "test_vmv_v_x_sew32_022");
    end
  endtask

  task automatic test_vmv_v_x_sew32_023;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e00c1d7, 32'h00000012); wait_done(100);
      check_vrf_elem0_sew(5'd3, 32, 32'h12, "test_vmv_v_x_sew32_023");
    end
  endtask

  task automatic test_vmv_v_x_sew32_024;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e00c1d7, 32'h0000007f); wait_done(100);
      check_vrf_elem0_sew(5'd3, 32, 32'h7f, "test_vmv_v_x_sew32_024");
    end
  endtask

  task automatic test_vmv_v_x_sew32_025;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e00c1d7, 32'h00000080); wait_done(100);
      check_vrf_elem0_sew(5'd3, 32, 32'h80, "test_vmv_v_x_sew32_025");
    end
  endtask

  task automatic test_vmv_v_x_sew32_026;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e00c1d7, 32'h000000ff); wait_done(100);
      check_vrf_elem0_sew(5'd3, 32, 32'hff, "test_vmv_v_x_sew32_026");
    end
  endtask

  task automatic test_vmv_v_i_sew8_027;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e0031d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 8, 8'h0, "test_vmv_v_i_sew8_027");
    end
  endtask

  task automatic test_vmv_v_i_sew8_028;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e00b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 8, 8'h1, "test_vmv_v_i_sew8_028");
    end
  endtask

  task automatic test_vmv_v_i_sew8_029;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e07b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 8, 8'hf, "test_vmv_v_i_sew8_029");
    end
  endtask

  task automatic test_vmv_v_i_sew8_030;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e0831d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 8, 8'hf0, "test_vmv_v_i_sew8_030");
    end
  endtask

  task automatic test_vmv_v_i_sew8_031;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e0fb1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 8, 8'hff, "test_vmv_v_i_sew8_031");
    end
  endtask

  task automatic test_vmv_v_i_sew16_032;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e0031d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 16, 16'h0, "test_vmv_v_i_sew16_032");
    end
  endtask

  task automatic test_vmv_v_i_sew16_033;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e00b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 16, 16'h1, "test_vmv_v_i_sew16_033");
    end
  endtask

  task automatic test_vmv_v_i_sew16_034;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e07b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 16, 16'hf, "test_vmv_v_i_sew16_034");
    end
  endtask

  task automatic test_vmv_v_i_sew16_035;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e0831d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 16, 16'hfff0, "test_vmv_v_i_sew16_035");
    end
  endtask

  task automatic test_vmv_v_i_sew16_036;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e0fb1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 16, 16'hffff, "test_vmv_v_i_sew16_036");
    end
  endtask

  task automatic test_vmv_v_i_sew32_037;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e0031d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 32, 32'h0, "test_vmv_v_i_sew32_037");
    end
  endtask

  task automatic test_vmv_v_i_sew32_038;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e00b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 32, 32'h1, "test_vmv_v_i_sew32_038");
    end
  endtask

  task automatic test_vmv_v_i_sew32_039;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e07b1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 32, 32'hf, "test_vmv_v_i_sew32_039");
    end
  endtask

  task automatic test_vmv_v_i_sew32_040;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e0831d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 32, 32'hfffffff0, "test_vmv_v_i_sew32_040");
    end
  endtask

  task automatic test_vmv_v_i_sew32_041;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5e0fb1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 32, 32'hffffffff, "test_vmv_v_i_sew32_041");
    end
  endtask

  task automatic test_vmerge_vvm_sew8_042;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd0, {{DLEN-8{1'b0}}, 8'h00});  // mask in v0
      vrf_write(5'd2, replicate_8(DLEN, 8'h0));
      vrf_write(5'd1, replicate_8(DLEN, 8'hff));
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5c2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 8, 8'h0, "test_vmerge_vvm_sew8_042");
    end
  endtask

  task automatic test_vmerge_vvm_sew8_043;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd0, {{DLEN-8{1'b0}}, 8'hff});  // mask in v0
      vrf_write(5'd2, replicate_8(DLEN, 8'h0));
      vrf_write(5'd1, replicate_8(DLEN, 8'hff));
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5c2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 8, 8'hff, "test_vmerge_vvm_sew8_043");
    end
  endtask

  task automatic test_vmerge_vvm_sew8_044;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd0, {{DLEN-8{1'b0}}, 8'h0f});  // mask in v0
      vrf_write(5'd2, replicate_8(DLEN, 8'h55));
      vrf_write(5'd1, replicate_8(DLEN, 8'haa));
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5c2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 8, 8'haa, "test_vmerge_vvm_sew8_044");
    end
  endtask

  task automatic test_vmerge_vvm_sew8_045;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd0, {{DLEN-8{1'b0}}, 8'h55});  // mask in v0
      vrf_write(5'd2, replicate_8(DLEN, 8'h12));
      vrf_write(5'd1, replicate_8(DLEN, 8'h34));
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5c2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 8, 8'h34, "test_vmerge_vvm_sew8_045");
    end
  endtask

  task automatic test_vmerge_vvm_sew16_046;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd0, {{DLEN-8{1'b0}}, 8'h00});  // mask in v0
      vrf_write(5'd2, replicate_16(DLEN, 16'h0));
      vrf_write(5'd1, replicate_16(DLEN, 16'hff));
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5c2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 16, 16'h0, "test_vmerge_vvm_sew16_046");
    end
  endtask

  task automatic test_vmerge_vvm_sew16_047;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd0, {{DLEN-8{1'b0}}, 8'hff});  // mask in v0
      vrf_write(5'd2, replicate_16(DLEN, 16'h0));
      vrf_write(5'd1, replicate_16(DLEN, 16'hff));
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5c2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 16, 16'hff, "test_vmerge_vvm_sew16_047");
    end
  endtask

  task automatic test_vmerge_vvm_sew16_048;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd0, {{DLEN-8{1'b0}}, 8'h0f});  // mask in v0
      vrf_write(5'd2, replicate_16(DLEN, 16'h55));
      vrf_write(5'd1, replicate_16(DLEN, 16'haa));
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5c2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 16, 16'haa, "test_vmerge_vvm_sew16_048");
    end
  endtask

  task automatic test_vmerge_vvm_sew16_049;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd0, {{DLEN-8{1'b0}}, 8'h55});  // mask in v0
      vrf_write(5'd2, replicate_16(DLEN, 16'h12));
      vrf_write(5'd1, replicate_16(DLEN, 16'h34));
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5c2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 16, 16'h34, "test_vmerge_vvm_sew16_049");
    end
  endtask

  task automatic test_vmerge_vvm_sew32_050;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd0, {{DLEN-8{1'b0}}, 8'h00});  // mask in v0
      vrf_write(5'd2, replicate_32(DLEN, 32'h0));
      vrf_write(5'd1, replicate_32(DLEN, 32'hff));
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5c2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 32, 32'h0, "test_vmerge_vvm_sew32_050");
    end
  endtask

  task automatic test_vmerge_vvm_sew32_051;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd0, {{DLEN-8{1'b0}}, 8'hff});  // mask in v0
      vrf_write(5'd2, replicate_32(DLEN, 32'h0));
      vrf_write(5'd1, replicate_32(DLEN, 32'hff));
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5c2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 32, 32'hff, "test_vmerge_vvm_sew32_051");
    end
  endtask

  task automatic test_vmerge_vvm_sew32_052;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd0, {{DLEN-8{1'b0}}, 8'h0f});  // mask in v0
      vrf_write(5'd2, replicate_32(DLEN, 32'h55));
      vrf_write(5'd1, replicate_32(DLEN, 32'haa));
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5c2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 32, 32'haa, "test_vmerge_vvm_sew32_052");
    end
  endtask

  task automatic test_vmerge_vvm_sew32_053;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd0, {{DLEN-8{1'b0}}, 8'h55});  // mask in v0
      vrf_write(5'd2, replicate_32(DLEN, 32'h12));
      vrf_write(5'd1, replicate_32(DLEN, 32'h34));
      vrf_write(5'd3, {DLEN{1'b0}});
      issue(32'h5c2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3, 32, 32'h34, "test_vmerge_vvm_sew32_053");
    end
  endtask


  task automatic run_perm_tests;
    begin
      $display("=== PERM TESTS (54) ===");
      test_vmv_v_v_sew8_000();
      test_vmv_v_v_sew8_001();
      test_vmv_v_v_sew8_002();
      test_vmv_v_v_sew8_003();
      test_vmv_v_v_sew16_004();
      test_vmv_v_v_sew16_005();
      test_vmv_v_v_sew16_006();
      test_vmv_v_v_sew16_007();
      test_vmv_v_v_sew32_008();
      test_vmv_v_v_sew32_009();
      test_vmv_v_v_sew32_010();
      test_vmv_v_v_sew32_011();
      test_vmv_v_x_sew8_012();
      test_vmv_v_x_sew8_013();
      test_vmv_v_x_sew8_014();
      test_vmv_v_x_sew8_015();
      test_vmv_v_x_sew8_016();
      test_vmv_v_x_sew16_017();
      test_vmv_v_x_sew16_018();
      test_vmv_v_x_sew16_019();
      test_vmv_v_x_sew16_020();
      test_vmv_v_x_sew16_021();
      test_vmv_v_x_sew32_022();
      test_vmv_v_x_sew32_023();
      test_vmv_v_x_sew32_024();
      test_vmv_v_x_sew32_025();
      test_vmv_v_x_sew32_026();
      test_vmv_v_i_sew8_027();
      test_vmv_v_i_sew8_028();
      test_vmv_v_i_sew8_029();
      test_vmv_v_i_sew8_030();
      test_vmv_v_i_sew8_031();
      test_vmv_v_i_sew16_032();
      test_vmv_v_i_sew16_033();
      test_vmv_v_i_sew16_034();
      test_vmv_v_i_sew16_035();
      test_vmv_v_i_sew16_036();
      test_vmv_v_i_sew32_037();
      test_vmv_v_i_sew32_038();
      test_vmv_v_i_sew32_039();
      test_vmv_v_i_sew32_040();
      test_vmv_v_i_sew32_041();
      test_vmerge_vvm_sew8_042();
      test_vmerge_vvm_sew8_043();
      test_vmerge_vvm_sew8_044();
      test_vmerge_vvm_sew8_045();
      test_vmerge_vvm_sew16_046();
      test_vmerge_vvm_sew16_047();
      test_vmerge_vvm_sew16_048();
      test_vmerge_vvm_sew16_049();
      test_vmerge_vvm_sew32_050();
      test_vmerge_vvm_sew32_051();
      test_vmerge_vvm_sew32_052();
      test_vmerge_vvm_sew32_053();
      $display("PERM: 54 tests done");
    end
  endtask
