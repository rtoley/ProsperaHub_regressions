// VPU v0.3c - SAT Tests (60 tests)

  task automatic test_vsaddu_vv_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h822081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h80,"test_vsaddu_vv_sew8_000");
    end
  endtask

  task automatic test_vsaddu_vv_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h822081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hff,"test_vsaddu_vv_sew8_001");
    end
  endtask

  task automatic test_vsaddu_vv_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h822081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h81,"test_vsaddu_vv_sew8_002");
    end
  endtask

  task automatic test_vsaddu_vv_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h822081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h1,"test_vsaddu_vv_sew8_003");
    end
  endtask

  task automatic test_vsaddu_vv_sew8_004;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      issue(32'h822081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hfe,"test_vsaddu_vv_sew8_004");
    end
  endtask

  task automatic test_vsaddu_vv_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h822081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h80,"test_vsaddu_vv_sew16_005");
    end
  endtask

  task automatic test_vsaddu_vv_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h822081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h100,"test_vsaddu_vv_sew16_006");
    end
  endtask

  task automatic test_vsaddu_vv_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h822081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h81,"test_vsaddu_vv_sew16_007");
    end
  endtask

  task automatic test_vsaddu_vv_sew16_008;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h822081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h1,"test_vsaddu_vv_sew16_008");
    end
  endtask

  task automatic test_vsaddu_vv_sew16_009;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      issue(32'h822081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hfe,"test_vsaddu_vv_sew16_009");
    end
  endtask

  task automatic test_vsaddu_vv_sew32_010;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h822081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h80,"test_vsaddu_vv_sew32_010");
    end
  endtask

  task automatic test_vsaddu_vv_sew32_011;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h822081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h100,"test_vsaddu_vv_sew32_011");
    end
  endtask

  task automatic test_vsaddu_vv_sew32_012;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h822081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h81,"test_vsaddu_vv_sew32_012");
    end
  endtask

  task automatic test_vsaddu_vv_sew32_013;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h822081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h1,"test_vsaddu_vv_sew32_013");
    end
  endtask

  task automatic test_vsaddu_vv_sew32_014;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      issue(32'h822081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hfe,"test_vsaddu_vv_sew32_014");
    end
  endtask

  task automatic test_vsadd_vv_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h862081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h7f,"test_vsadd_vv_sew8_000");
    end
  endtask

  task automatic test_vsadd_vv_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h862081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vsadd_vv_sew8_001");
    end
  endtask

  task automatic test_vsadd_vv_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h862081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h81,"test_vsadd_vv_sew8_002");
    end
  endtask

  task automatic test_vsadd_vv_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h862081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h1,"test_vsadd_vv_sew8_003");
    end
  endtask

  task automatic test_vsadd_vv_sew8_004;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      issue(32'h862081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h7f,"test_vsadd_vv_sew8_004");
    end
  endtask

  task automatic test_vsadd_vv_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h862081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h80,"test_vsadd_vv_sew16_005");
    end
  endtask

  task automatic test_vsadd_vv_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h862081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h100,"test_vsadd_vv_sew16_006");
    end
  endtask

  task automatic test_vsadd_vv_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h862081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h81,"test_vsadd_vv_sew16_007");
    end
  endtask

  task automatic test_vsadd_vv_sew16_008;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h862081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h1,"test_vsadd_vv_sew16_008");
    end
  endtask

  task automatic test_vsadd_vv_sew16_009;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      issue(32'h862081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hfe,"test_vsadd_vv_sew16_009");
    end
  endtask

  task automatic test_vsadd_vv_sew32_010;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h862081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h80,"test_vsadd_vv_sew32_010");
    end
  endtask

  task automatic test_vsadd_vv_sew32_011;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h862081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h100,"test_vsadd_vv_sew32_011");
    end
  endtask

  task automatic test_vsadd_vv_sew32_012;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h862081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h81,"test_vsadd_vv_sew32_012");
    end
  endtask

  task automatic test_vsadd_vv_sew32_013;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h862081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h1,"test_vsadd_vv_sew32_013");
    end
  endtask

  task automatic test_vsadd_vv_sew32_014;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      issue(32'h862081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hfe,"test_vsadd_vv_sew32_014");
    end
  endtask

  task automatic test_vssubu_vv_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h8a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h7e,"test_vssubu_vv_sew8_000");
    end
  endtask

  task automatic test_vssubu_vv_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h8a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hfe,"test_vssubu_vv_sew8_001");
    end
  endtask

  task automatic test_vssubu_vv_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h8a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h7f,"test_vssubu_vv_sew8_002");
    end
  endtask

  task automatic test_vssubu_vv_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h8a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vssubu_vv_sew8_003");
    end
  endtask

  task automatic test_vssubu_vv_sew8_004;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      issue(32'h8a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vssubu_vv_sew8_004");
    end
  endtask

  task automatic test_vssubu_vv_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h8a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h7e,"test_vssubu_vv_sew16_005");
    end
  endtask

  task automatic test_vssubu_vv_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h8a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hfe,"test_vssubu_vv_sew16_006");
    end
  endtask

  task automatic test_vssubu_vv_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h8a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h7f,"test_vssubu_vv_sew16_007");
    end
  endtask

  task automatic test_vssubu_vv_sew16_008;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h8a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vssubu_vv_sew16_008");
    end
  endtask

  task automatic test_vssubu_vv_sew16_009;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      issue(32'h8a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vssubu_vv_sew16_009");
    end
  endtask

  task automatic test_vssubu_vv_sew32_010;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h8a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h7e,"test_vssubu_vv_sew32_010");
    end
  endtask

  task automatic test_vssubu_vv_sew32_011;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h8a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hfe,"test_vssubu_vv_sew32_011");
    end
  endtask

  task automatic test_vssubu_vv_sew32_012;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h8a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h7f,"test_vssubu_vv_sew32_012");
    end
  endtask

  task automatic test_vssubu_vv_sew32_013;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h8a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vssubu_vv_sew32_013");
    end
  endtask

  task automatic test_vssubu_vv_sew32_014;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      issue(32'h8a2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vssubu_vv_sew32_014");
    end
  endtask

  task automatic test_vssub_vv_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h8e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h7e,"test_vssub_vv_sew8_000");
    end
  endtask

  task automatic test_vssub_vv_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h8e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hfe,"test_vssub_vv_sew8_001");
    end
  endtask

  task automatic test_vssub_vv_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h80));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h8e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h80,"test_vssub_vv_sew8_002");
    end
  endtask

  task automatic test_vssub_vv_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h0));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'h8e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hff,"test_vssub_vv_sew8_003");
    end
  endtask

  task automatic test_vssub_vv_sew8_004;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN,8'h7f));
      vrf_write(5'd1, replicate_8(DLEN,8'h7f));
      issue(32'h8e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h0,"test_vssub_vv_sew8_004");
    end
  endtask

  task automatic test_vssub_vv_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h8e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h7e,"test_vssub_vv_sew16_005");
    end
  endtask

  task automatic test_vssub_vv_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h8e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hfe,"test_vssub_vv_sew16_006");
    end
  endtask

  task automatic test_vssub_vv_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h80));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h8e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h7f,"test_vssub_vv_sew16_007");
    end
  endtask

  task automatic test_vssub_vv_sew16_008;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h0));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'h8e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hffff,"test_vssub_vv_sew16_008");
    end
  endtask

  task automatic test_vssub_vv_sew16_009;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN,16'h7f));
      vrf_write(5'd1, replicate_16(DLEN,16'h7f));
      issue(32'h8e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h0,"test_vssub_vv_sew16_009");
    end
  endtask

  task automatic test_vssub_vv_sew32_010;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h8e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h7e,"test_vssub_vv_sew32_010");
    end
  endtask

  task automatic test_vssub_vv_sew32_011;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h8e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hfe,"test_vssub_vv_sew32_011");
    end
  endtask

  task automatic test_vssub_vv_sew32_012;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h80));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h8e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h7f,"test_vssub_vv_sew32_012");
    end
  endtask

  task automatic test_vssub_vv_sew32_013;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h0));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'h8e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hffffffff,"test_vssub_vv_sew32_013");
    end
  endtask

  task automatic test_vssub_vv_sew32_014;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd2, replicate_32(DLEN,32'h7f));
      vrf_write(5'd1, replicate_32(DLEN,32'h7f));
      issue(32'h8e2081d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h0,"test_vssub_vv_sew32_014");
    end
  endtask


  task automatic run_sat_tests;
    begin
      $display("=== SAT TESTS (60) ===");
      test_vsaddu_vv_sew8_000();
      test_vsaddu_vv_sew8_001();
      test_vsaddu_vv_sew8_002();
      test_vsaddu_vv_sew8_003();
      test_vsaddu_vv_sew8_004();
      test_vsaddu_vv_sew16_005();
      test_vsaddu_vv_sew16_006();
      test_vsaddu_vv_sew16_007();
      test_vsaddu_vv_sew16_008();
      test_vsaddu_vv_sew16_009();
      test_vsaddu_vv_sew32_010();
      test_vsaddu_vv_sew32_011();
      test_vsaddu_vv_sew32_012();
      test_vsaddu_vv_sew32_013();
      test_vsaddu_vv_sew32_014();
      test_vsadd_vv_sew8_000();
      test_vsadd_vv_sew8_001();
      test_vsadd_vv_sew8_002();
      test_vsadd_vv_sew8_003();
      test_vsadd_vv_sew8_004();
      test_vsadd_vv_sew16_005();
      test_vsadd_vv_sew16_006();
      test_vsadd_vv_sew16_007();
      test_vsadd_vv_sew16_008();
      test_vsadd_vv_sew16_009();
      test_vsadd_vv_sew32_010();
      test_vsadd_vv_sew32_011();
      test_vsadd_vv_sew32_012();
      test_vsadd_vv_sew32_013();
      test_vsadd_vv_sew32_014();
      test_vssubu_vv_sew8_000();
      test_vssubu_vv_sew8_001();
      test_vssubu_vv_sew8_002();
      test_vssubu_vv_sew8_003();
      test_vssubu_vv_sew8_004();
      test_vssubu_vv_sew16_005();
      test_vssubu_vv_sew16_006();
      test_vssubu_vv_sew16_007();
      test_vssubu_vv_sew16_008();
      test_vssubu_vv_sew16_009();
      test_vssubu_vv_sew32_010();
      test_vssubu_vv_sew32_011();
      test_vssubu_vv_sew32_012();
      test_vssubu_vv_sew32_013();
      test_vssubu_vv_sew32_014();
      test_vssub_vv_sew8_000();
      test_vssub_vv_sew8_001();
      test_vssub_vv_sew8_002();
      test_vssub_vv_sew8_003();
      test_vssub_vv_sew8_004();
      test_vssub_vv_sew16_005();
      test_vssub_vv_sew16_006();
      test_vssub_vv_sew16_007();
      test_vssub_vv_sew16_008();
      test_vssub_vv_sew16_009();
      test_vssub_vv_sew32_010();
      test_vssub_vv_sew32_011();
      test_vssub_vv_sew32_012();
      test_vssub_vv_sew32_013();
      test_vssub_vv_sew32_014();
      $display("SAT: 60 tests done");
    end
  endtask
