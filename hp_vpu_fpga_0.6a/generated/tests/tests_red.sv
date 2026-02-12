// VPU v0.3c - RED Tests (120 tests)

  task automatic test_vredsum_vs_sew8_000;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0220a1d7); wait_done(100);
      n = VLEN/8; exp = ((32'h1*n)+32'h0)&255;
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredsum_vs_sew8_000");
    end
  endtask

  task automatic test_vredsum_vs_sew8_001;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0220a1d7); wait_done(100);
      n = VLEN/8; exp = ((32'hff*n)+32'h0)&255;
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredsum_vs_sew8_001");
    end
  endtask

  task automatic test_vredsum_vs_sew8_002;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h55));
      vrf_write(5'd1, replicate_8(DLEN,8'haa));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0220a1d7); wait_done(100);
      n = VLEN/8; exp = ((32'h55*n)+32'haa)&255;
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredsum_vs_sew8_002");
    end
  endtask

  task automatic test_vredsum_vs_sew8_003;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h80));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0220a1d7); wait_done(100);
      n = VLEN/8; exp = ((32'h7f*n)+32'h80)&255;
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredsum_vs_sew8_003");
    end
  endtask

  task automatic test_vredsum_vs_sew8_004;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0220a1d7); wait_done(100);
      n = VLEN/8; exp = ((32'h80*n)+32'h7f)&255;
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredsum_vs_sew8_004");
    end
  endtask

  task automatic test_vredsum_vs_sew16_005;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0220a1d7); wait_done(100);
      n = VLEN/16; exp = ((32'h1*n)+32'h0)&65535;
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredsum_vs_sew16_005");
    end
  endtask

  task automatic test_vredsum_vs_sew16_006;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0220a1d7); wait_done(100);
      n = VLEN/16; exp = ((32'hff*n)+32'h0)&65535;
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredsum_vs_sew16_006");
    end
  endtask

  task automatic test_vredsum_vs_sew16_007;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h55));
      vrf_write(5'd1, replicate_16(DLEN,16'haa));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0220a1d7); wait_done(100);
      n = VLEN/16; exp = ((32'h55*n)+32'haa)&65535;
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredsum_vs_sew16_007");
    end
  endtask

  task automatic test_vredsum_vs_sew16_008;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h80));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0220a1d7); wait_done(100);
      n = VLEN/16; exp = ((32'h7f*n)+32'h80)&65535;
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredsum_vs_sew16_008");
    end
  endtask

  task automatic test_vredsum_vs_sew16_009;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0220a1d7); wait_done(100);
      n = VLEN/16; exp = ((32'h80*n)+32'h7f)&65535;
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredsum_vs_sew16_009");
    end
  endtask

  task automatic test_vredsum_vs_sew32_010;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0220a1d7); wait_done(100);
      n = VLEN/32; exp = ((32'h1*n)+32'h0)&4294967295;
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredsum_vs_sew32_010");
    end
  endtask

  task automatic test_vredsum_vs_sew32_011;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0220a1d7); wait_done(100);
      n = VLEN/32; exp = ((32'hff*n)+32'h0)&4294967295;
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredsum_vs_sew32_011");
    end
  endtask

  task automatic test_vredsum_vs_sew32_012;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h55));
      vrf_write(5'd1, replicate_32(DLEN,32'haa));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0220a1d7); wait_done(100);
      n = VLEN/32; exp = ((32'h55*n)+32'haa)&4294967295;
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredsum_vs_sew32_012");
    end
  endtask

  task automatic test_vredsum_vs_sew32_013;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h80));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0220a1d7); wait_done(100);
      n = VLEN/32; exp = ((32'h7f*n)+32'h80)&4294967295;
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredsum_vs_sew32_013");
    end
  endtask

  task automatic test_vredsum_vs_sew32_014;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0220a1d7); wait_done(100);
      n = VLEN/32; exp = ((32'h80*n)+32'h7f)&4294967295;
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredsum_vs_sew32_014");
    end
  endtask

  task automatic test_vredand_vs_sew8_000;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0620a1d7); wait_done(100);
      n = VLEN/8; exp = 32'h0;
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredand_vs_sew8_000");
    end
  endtask

  task automatic test_vredand_vs_sew8_001;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0620a1d7); wait_done(100);
      n = VLEN/8; exp = 32'h0;
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredand_vs_sew8_001");
    end
  endtask

  task automatic test_vredand_vs_sew8_002;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h55));
      vrf_write(5'd1, replicate_8(DLEN,8'haa));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0620a1d7); wait_done(100);
      n = VLEN/8; exp = 32'h0;
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredand_vs_sew8_002");
    end
  endtask

  task automatic test_vredand_vs_sew8_003;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h80));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0620a1d7); wait_done(100);
      n = VLEN/8; exp = 32'h0;
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredand_vs_sew8_003");
    end
  endtask

  task automatic test_vredand_vs_sew8_004;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0620a1d7); wait_done(100);
      n = VLEN/8; exp = 32'h0;
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredand_vs_sew8_004");
    end
  endtask

  task automatic test_vredand_vs_sew16_005;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0620a1d7); wait_done(100);
      n = VLEN/16; exp = 32'h0;
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredand_vs_sew16_005");
    end
  endtask

  task automatic test_vredand_vs_sew16_006;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0620a1d7); wait_done(100);
      n = VLEN/16; exp = 32'h0;
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredand_vs_sew16_006");
    end
  endtask

  task automatic test_vredand_vs_sew16_007;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h55));
      vrf_write(5'd1, replicate_16(DLEN,16'haa));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0620a1d7); wait_done(100);
      n = VLEN/16; exp = 32'h0;
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredand_vs_sew16_007");
    end
  endtask

  task automatic test_vredand_vs_sew16_008;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h80));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0620a1d7); wait_done(100);
      n = VLEN/16; exp = 32'h0;
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredand_vs_sew16_008");
    end
  endtask

  task automatic test_vredand_vs_sew16_009;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0620a1d7); wait_done(100);
      n = VLEN/16; exp = 32'h0;
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredand_vs_sew16_009");
    end
  endtask

  task automatic test_vredand_vs_sew32_010;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0620a1d7); wait_done(100);
      n = VLEN/32; exp = 32'h0;
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredand_vs_sew32_010");
    end
  endtask

  task automatic test_vredand_vs_sew32_011;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0620a1d7); wait_done(100);
      n = VLEN/32; exp = 32'h0;
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredand_vs_sew32_011");
    end
  endtask

  task automatic test_vredand_vs_sew32_012;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h55));
      vrf_write(5'd1, replicate_32(DLEN,32'haa));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0620a1d7); wait_done(100);
      n = VLEN/32; exp = 32'h0;
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredand_vs_sew32_012");
    end
  endtask

  task automatic test_vredand_vs_sew32_013;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h80));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0620a1d7); wait_done(100);
      n = VLEN/32; exp = 32'h0;
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredand_vs_sew32_013");
    end
  endtask

  task automatic test_vredand_vs_sew32_014;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0620a1d7); wait_done(100);
      n = VLEN/32; exp = 32'h0;
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredand_vs_sew32_014");
    end
  endtask

  task automatic test_vredor_vs_sew8_000;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0a20a1d7); wait_done(100);
      n = VLEN/8; exp = 32'h1;
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredor_vs_sew8_000");
    end
  endtask

  task automatic test_vredor_vs_sew8_001;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0a20a1d7); wait_done(100);
      n = VLEN/8; exp = 32'hff;
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredor_vs_sew8_001");
    end
  endtask

  task automatic test_vredor_vs_sew8_002;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h55));
      vrf_write(5'd1, replicate_8(DLEN,8'haa));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0a20a1d7); wait_done(100);
      n = VLEN/8; exp = 32'hff;
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredor_vs_sew8_002");
    end
  endtask

  task automatic test_vredor_vs_sew8_003;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h80));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0a20a1d7); wait_done(100);
      n = VLEN/8; exp = 32'hff;
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredor_vs_sew8_003");
    end
  endtask

  task automatic test_vredor_vs_sew8_004;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0a20a1d7); wait_done(100);
      n = VLEN/8; exp = 32'hff;
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredor_vs_sew8_004");
    end
  endtask

  task automatic test_vredor_vs_sew16_005;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0a20a1d7); wait_done(100);
      n = VLEN/16; exp = 32'h1;
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredor_vs_sew16_005");
    end
  endtask

  task automatic test_vredor_vs_sew16_006;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0a20a1d7); wait_done(100);
      n = VLEN/16; exp = 32'hff;
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredor_vs_sew16_006");
    end
  endtask

  task automatic test_vredor_vs_sew16_007;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h55));
      vrf_write(5'd1, replicate_16(DLEN,16'haa));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0a20a1d7); wait_done(100);
      n = VLEN/16; exp = 32'hff;
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredor_vs_sew16_007");
    end
  endtask

  task automatic test_vredor_vs_sew16_008;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h80));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0a20a1d7); wait_done(100);
      n = VLEN/16; exp = 32'hff;
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredor_vs_sew16_008");
    end
  endtask

  task automatic test_vredor_vs_sew16_009;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0a20a1d7); wait_done(100);
      n = VLEN/16; exp = 32'hff;
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredor_vs_sew16_009");
    end
  endtask

  task automatic test_vredor_vs_sew32_010;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0a20a1d7); wait_done(100);
      n = VLEN/32; exp = 32'h1;
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredor_vs_sew32_010");
    end
  endtask

  task automatic test_vredor_vs_sew32_011;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0a20a1d7); wait_done(100);
      n = VLEN/32; exp = 32'hff;
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredor_vs_sew32_011");
    end
  endtask

  task automatic test_vredor_vs_sew32_012;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h55));
      vrf_write(5'd1, replicate_32(DLEN,32'haa));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0a20a1d7); wait_done(100);
      n = VLEN/32; exp = 32'hff;
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredor_vs_sew32_012");
    end
  endtask

  task automatic test_vredor_vs_sew32_013;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h80));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0a20a1d7); wait_done(100);
      n = VLEN/32; exp = 32'hff;
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredor_vs_sew32_013");
    end
  endtask

  task automatic test_vredor_vs_sew32_014;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0a20a1d7); wait_done(100);
      n = VLEN/32; exp = 32'hff;
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredor_vs_sew32_014");
    end
  endtask

  task automatic test_vredxor_vs_sew8_000;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0e20a1d7); wait_done(100);
      n = VLEN/8; exp = (((n&1)?32'h1:32'h0)^32'h0);
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredxor_vs_sew8_000");
    end
  endtask

  task automatic test_vredxor_vs_sew8_001;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0e20a1d7); wait_done(100);
      n = VLEN/8; exp = (((n&1)?32'hff:32'h0)^32'h0);
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredxor_vs_sew8_001");
    end
  endtask

  task automatic test_vredxor_vs_sew8_002;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h55));
      vrf_write(5'd1, replicate_8(DLEN,8'haa));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0e20a1d7); wait_done(100);
      n = VLEN/8; exp = (((n&1)?32'h55:32'h0)^32'haa);
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredxor_vs_sew8_002");
    end
  endtask

  task automatic test_vredxor_vs_sew8_003;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h80));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0e20a1d7); wait_done(100);
      n = VLEN/8; exp = (((n&1)?32'h7f:32'h0)^32'h80);
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredxor_vs_sew8_003");
    end
  endtask

  task automatic test_vredxor_vs_sew8_004;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0e20a1d7); wait_done(100);
      n = VLEN/8; exp = (((n&1)?32'h80:32'h0)^32'h7f);
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredxor_vs_sew8_004");
    end
  endtask

  task automatic test_vredxor_vs_sew16_005;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0e20a1d7); wait_done(100);
      n = VLEN/16; exp = (((n&1)?32'h1:32'h0)^32'h0);
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredxor_vs_sew16_005");
    end
  endtask

  task automatic test_vredxor_vs_sew16_006;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0e20a1d7); wait_done(100);
      n = VLEN/16; exp = (((n&1)?32'hff:32'h0)^32'h0);
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredxor_vs_sew16_006");
    end
  endtask

  task automatic test_vredxor_vs_sew16_007;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h55));
      vrf_write(5'd1, replicate_16(DLEN,16'haa));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0e20a1d7); wait_done(100);
      n = VLEN/16; exp = (((n&1)?32'h55:32'h0)^32'haa);
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredxor_vs_sew16_007");
    end
  endtask

  task automatic test_vredxor_vs_sew16_008;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h80));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0e20a1d7); wait_done(100);
      n = VLEN/16; exp = (((n&1)?32'h7f:32'h0)^32'h80);
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredxor_vs_sew16_008");
    end
  endtask

  task automatic test_vredxor_vs_sew16_009;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0e20a1d7); wait_done(100);
      n = VLEN/16; exp = (((n&1)?32'h80:32'h0)^32'h7f);
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredxor_vs_sew16_009");
    end
  endtask

  task automatic test_vredxor_vs_sew32_010;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0e20a1d7); wait_done(100);
      n = VLEN/32; exp = (((n&1)?32'h1:32'h0)^32'h0);
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredxor_vs_sew32_010");
    end
  endtask

  task automatic test_vredxor_vs_sew32_011;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0e20a1d7); wait_done(100);
      n = VLEN/32; exp = (((n&1)?32'hff:32'h0)^32'h0);
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredxor_vs_sew32_011");
    end
  endtask

  task automatic test_vredxor_vs_sew32_012;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h55));
      vrf_write(5'd1, replicate_32(DLEN,32'haa));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0e20a1d7); wait_done(100);
      n = VLEN/32; exp = (((n&1)?32'h55:32'h0)^32'haa);
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredxor_vs_sew32_012");
    end
  endtask

  task automatic test_vredxor_vs_sew32_013;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h80));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0e20a1d7); wait_done(100);
      n = VLEN/32; exp = (((n&1)?32'h7f:32'h0)^32'h80);
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredxor_vs_sew32_013");
    end
  endtask

  task automatic test_vredxor_vs_sew32_014;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h0e20a1d7); wait_done(100);
      n = VLEN/32; exp = (((n&1)?32'h80:32'h0)^32'h7f);
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredxor_vs_sew32_014");
    end
  endtask

  task automatic test_vredmax_vs_sew8_000;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1e20a1d7); wait_done(100);
      n = VLEN/8; exp = (($signed(8'h1)>$signed(8'h0))?32'h1:32'h0);
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredmax_vs_sew8_000");
    end
  endtask

  task automatic test_vredmax_vs_sew8_001;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1e20a1d7); wait_done(100);
      n = VLEN/8; exp = (($signed(8'hff)>$signed(8'h0))?32'hff:32'h0);
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredmax_vs_sew8_001");
    end
  endtask

  task automatic test_vredmax_vs_sew8_002;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h55));
      vrf_write(5'd1, replicate_8(DLEN,8'haa));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1e20a1d7); wait_done(100);
      n = VLEN/8; exp = (($signed(8'h55)>$signed(8'haa))?32'h55:32'haa);
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredmax_vs_sew8_002");
    end
  endtask

  task automatic test_vredmax_vs_sew8_003;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h80));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1e20a1d7); wait_done(100);
      n = VLEN/8; exp = (($signed(8'h7f)>$signed(8'h80))?32'h7f:32'h80);
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredmax_vs_sew8_003");
    end
  endtask

  task automatic test_vredmax_vs_sew8_004;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1e20a1d7); wait_done(100);
      n = VLEN/8; exp = (($signed(8'h80)>$signed(8'h7f))?32'h80:32'h7f);
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredmax_vs_sew8_004");
    end
  endtask

  task automatic test_vredmax_vs_sew16_005;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1e20a1d7); wait_done(100);
      n = VLEN/16; exp = (($signed(16'h1)>$signed(16'h0))?32'h1:32'h0);
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredmax_vs_sew16_005");
    end
  endtask

  task automatic test_vredmax_vs_sew16_006;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1e20a1d7); wait_done(100);
      n = VLEN/16; exp = (($signed(16'hff)>$signed(16'h0))?32'hff:32'h0);
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredmax_vs_sew16_006");
    end
  endtask

  task automatic test_vredmax_vs_sew16_007;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h55));
      vrf_write(5'd1, replicate_16(DLEN,16'haa));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1e20a1d7); wait_done(100);
      n = VLEN/16; exp = (($signed(16'h55)>$signed(16'haa))?32'h55:32'haa);
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredmax_vs_sew16_007");
    end
  endtask

  task automatic test_vredmax_vs_sew16_008;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h80));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1e20a1d7); wait_done(100);
      n = VLEN/16; exp = (($signed(16'h7f)>$signed(16'h80))?32'h7f:32'h80);
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredmax_vs_sew16_008");
    end
  endtask

  task automatic test_vredmax_vs_sew16_009;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1e20a1d7); wait_done(100);
      n = VLEN/16; exp = (($signed(16'h80)>$signed(16'h7f))?32'h80:32'h7f);
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredmax_vs_sew16_009");
    end
  endtask

  task automatic test_vredmax_vs_sew32_010;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1e20a1d7); wait_done(100);
      n = VLEN/32; exp = (($signed(32'h1)>$signed(32'h0))?32'h1:32'h0);
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredmax_vs_sew32_010");
    end
  endtask

  task automatic test_vredmax_vs_sew32_011;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1e20a1d7); wait_done(100);
      n = VLEN/32; exp = (($signed(32'hff)>$signed(32'h0))?32'hff:32'h0);
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredmax_vs_sew32_011");
    end
  endtask

  task automatic test_vredmax_vs_sew32_012;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h55));
      vrf_write(5'd1, replicate_32(DLEN,32'haa));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1e20a1d7); wait_done(100);
      n = VLEN/32; exp = (($signed(32'h55)>$signed(32'haa))?32'h55:32'haa);
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredmax_vs_sew32_012");
    end
  endtask

  task automatic test_vredmax_vs_sew32_013;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h80));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1e20a1d7); wait_done(100);
      n = VLEN/32; exp = (($signed(32'h7f)>$signed(32'h80))?32'h7f:32'h80);
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredmax_vs_sew32_013");
    end
  endtask

  task automatic test_vredmax_vs_sew32_014;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1e20a1d7); wait_done(100);
      n = VLEN/32; exp = (($signed(32'h80)>$signed(32'h7f))?32'h80:32'h7f);
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredmax_vs_sew32_014");
    end
  endtask

  task automatic test_vredmin_vs_sew8_000;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1620a1d7); wait_done(100);
      n = VLEN/8; exp = (($signed(8'h1)<$signed(8'h0))?32'h1:32'h0);
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredmin_vs_sew8_000");
    end
  endtask

  task automatic test_vredmin_vs_sew8_001;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1620a1d7); wait_done(100);
      n = VLEN/8; exp = (($signed(8'hff)<$signed(8'h0))?32'hff:32'h0);
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredmin_vs_sew8_001");
    end
  endtask

  task automatic test_vredmin_vs_sew8_002;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h55));
      vrf_write(5'd1, replicate_8(DLEN,8'haa));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1620a1d7); wait_done(100);
      n = VLEN/8; exp = (($signed(8'h55)<$signed(8'haa))?32'h55:32'haa);
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredmin_vs_sew8_002");
    end
  endtask

  task automatic test_vredmin_vs_sew8_003;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h80));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1620a1d7); wait_done(100);
      n = VLEN/8; exp = (($signed(8'h7f)<$signed(8'h80))?32'h7f:32'h80);
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredmin_vs_sew8_003");
    end
  endtask

  task automatic test_vredmin_vs_sew8_004;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1620a1d7); wait_done(100);
      n = VLEN/8; exp = (($signed(8'h80)<$signed(8'h7f))?32'h80:32'h7f);
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredmin_vs_sew8_004");
    end
  endtask

  task automatic test_vredmin_vs_sew16_005;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1620a1d7); wait_done(100);
      n = VLEN/16; exp = (($signed(16'h1)<$signed(16'h0))?32'h1:32'h0);
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredmin_vs_sew16_005");
    end
  endtask

  task automatic test_vredmin_vs_sew16_006;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1620a1d7); wait_done(100);
      n = VLEN/16; exp = (($signed(16'hff)<$signed(16'h0))?32'hff:32'h0);
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredmin_vs_sew16_006");
    end
  endtask

  task automatic test_vredmin_vs_sew16_007;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h55));
      vrf_write(5'd1, replicate_16(DLEN,16'haa));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1620a1d7); wait_done(100);
      n = VLEN/16; exp = (($signed(16'h55)<$signed(16'haa))?32'h55:32'haa);
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredmin_vs_sew16_007");
    end
  endtask

  task automatic test_vredmin_vs_sew16_008;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h80));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1620a1d7); wait_done(100);
      n = VLEN/16; exp = (($signed(16'h7f)<$signed(16'h80))?32'h7f:32'h80);
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredmin_vs_sew16_008");
    end
  endtask

  task automatic test_vredmin_vs_sew16_009;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1620a1d7); wait_done(100);
      n = VLEN/16; exp = (($signed(16'h80)<$signed(16'h7f))?32'h80:32'h7f);
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredmin_vs_sew16_009");
    end
  endtask

  task automatic test_vredmin_vs_sew32_010;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1620a1d7); wait_done(100);
      n = VLEN/32; exp = (($signed(32'h1)<$signed(32'h0))?32'h1:32'h0);
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredmin_vs_sew32_010");
    end
  endtask

  task automatic test_vredmin_vs_sew32_011;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1620a1d7); wait_done(100);
      n = VLEN/32; exp = (($signed(32'hff)<$signed(32'h0))?32'hff:32'h0);
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredmin_vs_sew32_011");
    end
  endtask

  task automatic test_vredmin_vs_sew32_012;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h55));
      vrf_write(5'd1, replicate_32(DLEN,32'haa));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1620a1d7); wait_done(100);
      n = VLEN/32; exp = (($signed(32'h55)<$signed(32'haa))?32'h55:32'haa);
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredmin_vs_sew32_012");
    end
  endtask

  task automatic test_vredmin_vs_sew32_013;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h80));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1620a1d7); wait_done(100);
      n = VLEN/32; exp = (($signed(32'h7f)<$signed(32'h80))?32'h7f:32'h80);
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredmin_vs_sew32_013");
    end
  endtask

  task automatic test_vredmin_vs_sew32_014;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1620a1d7); wait_done(100);
      n = VLEN/32; exp = (($signed(32'h80)<$signed(32'h7f))?32'h80:32'h7f);
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredmin_vs_sew32_014");
    end
  endtask

  task automatic test_vredmaxu_vs_sew8_000;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1a20a1d7); wait_done(100);
      n = VLEN/8; exp = ((32'h1>32'h0)?32'h1:32'h0);
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredmaxu_vs_sew8_000");
    end
  endtask

  task automatic test_vredmaxu_vs_sew8_001;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1a20a1d7); wait_done(100);
      n = VLEN/8; exp = ((32'hff>32'h0)?32'hff:32'h0);
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredmaxu_vs_sew8_001");
    end
  endtask

  task automatic test_vredmaxu_vs_sew8_002;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h55));
      vrf_write(5'd1, replicate_8(DLEN,8'haa));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1a20a1d7); wait_done(100);
      n = VLEN/8; exp = ((32'h55>32'haa)?32'h55:32'haa);
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredmaxu_vs_sew8_002");
    end
  endtask

  task automatic test_vredmaxu_vs_sew8_003;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h80));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1a20a1d7); wait_done(100);
      n = VLEN/8; exp = ((32'h7f>32'h80)?32'h7f:32'h80);
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredmaxu_vs_sew8_003");
    end
  endtask

  task automatic test_vredmaxu_vs_sew8_004;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1a20a1d7); wait_done(100);
      n = VLEN/8; exp = ((32'h80>32'h7f)?32'h80:32'h7f);
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredmaxu_vs_sew8_004");
    end
  endtask

  task automatic test_vredmaxu_vs_sew16_005;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1a20a1d7); wait_done(100);
      n = VLEN/16; exp = ((32'h1>32'h0)?32'h1:32'h0);
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredmaxu_vs_sew16_005");
    end
  endtask

  task automatic test_vredmaxu_vs_sew16_006;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1a20a1d7); wait_done(100);
      n = VLEN/16; exp = ((32'hff>32'h0)?32'hff:32'h0);
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredmaxu_vs_sew16_006");
    end
  endtask

  task automatic test_vredmaxu_vs_sew16_007;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h55));
      vrf_write(5'd1, replicate_16(DLEN,16'haa));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1a20a1d7); wait_done(100);
      n = VLEN/16; exp = ((32'h55>32'haa)?32'h55:32'haa);
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredmaxu_vs_sew16_007");
    end
  endtask

  task automatic test_vredmaxu_vs_sew16_008;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h80));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1a20a1d7); wait_done(100);
      n = VLEN/16; exp = ((32'h7f>32'h80)?32'h7f:32'h80);
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredmaxu_vs_sew16_008");
    end
  endtask

  task automatic test_vredmaxu_vs_sew16_009;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1a20a1d7); wait_done(100);
      n = VLEN/16; exp = ((32'h80>32'h7f)?32'h80:32'h7f);
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredmaxu_vs_sew16_009");
    end
  endtask

  task automatic test_vredmaxu_vs_sew32_010;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1a20a1d7); wait_done(100);
      n = VLEN/32; exp = ((32'h1>32'h0)?32'h1:32'h0);
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredmaxu_vs_sew32_010");
    end
  endtask

  task automatic test_vredmaxu_vs_sew32_011;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1a20a1d7); wait_done(100);
      n = VLEN/32; exp = ((32'hff>32'h0)?32'hff:32'h0);
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredmaxu_vs_sew32_011");
    end
  endtask

  task automatic test_vredmaxu_vs_sew32_012;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h55));
      vrf_write(5'd1, replicate_32(DLEN,32'haa));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1a20a1d7); wait_done(100);
      n = VLEN/32; exp = ((32'h55>32'haa)?32'h55:32'haa);
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredmaxu_vs_sew32_012");
    end
  endtask

  task automatic test_vredmaxu_vs_sew32_013;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h80));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1a20a1d7); wait_done(100);
      n = VLEN/32; exp = ((32'h7f>32'h80)?32'h7f:32'h80);
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredmaxu_vs_sew32_013");
    end
  endtask

  task automatic test_vredmaxu_vs_sew32_014;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1a20a1d7); wait_done(100);
      n = VLEN/32; exp = ((32'h80>32'h7f)?32'h80:32'h7f);
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredmaxu_vs_sew32_014");
    end
  endtask

  task automatic test_vredminu_vs_sew8_000;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h1));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1220a1d7); wait_done(100);
      n = VLEN/8; exp = ((32'h1<32'h0)?32'h1:32'h0);
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredminu_vs_sew8_000");
    end
  endtask

  task automatic test_vredminu_vs_sew8_001;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1220a1d7); wait_done(100);
      n = VLEN/8; exp = ((32'hff<32'h0)?32'hff:32'h0);
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredminu_vs_sew8_001");
    end
  endtask

  task automatic test_vredminu_vs_sew8_002;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h55));
      vrf_write(5'd1, replicate_8(DLEN,8'haa));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1220a1d7); wait_done(100);
      n = VLEN/8; exp = ((32'h55<32'haa)?32'h55:32'haa);
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredminu_vs_sew8_002");
    end
  endtask

  task automatic test_vredminu_vs_sew8_003;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h80));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1220a1d7); wait_done(100);
      n = VLEN/8; exp = ((32'h7f<32'h80)?32'h7f:32'h80);
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredminu_vs_sew8_003");
    end
  endtask

  task automatic test_vredminu_vs_sew8_004;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1220a1d7); wait_done(100);
      n = VLEN/8; exp = ((32'h80<32'h7f)?32'h80:32'h7f);
      check_vrf_elem0_sew(5'd3,8,exp,"test_vredminu_vs_sew8_004");
    end
  endtask

  task automatic test_vredminu_vs_sew16_005;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h1));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1220a1d7); wait_done(100);
      n = VLEN/16; exp = ((32'h1<32'h0)?32'h1:32'h0);
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredminu_vs_sew16_005");
    end
  endtask

  task automatic test_vredminu_vs_sew16_006;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1220a1d7); wait_done(100);
      n = VLEN/16; exp = ((32'hff<32'h0)?32'hff:32'h0);
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredminu_vs_sew16_006");
    end
  endtask

  task automatic test_vredminu_vs_sew16_007;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h55));
      vrf_write(5'd1, replicate_16(DLEN,16'haa));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1220a1d7); wait_done(100);
      n = VLEN/16; exp = ((32'h55<32'haa)?32'h55:32'haa);
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredminu_vs_sew16_007");
    end
  endtask

  task automatic test_vredminu_vs_sew16_008;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h80));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1220a1d7); wait_done(100);
      n = VLEN/16; exp = ((32'h7f<32'h80)?32'h7f:32'h80);
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredminu_vs_sew16_008");
    end
  endtask

  task automatic test_vredminu_vs_sew16_009;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1220a1d7); wait_done(100);
      n = VLEN/16; exp = ((32'h80<32'h7f)?32'h80:32'h7f);
      check_vrf_elem0_sew(5'd3,16,exp,"test_vredminu_vs_sew16_009");
    end
  endtask

  task automatic test_vredminu_vs_sew32_010;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h1));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1220a1d7); wait_done(100);
      n = VLEN/32; exp = ((32'h1<32'h0)?32'h1:32'h0);
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredminu_vs_sew32_010");
    end
  endtask

  task automatic test_vredminu_vs_sew32_011;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h0));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1220a1d7); wait_done(100);
      n = VLEN/32; exp = ((32'hff<32'h0)?32'hff:32'h0);
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredminu_vs_sew32_011");
    end
  endtask

  task automatic test_vredminu_vs_sew32_012;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h55));
      vrf_write(5'd1, replicate_32(DLEN,32'haa));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1220a1d7); wait_done(100);
      n = VLEN/32; exp = ((32'h55<32'haa)?32'h55:32'haa);
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredminu_vs_sew32_012");
    end
  endtask

  task automatic test_vredminu_vs_sew32_013;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h80));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1220a1d7); wait_done(100);
      n = VLEN/32; exp = ((32'h7f<32'h80)?32'h7f:32'h80);
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredminu_vs_sew32_013");
    end
  endtask

  task automatic test_vredminu_vs_sew32_014;
    automatic int n; automatic logic [31:0] exp;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      vrf_write(5'd3, {DLEN{1'b1}});
      issue(32'h1220a1d7); wait_done(100);
      n = VLEN/32; exp = ((32'h80<32'h7f)?32'h80:32'h7f);
      check_vrf_elem0_sew(5'd3,32,exp,"test_vredminu_vs_sew32_014");
    end
  endtask


  task automatic run_red_tests;
    begin
      $display("=== RED TESTS (120) ===");
      test_vredsum_vs_sew8_000();
      test_vredsum_vs_sew8_001();
      test_vredsum_vs_sew8_002();
      test_vredsum_vs_sew8_003();
      test_vredsum_vs_sew8_004();
      test_vredsum_vs_sew16_005();
      test_vredsum_vs_sew16_006();
      test_vredsum_vs_sew16_007();
      test_vredsum_vs_sew16_008();
      test_vredsum_vs_sew16_009();
      test_vredsum_vs_sew32_010();
      test_vredsum_vs_sew32_011();
      test_vredsum_vs_sew32_012();
      test_vredsum_vs_sew32_013();
      test_vredsum_vs_sew32_014();
      test_vredand_vs_sew8_000();
      test_vredand_vs_sew8_001();
      test_vredand_vs_sew8_002();
      test_vredand_vs_sew8_003();
      test_vredand_vs_sew8_004();
      test_vredand_vs_sew16_005();
      test_vredand_vs_sew16_006();
      test_vredand_vs_sew16_007();
      test_vredand_vs_sew16_008();
      test_vredand_vs_sew16_009();
      test_vredand_vs_sew32_010();
      test_vredand_vs_sew32_011();
      test_vredand_vs_sew32_012();
      test_vredand_vs_sew32_013();
      test_vredand_vs_sew32_014();
      test_vredor_vs_sew8_000();
      test_vredor_vs_sew8_001();
      test_vredor_vs_sew8_002();
      test_vredor_vs_sew8_003();
      test_vredor_vs_sew8_004();
      test_vredor_vs_sew16_005();
      test_vredor_vs_sew16_006();
      test_vredor_vs_sew16_007();
      test_vredor_vs_sew16_008();
      test_vredor_vs_sew16_009();
      test_vredor_vs_sew32_010();
      test_vredor_vs_sew32_011();
      test_vredor_vs_sew32_012();
      test_vredor_vs_sew32_013();
      test_vredor_vs_sew32_014();
      test_vredxor_vs_sew8_000();
      test_vredxor_vs_sew8_001();
      test_vredxor_vs_sew8_002();
      test_vredxor_vs_sew8_003();
      test_vredxor_vs_sew8_004();
      test_vredxor_vs_sew16_005();
      test_vredxor_vs_sew16_006();
      test_vredxor_vs_sew16_007();
      test_vredxor_vs_sew16_008();
      test_vredxor_vs_sew16_009();
      test_vredxor_vs_sew32_010();
      test_vredxor_vs_sew32_011();
      test_vredxor_vs_sew32_012();
      test_vredxor_vs_sew32_013();
      test_vredxor_vs_sew32_014();
      test_vredmax_vs_sew8_000();
      test_vredmax_vs_sew8_001();
      test_vredmax_vs_sew8_002();
      test_vredmax_vs_sew8_003();
      test_vredmax_vs_sew8_004();
      test_vredmax_vs_sew16_005();
      test_vredmax_vs_sew16_006();
      test_vredmax_vs_sew16_007();
      test_vredmax_vs_sew16_008();
      test_vredmax_vs_sew16_009();
      test_vredmax_vs_sew32_010();
      test_vredmax_vs_sew32_011();
      test_vredmax_vs_sew32_012();
      test_vredmax_vs_sew32_013();
      test_vredmax_vs_sew32_014();
      test_vredmin_vs_sew8_000();
      test_vredmin_vs_sew8_001();
      test_vredmin_vs_sew8_002();
      test_vredmin_vs_sew8_003();
      test_vredmin_vs_sew8_004();
      test_vredmin_vs_sew16_005();
      test_vredmin_vs_sew16_006();
      test_vredmin_vs_sew16_007();
      test_vredmin_vs_sew16_008();
      test_vredmin_vs_sew16_009();
      test_vredmin_vs_sew32_010();
      test_vredmin_vs_sew32_011();
      test_vredmin_vs_sew32_012();
      test_vredmin_vs_sew32_013();
      test_vredmin_vs_sew32_014();
      test_vredmaxu_vs_sew8_000();
      test_vredmaxu_vs_sew8_001();
      test_vredmaxu_vs_sew8_002();
      test_vredmaxu_vs_sew8_003();
      test_vredmaxu_vs_sew8_004();
      test_vredmaxu_vs_sew16_005();
      test_vredmaxu_vs_sew16_006();
      test_vredmaxu_vs_sew16_007();
      test_vredmaxu_vs_sew16_008();
      test_vredmaxu_vs_sew16_009();
      test_vredmaxu_vs_sew32_010();
      test_vredmaxu_vs_sew32_011();
      test_vredmaxu_vs_sew32_012();
      test_vredmaxu_vs_sew32_013();
      test_vredmaxu_vs_sew32_014();
      test_vredminu_vs_sew8_000();
      test_vredminu_vs_sew8_001();
      test_vredminu_vs_sew8_002();
      test_vredminu_vs_sew8_003();
      test_vredminu_vs_sew8_004();
      test_vredminu_vs_sew16_005();
      test_vredminu_vs_sew16_006();
      test_vredminu_vs_sew16_007();
      test_vredminu_vs_sew16_008();
      test_vredminu_vs_sew16_009();
      test_vredminu_vs_sew32_010();
      test_vredminu_vs_sew32_011();
      test_vredminu_vs_sew32_012();
      test_vredminu_vs_sew32_013();
      test_vredminu_vs_sew32_014();
      $display("RED: 120 tests done");
    end
  endtask
