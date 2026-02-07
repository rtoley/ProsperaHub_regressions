// VPU v0.3c - CMP Tests (192 tests)

  task automatic test_vmseq_vv_sew8_000;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h62208057); wait_done(100);
      n = VLEN/8; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmseq_vv_sew8_000");
    end
  endtask

  task automatic test_vmseq_vv_sew8_001;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h62208057); wait_done(100);
      n = VLEN/8; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmseq_vv_sew8_001");
    end
  endtask

  task automatic test_vmseq_vv_sew8_002;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h2));
      vrf_write(5'd0, 64'h0);
      issue(32'h62208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmseq_vv_sew8_002");
    end
  endtask

  task automatic test_vmseq_vv_sew8_003;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h2));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h62208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmseq_vv_sew8_003");
    end
  endtask

  task automatic test_vmseq_vv_sew8_004;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h80));
      vrf_write(5'd0, 64'h0);
      issue(32'h62208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmseq_vv_sew8_004");
    end
  endtask

  task automatic test_vmseq_vv_sew8_005;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      vrf_write(5'd0, 64'h0);
      issue(32'h62208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmseq_vv_sew8_005");
    end
  endtask

  task automatic test_vmseq_vv_sew8_006;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h62208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmseq_vv_sew8_006");
    end
  endtask

  task automatic test_vmseq_vv_sew8_007;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'hff));
      vrf_write(5'd0, 64'h0);
      issue(32'h62208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmseq_vv_sew8_007");
    end
  endtask

  task automatic test_vmseq_vv_sew16_008;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h62208057); wait_done(100);
      n = VLEN/16; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmseq_vv_sew16_008");
    end
  endtask

  task automatic test_vmseq_vv_sew16_009;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h62208057); wait_done(100);
      n = VLEN/16; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmseq_vv_sew16_009");
    end
  endtask

  task automatic test_vmseq_vv_sew16_010;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h2));
      vrf_write(5'd0, 64'h0);
      issue(32'h62208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmseq_vv_sew16_010");
    end
  endtask

  task automatic test_vmseq_vv_sew16_011;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h2));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h62208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmseq_vv_sew16_011");
    end
  endtask

  task automatic test_vmseq_vv_sew16_012;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h80));
      vrf_write(5'd0, 64'h0);
      issue(32'h62208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmseq_vv_sew16_012");
    end
  endtask

  task automatic test_vmseq_vv_sew16_013;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      vrf_write(5'd0, 64'h0);
      issue(32'h62208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmseq_vv_sew16_013");
    end
  endtask

  task automatic test_vmseq_vv_sew16_014;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h62208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmseq_vv_sew16_014");
    end
  endtask

  task automatic test_vmseq_vv_sew16_015;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'hff));
      vrf_write(5'd0, 64'h0);
      issue(32'h62208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmseq_vv_sew16_015");
    end
  endtask

  task automatic test_vmseq_vv_sew32_016;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h62208057); wait_done(100);
      n = VLEN/32; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmseq_vv_sew32_016");
    end
  endtask

  task automatic test_vmseq_vv_sew32_017;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h62208057); wait_done(100);
      n = VLEN/32; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmseq_vv_sew32_017");
    end
  endtask

  task automatic test_vmseq_vv_sew32_018;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h2));
      vrf_write(5'd0, 64'h0);
      issue(32'h62208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmseq_vv_sew32_018");
    end
  endtask

  task automatic test_vmseq_vv_sew32_019;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h2));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h62208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmseq_vv_sew32_019");
    end
  endtask

  task automatic test_vmseq_vv_sew32_020;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h80));
      vrf_write(5'd0, 64'h0);
      issue(32'h62208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmseq_vv_sew32_020");
    end
  endtask

  task automatic test_vmseq_vv_sew32_021;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      vrf_write(5'd0, 64'h0);
      issue(32'h62208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmseq_vv_sew32_021");
    end
  endtask

  task automatic test_vmseq_vv_sew32_022;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h62208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmseq_vv_sew32_022");
    end
  endtask

  task automatic test_vmseq_vv_sew32_023;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'hff));
      vrf_write(5'd0, 64'h0);
      issue(32'h62208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmseq_vv_sew32_023");
    end
  endtask

  task automatic test_vmsne_vv_sew8_000;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h66208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsne_vv_sew8_000");
    end
  endtask

  task automatic test_vmsne_vv_sew8_001;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h66208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsne_vv_sew8_001");
    end
  endtask

  task automatic test_vmsne_vv_sew8_002;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h2));
      vrf_write(5'd0, 64'h0);
      issue(32'h66208057); wait_done(100);
      n = VLEN/8; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsne_vv_sew8_002");
    end
  endtask

  task automatic test_vmsne_vv_sew8_003;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h2));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h66208057); wait_done(100);
      n = VLEN/8; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsne_vv_sew8_003");
    end
  endtask

  task automatic test_vmsne_vv_sew8_004;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h80));
      vrf_write(5'd0, 64'h0);
      issue(32'h66208057); wait_done(100);
      n = VLEN/8; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsne_vv_sew8_004");
    end
  endtask

  task automatic test_vmsne_vv_sew8_005;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      vrf_write(5'd0, 64'h0);
      issue(32'h66208057); wait_done(100);
      n = VLEN/8; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsne_vv_sew8_005");
    end
  endtask

  task automatic test_vmsne_vv_sew8_006;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h66208057); wait_done(100);
      n = VLEN/8; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsne_vv_sew8_006");
    end
  endtask

  task automatic test_vmsne_vv_sew8_007;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'hff));
      vrf_write(5'd0, 64'h0);
      issue(32'h66208057); wait_done(100);
      n = VLEN/8; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsne_vv_sew8_007");
    end
  endtask

  task automatic test_vmsne_vv_sew16_008;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h66208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsne_vv_sew16_008");
    end
  endtask

  task automatic test_vmsne_vv_sew16_009;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h66208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsne_vv_sew16_009");
    end
  endtask

  task automatic test_vmsne_vv_sew16_010;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h2));
      vrf_write(5'd0, 64'h0);
      issue(32'h66208057); wait_done(100);
      n = VLEN/16; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsne_vv_sew16_010");
    end
  endtask

  task automatic test_vmsne_vv_sew16_011;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h2));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h66208057); wait_done(100);
      n = VLEN/16; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsne_vv_sew16_011");
    end
  endtask

  task automatic test_vmsne_vv_sew16_012;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h80));
      vrf_write(5'd0, 64'h0);
      issue(32'h66208057); wait_done(100);
      n = VLEN/16; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsne_vv_sew16_012");
    end
  endtask

  task automatic test_vmsne_vv_sew16_013;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      vrf_write(5'd0, 64'h0);
      issue(32'h66208057); wait_done(100);
      n = VLEN/16; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsne_vv_sew16_013");
    end
  endtask

  task automatic test_vmsne_vv_sew16_014;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h66208057); wait_done(100);
      n = VLEN/16; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsne_vv_sew16_014");
    end
  endtask

  task automatic test_vmsne_vv_sew16_015;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'hff));
      vrf_write(5'd0, 64'h0);
      issue(32'h66208057); wait_done(100);
      n = VLEN/16; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsne_vv_sew16_015");
    end
  endtask

  task automatic test_vmsne_vv_sew32_016;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h66208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsne_vv_sew32_016");
    end
  endtask

  task automatic test_vmsne_vv_sew32_017;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h66208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsne_vv_sew32_017");
    end
  endtask

  task automatic test_vmsne_vv_sew32_018;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h2));
      vrf_write(5'd0, 64'h0);
      issue(32'h66208057); wait_done(100);
      n = VLEN/32; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsne_vv_sew32_018");
    end
  endtask

  task automatic test_vmsne_vv_sew32_019;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h2));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h66208057); wait_done(100);
      n = VLEN/32; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsne_vv_sew32_019");
    end
  endtask

  task automatic test_vmsne_vv_sew32_020;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h80));
      vrf_write(5'd0, 64'h0);
      issue(32'h66208057); wait_done(100);
      n = VLEN/32; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsne_vv_sew32_020");
    end
  endtask

  task automatic test_vmsne_vv_sew32_021;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      vrf_write(5'd0, 64'h0);
      issue(32'h66208057); wait_done(100);
      n = VLEN/32; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsne_vv_sew32_021");
    end
  endtask

  task automatic test_vmsne_vv_sew32_022;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h66208057); wait_done(100);
      n = VLEN/32; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsne_vv_sew32_022");
    end
  endtask

  task automatic test_vmsne_vv_sew32_023;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'hff));
      vrf_write(5'd0, 64'h0);
      issue(32'h66208057); wait_done(100);
      n = VLEN/32; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsne_vv_sew32_023");
    end
  endtask

  task automatic test_vmslt_vv_sew8_000;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h6e208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmslt_vv_sew8_000");
    end
  endtask

  task automatic test_vmslt_vv_sew8_001;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h6e208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmslt_vv_sew8_001");
    end
  endtask

  task automatic test_vmslt_vv_sew8_002;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h2));
      vrf_write(5'd0, 64'h0);
      issue(32'h6e208057); wait_done(100);
      n = VLEN/8; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmslt_vv_sew8_002");
    end
  endtask

  task automatic test_vmslt_vv_sew8_003;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h2));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h6e208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmslt_vv_sew8_003");
    end
  endtask

  task automatic test_vmslt_vv_sew8_004;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h80));
      vrf_write(5'd0, 64'h0);
      issue(32'h6e208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmslt_vv_sew8_004");
    end
  endtask

  task automatic test_vmslt_vv_sew8_005;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      vrf_write(5'd0, 64'h0);
      issue(32'h6e208057); wait_done(100);
      n = VLEN/8; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmslt_vv_sew8_005");
    end
  endtask

  task automatic test_vmslt_vv_sew8_006;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h6e208057); wait_done(100);
      n = VLEN/8; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmslt_vv_sew8_006");
    end
  endtask

  task automatic test_vmslt_vv_sew8_007;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'hff));
      vrf_write(5'd0, 64'h0);
      issue(32'h6e208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmslt_vv_sew8_007");
    end
  endtask

  task automatic test_vmslt_vv_sew16_008;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h6e208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmslt_vv_sew16_008");
    end
  endtask

  task automatic test_vmslt_vv_sew16_009;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h6e208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmslt_vv_sew16_009");
    end
  endtask

  task automatic test_vmslt_vv_sew16_010;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h2));
      vrf_write(5'd0, 64'h0);
      issue(32'h6e208057); wait_done(100);
      n = VLEN/16; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmslt_vv_sew16_010");
    end
  endtask

  task automatic test_vmslt_vv_sew16_011;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h2));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h6e208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmslt_vv_sew16_011");
    end
  endtask

  task automatic test_vmslt_vv_sew16_012;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h80));
      vrf_write(5'd0, 64'h0);
      issue(32'h6e208057); wait_done(100);
      n = VLEN/16; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmslt_vv_sew16_012");
    end
  endtask

  task automatic test_vmslt_vv_sew16_013;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      vrf_write(5'd0, 64'h0);
      issue(32'h6e208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmslt_vv_sew16_013");
    end
  endtask

  task automatic test_vmslt_vv_sew16_014;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h6e208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmslt_vv_sew16_014");
    end
  endtask

  task automatic test_vmslt_vv_sew16_015;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'hff));
      vrf_write(5'd0, 64'h0);
      issue(32'h6e208057); wait_done(100);
      n = VLEN/16; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmslt_vv_sew16_015");
    end
  endtask

  task automatic test_vmslt_vv_sew32_016;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h6e208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmslt_vv_sew32_016");
    end
  endtask

  task automatic test_vmslt_vv_sew32_017;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h6e208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmslt_vv_sew32_017");
    end
  endtask

  task automatic test_vmslt_vv_sew32_018;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h2));
      vrf_write(5'd0, 64'h0);
      issue(32'h6e208057); wait_done(100);
      n = VLEN/32; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmslt_vv_sew32_018");
    end
  endtask

  task automatic test_vmslt_vv_sew32_019;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h2));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h6e208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmslt_vv_sew32_019");
    end
  endtask

  task automatic test_vmslt_vv_sew32_020;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h80));
      vrf_write(5'd0, 64'h0);
      issue(32'h6e208057); wait_done(100);
      n = VLEN/32; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmslt_vv_sew32_020");
    end
  endtask

  task automatic test_vmslt_vv_sew32_021;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      vrf_write(5'd0, 64'h0);
      issue(32'h6e208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmslt_vv_sew32_021");
    end
  endtask

  task automatic test_vmslt_vv_sew32_022;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h6e208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmslt_vv_sew32_022");
    end
  endtask

  task automatic test_vmslt_vv_sew32_023;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'hff));
      vrf_write(5'd0, 64'h0);
      issue(32'h6e208057); wait_done(100);
      n = VLEN/32; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmslt_vv_sew32_023");
    end
  endtask

  task automatic test_vmsltu_vv_sew8_000;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h6a208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsltu_vv_sew8_000");
    end
  endtask

  task automatic test_vmsltu_vv_sew8_001;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h6a208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsltu_vv_sew8_001");
    end
  endtask

  task automatic test_vmsltu_vv_sew8_002;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h2));
      vrf_write(5'd0, 64'h0);
      issue(32'h6a208057); wait_done(100);
      n = VLEN/8; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsltu_vv_sew8_002");
    end
  endtask

  task automatic test_vmsltu_vv_sew8_003;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h2));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h6a208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsltu_vv_sew8_003");
    end
  endtask

  task automatic test_vmsltu_vv_sew8_004;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h80));
      vrf_write(5'd0, 64'h0);
      issue(32'h6a208057); wait_done(100);
      n = VLEN/8; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsltu_vv_sew8_004");
    end
  endtask

  task automatic test_vmsltu_vv_sew8_005;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      vrf_write(5'd0, 64'h0);
      issue(32'h6a208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsltu_vv_sew8_005");
    end
  endtask

  task automatic test_vmsltu_vv_sew8_006;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h6a208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsltu_vv_sew8_006");
    end
  endtask

  task automatic test_vmsltu_vv_sew8_007;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'hff));
      vrf_write(5'd0, 64'h0);
      issue(32'h6a208057); wait_done(100);
      n = VLEN/8; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsltu_vv_sew8_007");
    end
  endtask

  task automatic test_vmsltu_vv_sew16_008;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h6a208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsltu_vv_sew16_008");
    end
  endtask

  task automatic test_vmsltu_vv_sew16_009;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h6a208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsltu_vv_sew16_009");
    end
  endtask

  task automatic test_vmsltu_vv_sew16_010;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h2));
      vrf_write(5'd0, 64'h0);
      issue(32'h6a208057); wait_done(100);
      n = VLEN/16; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsltu_vv_sew16_010");
    end
  endtask

  task automatic test_vmsltu_vv_sew16_011;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h2));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h6a208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsltu_vv_sew16_011");
    end
  endtask

  task automatic test_vmsltu_vv_sew16_012;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h80));
      vrf_write(5'd0, 64'h0);
      issue(32'h6a208057); wait_done(100);
      n = VLEN/16; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsltu_vv_sew16_012");
    end
  endtask

  task automatic test_vmsltu_vv_sew16_013;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      vrf_write(5'd0, 64'h0);
      issue(32'h6a208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsltu_vv_sew16_013");
    end
  endtask

  task automatic test_vmsltu_vv_sew16_014;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h6a208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsltu_vv_sew16_014");
    end
  endtask

  task automatic test_vmsltu_vv_sew16_015;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'hff));
      vrf_write(5'd0, 64'h0);
      issue(32'h6a208057); wait_done(100);
      n = VLEN/16; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsltu_vv_sew16_015");
    end
  endtask

  task automatic test_vmsltu_vv_sew32_016;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h6a208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsltu_vv_sew32_016");
    end
  endtask

  task automatic test_vmsltu_vv_sew32_017;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h6a208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsltu_vv_sew32_017");
    end
  endtask

  task automatic test_vmsltu_vv_sew32_018;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h2));
      vrf_write(5'd0, 64'h0);
      issue(32'h6a208057); wait_done(100);
      n = VLEN/32; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsltu_vv_sew32_018");
    end
  endtask

  task automatic test_vmsltu_vv_sew32_019;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h2));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h6a208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsltu_vv_sew32_019");
    end
  endtask

  task automatic test_vmsltu_vv_sew32_020;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h80));
      vrf_write(5'd0, 64'h0);
      issue(32'h6a208057); wait_done(100);
      n = VLEN/32; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsltu_vv_sew32_020");
    end
  endtask

  task automatic test_vmsltu_vv_sew32_021;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      vrf_write(5'd0, 64'h0);
      issue(32'h6a208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsltu_vv_sew32_021");
    end
  endtask

  task automatic test_vmsltu_vv_sew32_022;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h6a208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsltu_vv_sew32_022");
    end
  endtask

  task automatic test_vmsltu_vv_sew32_023;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'hff));
      vrf_write(5'd0, 64'h0);
      issue(32'h6a208057); wait_done(100);
      n = VLEN/32; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsltu_vv_sew32_023");
    end
  endtask

  task automatic test_vmsle_vv_sew8_000;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h76208057); wait_done(100);
      n = VLEN/8; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsle_vv_sew8_000");
    end
  endtask

  task automatic test_vmsle_vv_sew8_001;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h76208057); wait_done(100);
      n = VLEN/8; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsle_vv_sew8_001");
    end
  endtask

  task automatic test_vmsle_vv_sew8_002;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h2));
      vrf_write(5'd0, 64'h0);
      issue(32'h76208057); wait_done(100);
      n = VLEN/8; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsle_vv_sew8_002");
    end
  endtask

  task automatic test_vmsle_vv_sew8_003;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h2));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h76208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsle_vv_sew8_003");
    end
  endtask

  task automatic test_vmsle_vv_sew8_004;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h80));
      vrf_write(5'd0, 64'h0);
      issue(32'h76208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsle_vv_sew8_004");
    end
  endtask

  task automatic test_vmsle_vv_sew8_005;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      vrf_write(5'd0, 64'h0);
      issue(32'h76208057); wait_done(100);
      n = VLEN/8; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsle_vv_sew8_005");
    end
  endtask

  task automatic test_vmsle_vv_sew8_006;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h76208057); wait_done(100);
      n = VLEN/8; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsle_vv_sew8_006");
    end
  endtask

  task automatic test_vmsle_vv_sew8_007;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'hff));
      vrf_write(5'd0, 64'h0);
      issue(32'h76208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsle_vv_sew8_007");
    end
  endtask

  task automatic test_vmsle_vv_sew16_008;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h76208057); wait_done(100);
      n = VLEN/16; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsle_vv_sew16_008");
    end
  endtask

  task automatic test_vmsle_vv_sew16_009;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h76208057); wait_done(100);
      n = VLEN/16; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsle_vv_sew16_009");
    end
  endtask

  task automatic test_vmsle_vv_sew16_010;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h2));
      vrf_write(5'd0, 64'h0);
      issue(32'h76208057); wait_done(100);
      n = VLEN/16; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsle_vv_sew16_010");
    end
  endtask

  task automatic test_vmsle_vv_sew16_011;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h2));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h76208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsle_vv_sew16_011");
    end
  endtask

  task automatic test_vmsle_vv_sew16_012;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h80));
      vrf_write(5'd0, 64'h0);
      issue(32'h76208057); wait_done(100);
      n = VLEN/16; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsle_vv_sew16_012");
    end
  endtask

  task automatic test_vmsle_vv_sew16_013;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      vrf_write(5'd0, 64'h0);
      issue(32'h76208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsle_vv_sew16_013");
    end
  endtask

  task automatic test_vmsle_vv_sew16_014;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h76208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsle_vv_sew16_014");
    end
  endtask

  task automatic test_vmsle_vv_sew16_015;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'hff));
      vrf_write(5'd0, 64'h0);
      issue(32'h76208057); wait_done(100);
      n = VLEN/16; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsle_vv_sew16_015");
    end
  endtask

  task automatic test_vmsle_vv_sew32_016;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h76208057); wait_done(100);
      n = VLEN/32; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsle_vv_sew32_016");
    end
  endtask

  task automatic test_vmsle_vv_sew32_017;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h76208057); wait_done(100);
      n = VLEN/32; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsle_vv_sew32_017");
    end
  endtask

  task automatic test_vmsle_vv_sew32_018;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h2));
      vrf_write(5'd0, 64'h0);
      issue(32'h76208057); wait_done(100);
      n = VLEN/32; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsle_vv_sew32_018");
    end
  endtask

  task automatic test_vmsle_vv_sew32_019;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h2));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h76208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsle_vv_sew32_019");
    end
  endtask

  task automatic test_vmsle_vv_sew32_020;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h80));
      vrf_write(5'd0, 64'h0);
      issue(32'h76208057); wait_done(100);
      n = VLEN/32; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsle_vv_sew32_020");
    end
  endtask

  task automatic test_vmsle_vv_sew32_021;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      vrf_write(5'd0, 64'h0);
      issue(32'h76208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsle_vv_sew32_021");
    end
  endtask

  task automatic test_vmsle_vv_sew32_022;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h76208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsle_vv_sew32_022");
    end
  endtask

  task automatic test_vmsle_vv_sew32_023;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'hff));
      vrf_write(5'd0, 64'h0);
      issue(32'h76208057); wait_done(100);
      n = VLEN/32; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsle_vv_sew32_023");
    end
  endtask

  task automatic test_vmsleu_vv_sew8_000;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h72208057); wait_done(100);
      n = VLEN/8; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsleu_vv_sew8_000");
    end
  endtask

  task automatic test_vmsleu_vv_sew8_001;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h72208057); wait_done(100);
      n = VLEN/8; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsleu_vv_sew8_001");
    end
  endtask

  task automatic test_vmsleu_vv_sew8_002;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h2));
      vrf_write(5'd0, 64'h0);
      issue(32'h72208057); wait_done(100);
      n = VLEN/8; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsleu_vv_sew8_002");
    end
  endtask

  task automatic test_vmsleu_vv_sew8_003;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h2));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h72208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsleu_vv_sew8_003");
    end
  endtask

  task automatic test_vmsleu_vv_sew8_004;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h80));
      vrf_write(5'd0, 64'h0);
      issue(32'h72208057); wait_done(100);
      n = VLEN/8; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsleu_vv_sew8_004");
    end
  endtask

  task automatic test_vmsleu_vv_sew8_005;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      vrf_write(5'd0, 64'h0);
      issue(32'h72208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsleu_vv_sew8_005");
    end
  endtask

  task automatic test_vmsleu_vv_sew8_006;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h72208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsleu_vv_sew8_006");
    end
  endtask

  task automatic test_vmsleu_vv_sew8_007;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'hff));
      vrf_write(5'd0, 64'h0);
      issue(32'h72208057); wait_done(100);
      n = VLEN/8; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsleu_vv_sew8_007");
    end
  endtask

  task automatic test_vmsleu_vv_sew16_008;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h72208057); wait_done(100);
      n = VLEN/16; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsleu_vv_sew16_008");
    end
  endtask

  task automatic test_vmsleu_vv_sew16_009;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h72208057); wait_done(100);
      n = VLEN/16; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsleu_vv_sew16_009");
    end
  endtask

  task automatic test_vmsleu_vv_sew16_010;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h2));
      vrf_write(5'd0, 64'h0);
      issue(32'h72208057); wait_done(100);
      n = VLEN/16; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsleu_vv_sew16_010");
    end
  endtask

  task automatic test_vmsleu_vv_sew16_011;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h2));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h72208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsleu_vv_sew16_011");
    end
  endtask

  task automatic test_vmsleu_vv_sew16_012;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h80));
      vrf_write(5'd0, 64'h0);
      issue(32'h72208057); wait_done(100);
      n = VLEN/16; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsleu_vv_sew16_012");
    end
  endtask

  task automatic test_vmsleu_vv_sew16_013;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      vrf_write(5'd0, 64'h0);
      issue(32'h72208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsleu_vv_sew16_013");
    end
  endtask

  task automatic test_vmsleu_vv_sew16_014;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h72208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsleu_vv_sew16_014");
    end
  endtask

  task automatic test_vmsleu_vv_sew16_015;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'hff));
      vrf_write(5'd0, 64'h0);
      issue(32'h72208057); wait_done(100);
      n = VLEN/16; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsleu_vv_sew16_015");
    end
  endtask

  task automatic test_vmsleu_vv_sew32_016;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h72208057); wait_done(100);
      n = VLEN/32; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsleu_vv_sew32_016");
    end
  endtask

  task automatic test_vmsleu_vv_sew32_017;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h72208057); wait_done(100);
      n = VLEN/32; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsleu_vv_sew32_017");
    end
  endtask

  task automatic test_vmsleu_vv_sew32_018;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h2));
      vrf_write(5'd0, 64'h0);
      issue(32'h72208057); wait_done(100);
      n = VLEN/32; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsleu_vv_sew32_018");
    end
  endtask

  task automatic test_vmsleu_vv_sew32_019;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h2));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h72208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsleu_vv_sew32_019");
    end
  endtask

  task automatic test_vmsleu_vv_sew32_020;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h80));
      vrf_write(5'd0, 64'h0);
      issue(32'h72208057); wait_done(100);
      n = VLEN/32; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsleu_vv_sew32_020");
    end
  endtask

  task automatic test_vmsleu_vv_sew32_021;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      vrf_write(5'd0, 64'h0);
      issue(32'h72208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsleu_vv_sew32_021");
    end
  endtask

  task automatic test_vmsleu_vv_sew32_022;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h72208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsleu_vv_sew32_022");
    end
  endtask

  task automatic test_vmsleu_vv_sew32_023;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'hff));
      vrf_write(5'd0, 64'h0);
      issue(32'h72208057); wait_done(100);
      n = VLEN/32; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsleu_vv_sew32_023");
    end
  endtask

  task automatic test_vmsgt_vv_sew8_000;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h7e208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgt_vv_sew8_000");
    end
  endtask

  task automatic test_vmsgt_vv_sew8_001;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h7e208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgt_vv_sew8_001");
    end
  endtask

  task automatic test_vmsgt_vv_sew8_002;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h2));
      vrf_write(5'd0, 64'h0);
      issue(32'h7e208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgt_vv_sew8_002");
    end
  endtask

  task automatic test_vmsgt_vv_sew8_003;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h2));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h7e208057); wait_done(100);
      n = VLEN/8; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgt_vv_sew8_003");
    end
  endtask

  task automatic test_vmsgt_vv_sew8_004;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h80));
      vrf_write(5'd0, 64'h0);
      issue(32'h7e208057); wait_done(100);
      n = VLEN/8; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgt_vv_sew8_004");
    end
  endtask

  task automatic test_vmsgt_vv_sew8_005;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      vrf_write(5'd0, 64'h0);
      issue(32'h7e208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgt_vv_sew8_005");
    end
  endtask

  task automatic test_vmsgt_vv_sew8_006;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h7e208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgt_vv_sew8_006");
    end
  endtask

  task automatic test_vmsgt_vv_sew8_007;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'hff));
      vrf_write(5'd0, 64'h0);
      issue(32'h7e208057); wait_done(100);
      n = VLEN/8; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgt_vv_sew8_007");
    end
  endtask

  task automatic test_vmsgt_vv_sew16_008;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h7e208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgt_vv_sew16_008");
    end
  endtask

  task automatic test_vmsgt_vv_sew16_009;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h7e208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgt_vv_sew16_009");
    end
  endtask

  task automatic test_vmsgt_vv_sew16_010;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h2));
      vrf_write(5'd0, 64'h0);
      issue(32'h7e208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgt_vv_sew16_010");
    end
  endtask

  task automatic test_vmsgt_vv_sew16_011;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h2));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h7e208057); wait_done(100);
      n = VLEN/16; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgt_vv_sew16_011");
    end
  endtask

  task automatic test_vmsgt_vv_sew16_012;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h80));
      vrf_write(5'd0, 64'h0);
      issue(32'h7e208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgt_vv_sew16_012");
    end
  endtask

  task automatic test_vmsgt_vv_sew16_013;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      vrf_write(5'd0, 64'h0);
      issue(32'h7e208057); wait_done(100);
      n = VLEN/16; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgt_vv_sew16_013");
    end
  endtask

  task automatic test_vmsgt_vv_sew16_014;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h7e208057); wait_done(100);
      n = VLEN/16; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgt_vv_sew16_014");
    end
  endtask

  task automatic test_vmsgt_vv_sew16_015;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'hff));
      vrf_write(5'd0, 64'h0);
      issue(32'h7e208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgt_vv_sew16_015");
    end
  endtask

  task automatic test_vmsgt_vv_sew32_016;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h7e208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgt_vv_sew32_016");
    end
  endtask

  task automatic test_vmsgt_vv_sew32_017;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h7e208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgt_vv_sew32_017");
    end
  endtask

  task automatic test_vmsgt_vv_sew32_018;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h2));
      vrf_write(5'd0, 64'h0);
      issue(32'h7e208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgt_vv_sew32_018");
    end
  endtask

  task automatic test_vmsgt_vv_sew32_019;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h2));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h7e208057); wait_done(100);
      n = VLEN/32; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgt_vv_sew32_019");
    end
  endtask

  task automatic test_vmsgt_vv_sew32_020;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h80));
      vrf_write(5'd0, 64'h0);
      issue(32'h7e208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgt_vv_sew32_020");
    end
  endtask

  task automatic test_vmsgt_vv_sew32_021;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      vrf_write(5'd0, 64'h0);
      issue(32'h7e208057); wait_done(100);
      n = VLEN/32; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgt_vv_sew32_021");
    end
  endtask

  task automatic test_vmsgt_vv_sew32_022;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h7e208057); wait_done(100);
      n = VLEN/32; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgt_vv_sew32_022");
    end
  endtask

  task automatic test_vmsgt_vv_sew32_023;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'hff));
      vrf_write(5'd0, 64'h0);
      issue(32'h7e208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgt_vv_sew32_023");
    end
  endtask

  task automatic test_vmsgtu_vv_sew8_000;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h7a208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgtu_vv_sew8_000");
    end
  endtask

  task automatic test_vmsgtu_vv_sew8_001;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h7a208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgtu_vv_sew8_001");
    end
  endtask

  task automatic test_vmsgtu_vv_sew8_002;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h2));
      vrf_write(5'd0, 64'h0);
      issue(32'h7a208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgtu_vv_sew8_002");
    end
  endtask

  task automatic test_vmsgtu_vv_sew8_003;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h2));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h7a208057); wait_done(100);
      n = VLEN/8; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgtu_vv_sew8_003");
    end
  endtask

  task automatic test_vmsgtu_vv_sew8_004;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h80));
      vrf_write(5'd0, 64'h0);
      issue(32'h7a208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgtu_vv_sew8_004");
    end
  endtask

  task automatic test_vmsgtu_vv_sew8_005;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      vrf_write(5'd0, 64'h0);
      issue(32'h7a208057); wait_done(100);
      n = VLEN/8; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgtu_vv_sew8_005");
    end
  endtask

  task automatic test_vmsgtu_vv_sew8_006;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h7a208057); wait_done(100);
      n = VLEN/8; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgtu_vv_sew8_006");
    end
  endtask

  task automatic test_vmsgtu_vv_sew8_007;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'hff));
      vrf_write(5'd0, 64'h0);
      issue(32'h7a208057); wait_done(100);
      n = VLEN/8; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgtu_vv_sew8_007");
    end
  endtask

  task automatic test_vmsgtu_vv_sew16_008;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h7a208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgtu_vv_sew16_008");
    end
  endtask

  task automatic test_vmsgtu_vv_sew16_009;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h7a208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgtu_vv_sew16_009");
    end
  endtask

  task automatic test_vmsgtu_vv_sew16_010;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h2));
      vrf_write(5'd0, 64'h0);
      issue(32'h7a208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgtu_vv_sew16_010");
    end
  endtask

  task automatic test_vmsgtu_vv_sew16_011;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h2));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h7a208057); wait_done(100);
      n = VLEN/16; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgtu_vv_sew16_011");
    end
  endtask

  task automatic test_vmsgtu_vv_sew16_012;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h80));
      vrf_write(5'd0, 64'h0);
      issue(32'h7a208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgtu_vv_sew16_012");
    end
  endtask

  task automatic test_vmsgtu_vv_sew16_013;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      vrf_write(5'd0, 64'h0);
      issue(32'h7a208057); wait_done(100);
      n = VLEN/16; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgtu_vv_sew16_013");
    end
  endtask

  task automatic test_vmsgtu_vv_sew16_014;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h7a208057); wait_done(100);
      n = VLEN/16; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgtu_vv_sew16_014");
    end
  endtask

  task automatic test_vmsgtu_vv_sew16_015;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'hff));
      vrf_write(5'd0, 64'h0);
      issue(32'h7a208057); wait_done(100);
      n = VLEN/16; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgtu_vv_sew16_015");
    end
  endtask

  task automatic test_vmsgtu_vv_sew32_016;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h7a208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgtu_vv_sew32_016");
    end
  endtask

  task automatic test_vmsgtu_vv_sew32_017;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h7a208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgtu_vv_sew32_017");
    end
  endtask

  task automatic test_vmsgtu_vv_sew32_018;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h2));
      vrf_write(5'd0, 64'h0);
      issue(32'h7a208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgtu_vv_sew32_018");
    end
  endtask

  task automatic test_vmsgtu_vv_sew32_019;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h2));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      vrf_write(5'd0, 64'h0);
      issue(32'h7a208057); wait_done(100);
      n = VLEN/32; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgtu_vv_sew32_019");
    end
  endtask

  task automatic test_vmsgtu_vv_sew32_020;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h80));
      vrf_write(5'd0, 64'h0);
      issue(32'h7a208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgtu_vv_sew32_020");
    end
  endtask

  task automatic test_vmsgtu_vv_sew32_021;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      vrf_write(5'd0, 64'h0);
      issue(32'h7a208057); wait_done(100);
      n = VLEN/32; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgtu_vv_sew32_021");
    end
  endtask

  task automatic test_vmsgtu_vv_sew32_022;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd0, 64'h0);
      issue(32'h7a208057); wait_done(100);
      n = VLEN/32; exp_mask = 1 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgtu_vv_sew32_022");
    end
  endtask

  task automatic test_vmsgtu_vv_sew32_023;
    automatic int n; automatic logic [DLEN-1:0] exp_mask;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'hff));
      vrf_write(5'd0, 64'h0);
      issue(32'h7a208057); wait_done(100);
      n = VLEN/32; exp_mask = 0 ? ((1<<n)-1) : 0;
      check_vrf_mask(5'd0, exp_mask, "test_vmsgtu_vv_sew32_023");
    end
  endtask


  task automatic run_cmp_tests;
    begin
      $display("=== CMP TESTS (192) ===");
      test_vmseq_vv_sew8_000();
      test_vmseq_vv_sew8_001();
      test_vmseq_vv_sew8_002();
      test_vmseq_vv_sew8_003();
      test_vmseq_vv_sew8_004();
      test_vmseq_vv_sew8_005();
      test_vmseq_vv_sew8_006();
      test_vmseq_vv_sew8_007();
      test_vmseq_vv_sew16_008();
      test_vmseq_vv_sew16_009();
      test_vmseq_vv_sew16_010();
      test_vmseq_vv_sew16_011();
      test_vmseq_vv_sew16_012();
      test_vmseq_vv_sew16_013();
      test_vmseq_vv_sew16_014();
      test_vmseq_vv_sew16_015();
      test_vmseq_vv_sew32_016();
      test_vmseq_vv_sew32_017();
      test_vmseq_vv_sew32_018();
      test_vmseq_vv_sew32_019();
      test_vmseq_vv_sew32_020();
      test_vmseq_vv_sew32_021();
      test_vmseq_vv_sew32_022();
      test_vmseq_vv_sew32_023();
      test_vmsne_vv_sew8_000();
      test_vmsne_vv_sew8_001();
      test_vmsne_vv_sew8_002();
      test_vmsne_vv_sew8_003();
      test_vmsne_vv_sew8_004();
      test_vmsne_vv_sew8_005();
      test_vmsne_vv_sew8_006();
      test_vmsne_vv_sew8_007();
      test_vmsne_vv_sew16_008();
      test_vmsne_vv_sew16_009();
      test_vmsne_vv_sew16_010();
      test_vmsne_vv_sew16_011();
      test_vmsne_vv_sew16_012();
      test_vmsne_vv_sew16_013();
      test_vmsne_vv_sew16_014();
      test_vmsne_vv_sew16_015();
      test_vmsne_vv_sew32_016();
      test_vmsne_vv_sew32_017();
      test_vmsne_vv_sew32_018();
      test_vmsne_vv_sew32_019();
      test_vmsne_vv_sew32_020();
      test_vmsne_vv_sew32_021();
      test_vmsne_vv_sew32_022();
      test_vmsne_vv_sew32_023();
      test_vmslt_vv_sew8_000();
      test_vmslt_vv_sew8_001();
      test_vmslt_vv_sew8_002();
      test_vmslt_vv_sew8_003();
      test_vmslt_vv_sew8_004();
      test_vmslt_vv_sew8_005();
      test_vmslt_vv_sew8_006();
      test_vmslt_vv_sew8_007();
      test_vmslt_vv_sew16_008();
      test_vmslt_vv_sew16_009();
      test_vmslt_vv_sew16_010();
      test_vmslt_vv_sew16_011();
      test_vmslt_vv_sew16_012();
      test_vmslt_vv_sew16_013();
      test_vmslt_vv_sew16_014();
      test_vmslt_vv_sew16_015();
      test_vmslt_vv_sew32_016();
      test_vmslt_vv_sew32_017();
      test_vmslt_vv_sew32_018();
      test_vmslt_vv_sew32_019();
      test_vmslt_vv_sew32_020();
      test_vmslt_vv_sew32_021();
      test_vmslt_vv_sew32_022();
      test_vmslt_vv_sew32_023();
      test_vmsltu_vv_sew8_000();
      test_vmsltu_vv_sew8_001();
      test_vmsltu_vv_sew8_002();
      test_vmsltu_vv_sew8_003();
      test_vmsltu_vv_sew8_004();
      test_vmsltu_vv_sew8_005();
      test_vmsltu_vv_sew8_006();
      test_vmsltu_vv_sew8_007();
      test_vmsltu_vv_sew16_008();
      test_vmsltu_vv_sew16_009();
      test_vmsltu_vv_sew16_010();
      test_vmsltu_vv_sew16_011();
      test_vmsltu_vv_sew16_012();
      test_vmsltu_vv_sew16_013();
      test_vmsltu_vv_sew16_014();
      test_vmsltu_vv_sew16_015();
      test_vmsltu_vv_sew32_016();
      test_vmsltu_vv_sew32_017();
      test_vmsltu_vv_sew32_018();
      test_vmsltu_vv_sew32_019();
      test_vmsltu_vv_sew32_020();
      test_vmsltu_vv_sew32_021();
      test_vmsltu_vv_sew32_022();
      test_vmsltu_vv_sew32_023();
      test_vmsle_vv_sew8_000();
      test_vmsle_vv_sew8_001();
      test_vmsle_vv_sew8_002();
      test_vmsle_vv_sew8_003();
      test_vmsle_vv_sew8_004();
      test_vmsle_vv_sew8_005();
      test_vmsle_vv_sew8_006();
      test_vmsle_vv_sew8_007();
      test_vmsle_vv_sew16_008();
      test_vmsle_vv_sew16_009();
      test_vmsle_vv_sew16_010();
      test_vmsle_vv_sew16_011();
      test_vmsle_vv_sew16_012();
      test_vmsle_vv_sew16_013();
      test_vmsle_vv_sew16_014();
      test_vmsle_vv_sew16_015();
      test_vmsle_vv_sew32_016();
      test_vmsle_vv_sew32_017();
      test_vmsle_vv_sew32_018();
      test_vmsle_vv_sew32_019();
      test_vmsle_vv_sew32_020();
      test_vmsle_vv_sew32_021();
      test_vmsle_vv_sew32_022();
      test_vmsle_vv_sew32_023();
      test_vmsleu_vv_sew8_000();
      test_vmsleu_vv_sew8_001();
      test_vmsleu_vv_sew8_002();
      test_vmsleu_vv_sew8_003();
      test_vmsleu_vv_sew8_004();
      test_vmsleu_vv_sew8_005();
      test_vmsleu_vv_sew8_006();
      test_vmsleu_vv_sew8_007();
      test_vmsleu_vv_sew16_008();
      test_vmsleu_vv_sew16_009();
      test_vmsleu_vv_sew16_010();
      test_vmsleu_vv_sew16_011();
      test_vmsleu_vv_sew16_012();
      test_vmsleu_vv_sew16_013();
      test_vmsleu_vv_sew16_014();
      test_vmsleu_vv_sew16_015();
      test_vmsleu_vv_sew32_016();
      test_vmsleu_vv_sew32_017();
      test_vmsleu_vv_sew32_018();
      test_vmsleu_vv_sew32_019();
      test_vmsleu_vv_sew32_020();
      test_vmsleu_vv_sew32_021();
      test_vmsleu_vv_sew32_022();
      test_vmsleu_vv_sew32_023();
      test_vmsgt_vv_sew8_000();
      test_vmsgt_vv_sew8_001();
      test_vmsgt_vv_sew8_002();
      test_vmsgt_vv_sew8_003();
      test_vmsgt_vv_sew8_004();
      test_vmsgt_vv_sew8_005();
      test_vmsgt_vv_sew8_006();
      test_vmsgt_vv_sew8_007();
      test_vmsgt_vv_sew16_008();
      test_vmsgt_vv_sew16_009();
      test_vmsgt_vv_sew16_010();
      test_vmsgt_vv_sew16_011();
      test_vmsgt_vv_sew16_012();
      test_vmsgt_vv_sew16_013();
      test_vmsgt_vv_sew16_014();
      test_vmsgt_vv_sew16_015();
      test_vmsgt_vv_sew32_016();
      test_vmsgt_vv_sew32_017();
      test_vmsgt_vv_sew32_018();
      test_vmsgt_vv_sew32_019();
      test_vmsgt_vv_sew32_020();
      test_vmsgt_vv_sew32_021();
      test_vmsgt_vv_sew32_022();
      test_vmsgt_vv_sew32_023();
      test_vmsgtu_vv_sew8_000();
      test_vmsgtu_vv_sew8_001();
      test_vmsgtu_vv_sew8_002();
      test_vmsgtu_vv_sew8_003();
      test_vmsgtu_vv_sew8_004();
      test_vmsgtu_vv_sew8_005();
      test_vmsgtu_vv_sew8_006();
      test_vmsgtu_vv_sew8_007();
      test_vmsgtu_vv_sew16_008();
      test_vmsgtu_vv_sew16_009();
      test_vmsgtu_vv_sew16_010();
      test_vmsgtu_vv_sew16_011();
      test_vmsgtu_vv_sew16_012();
      test_vmsgtu_vv_sew16_013();
      test_vmsgtu_vv_sew16_014();
      test_vmsgtu_vv_sew16_015();
      test_vmsgtu_vv_sew32_016();
      test_vmsgtu_vv_sew32_017();
      test_vmsgtu_vv_sew32_018();
      test_vmsgtu_vv_sew32_019();
      test_vmsgtu_vv_sew32_020();
      test_vmsgtu_vv_sew32_021();
      test_vmsgtu_vv_sew32_022();
      test_vmsgtu_vv_sew32_023();
      $display("CMP: 192 tests done");
    end
  endtask
