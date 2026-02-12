// VPU v0.3c - MAC Tests (36 tests)

  task automatic test_vmacc_vv_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd3, replicate_8(DLEN,8'h10));
      vrf_write(5'd2, replicate_8(DLEN,8'h2));
      vrf_write(5'd1, replicate_8(DLEN,8'h3));
      issue(32'hb620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h16,"test_vmacc_vv_sew8_000");
    end
  endtask

  task automatic test_vmacc_vv_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd3, replicate_8(DLEN,8'h0));
      vrf_write(5'd2, replicate_8(DLEN,8'h10));
      vrf_write(5'd1, replicate_8(DLEN,8'h2));
      issue(32'hb620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h20,"test_vmacc_vv_sew8_001");
    end
  endtask

  task automatic test_vmacc_vv_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd3, replicate_8(DLEN,8'h50));
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'hb620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h4f,"test_vmacc_vv_sew8_002");
    end
  endtask

  task automatic test_vmacc_vv_sew16_003;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd3, replicate_16(DLEN,16'h10));
      vrf_write(5'd2, replicate_16(DLEN,16'h2));
      vrf_write(5'd1, replicate_16(DLEN,16'h3));
      issue(32'hb620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h16,"test_vmacc_vv_sew16_003");
    end
  endtask

  task automatic test_vmacc_vv_sew16_004;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd3, replicate_16(DLEN,16'h0));
      vrf_write(5'd2, replicate_16(DLEN,16'h10));
      vrf_write(5'd1, replicate_16(DLEN,16'h2));
      issue(32'hb620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h20,"test_vmacc_vv_sew16_004");
    end
  endtask

  task automatic test_vmacc_vv_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd3, replicate_16(DLEN,16'h50));
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'hb620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h14f,"test_vmacc_vv_sew16_005");
    end
  endtask

  task automatic test_vmacc_vv_sew32_006;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd3, replicate_32(DLEN,32'h10));
      vrf_write(5'd2, replicate_32(DLEN,32'h2));
      vrf_write(5'd1, replicate_32(DLEN,32'h3));
      issue(32'hb620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h16,"test_vmacc_vv_sew32_006");
    end
  endtask

  task automatic test_vmacc_vv_sew32_007;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd3, replicate_32(DLEN,32'h0));
      vrf_write(5'd2, replicate_32(DLEN,32'h10));
      vrf_write(5'd1, replicate_32(DLEN,32'h2));
      issue(32'hb620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h20,"test_vmacc_vv_sew32_007");
    end
  endtask

  task automatic test_vmacc_vv_sew32_008;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd3, replicate_32(DLEN,32'h50));
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'hb620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h14f,"test_vmacc_vv_sew32_008");
    end
  endtask

  task automatic test_vnmsac_vv_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd3, replicate_8(DLEN,8'h10));
      vrf_write(5'd2, replicate_8(DLEN,8'h2));
      vrf_write(5'd1, replicate_8(DLEN,8'h3));
      issue(32'hbe20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'ha,"test_vnmsac_vv_sew8_000");
    end
  endtask

  task automatic test_vnmsac_vv_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd3, replicate_8(DLEN,8'h0));
      vrf_write(5'd2, replicate_8(DLEN,8'h10));
      vrf_write(5'd1, replicate_8(DLEN,8'h2));
      issue(32'hbe20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'he0,"test_vnmsac_vv_sew8_001");
    end
  endtask

  task automatic test_vnmsac_vv_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd3, replicate_8(DLEN,8'h50));
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'hbe20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h51,"test_vnmsac_vv_sew8_002");
    end
  endtask

  task automatic test_vnmsac_vv_sew16_003;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd3, replicate_16(DLEN,16'h10));
      vrf_write(5'd2, replicate_16(DLEN,16'h2));
      vrf_write(5'd1, replicate_16(DLEN,16'h3));
      issue(32'hbe20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'ha,"test_vnmsac_vv_sew16_003");
    end
  endtask

  task automatic test_vnmsac_vv_sew16_004;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd3, replicate_16(DLEN,16'h0));
      vrf_write(5'd2, replicate_16(DLEN,16'h10));
      vrf_write(5'd1, replicate_16(DLEN,16'h2));
      issue(32'hbe20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hffe0,"test_vnmsac_vv_sew16_004");
    end
  endtask

  task automatic test_vnmsac_vv_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd3, replicate_16(DLEN,16'h50));
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'hbe20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hff51,"test_vnmsac_vv_sew16_005");
    end
  endtask

  task automatic test_vnmsac_vv_sew32_006;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd3, replicate_32(DLEN,32'h10));
      vrf_write(5'd2, replicate_32(DLEN,32'h2));
      vrf_write(5'd1, replicate_32(DLEN,32'h3));
      issue(32'hbe20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'ha,"test_vnmsac_vv_sew32_006");
    end
  endtask

  task automatic test_vnmsac_vv_sew32_007;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd3, replicate_32(DLEN,32'h0));
      vrf_write(5'd2, replicate_32(DLEN,32'h10));
      vrf_write(5'd1, replicate_32(DLEN,32'h2));
      issue(32'hbe20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hffffffe0,"test_vnmsac_vv_sew32_007");
    end
  endtask

  task automatic test_vnmsac_vv_sew32_008;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd3, replicate_32(DLEN,32'h50));
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'hbe20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hffffff51,"test_vnmsac_vv_sew32_008");
    end
  endtask

  task automatic test_vmadd_vv_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd3, replicate_8(DLEN,8'h10));
      vrf_write(5'd2, replicate_8(DLEN,8'h2));
      vrf_write(5'd1, replicate_8(DLEN,8'h3));
      issue(32'ha620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h32,"test_vmadd_vv_sew8_000");
    end
  endtask

  task automatic test_vmadd_vv_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd3, replicate_8(DLEN,8'h0));
      vrf_write(5'd2, replicate_8(DLEN,8'h10));
      vrf_write(5'd1, replicate_8(DLEN,8'h2));
      issue(32'ha620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h10,"test_vmadd_vv_sew8_001");
    end
  endtask

  task automatic test_vmadd_vv_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd3, replicate_8(DLEN,8'h50));
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'ha620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h4f,"test_vmadd_vv_sew8_002");
    end
  endtask

  task automatic test_vmadd_vv_sew16_003;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd3, replicate_16(DLEN,16'h10));
      vrf_write(5'd2, replicate_16(DLEN,16'h2));
      vrf_write(5'd1, replicate_16(DLEN,16'h3));
      issue(32'ha620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h32,"test_vmadd_vv_sew16_003");
    end
  endtask

  task automatic test_vmadd_vv_sew16_004;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd3, replicate_16(DLEN,16'h0));
      vrf_write(5'd2, replicate_16(DLEN,16'h10));
      vrf_write(5'd1, replicate_16(DLEN,16'h2));
      issue(32'ha620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h10,"test_vmadd_vv_sew16_004");
    end
  endtask

  task automatic test_vmadd_vv_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd3, replicate_16(DLEN,16'h50));
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'ha620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h14f,"test_vmadd_vv_sew16_005");
    end
  endtask

  task automatic test_vmadd_vv_sew32_006;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd3, replicate_32(DLEN,32'h10));
      vrf_write(5'd2, replicate_32(DLEN,32'h2));
      vrf_write(5'd1, replicate_32(DLEN,32'h3));
      issue(32'ha620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h32,"test_vmadd_vv_sew32_006");
    end
  endtask

  task automatic test_vmadd_vv_sew32_007;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd3, replicate_32(DLEN,32'h0));
      vrf_write(5'd2, replicate_32(DLEN,32'h10));
      vrf_write(5'd1, replicate_32(DLEN,32'h2));
      issue(32'ha620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h10,"test_vmadd_vv_sew32_007");
    end
  endtask

  task automatic test_vmadd_vv_sew32_008;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd3, replicate_32(DLEN,32'h50));
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'ha620a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h14f,"test_vmadd_vv_sew32_008");
    end
  endtask

  task automatic test_vnmsub_vv_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd3, replicate_8(DLEN,8'h10));
      vrf_write(5'd2, replicate_8(DLEN,8'h2));
      vrf_write(5'd1, replicate_8(DLEN,8'h3));
      issue(32'hae20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'hd2,"test_vnmsub_vv_sew8_000");
    end
  endtask

  task automatic test_vnmsub_vv_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd3, replicate_8(DLEN,8'h0));
      vrf_write(5'd2, replicate_8(DLEN,8'h10));
      vrf_write(5'd1, replicate_8(DLEN,8'h2));
      issue(32'hae20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'h10,"test_vnmsub_vv_sew8_001");
    end
  endtask

  task automatic test_vnmsub_vv_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd3, replicate_8(DLEN,8'h50));
      vrf_write(5'd2, replicate_8(DLEN,8'hff));
      vrf_write(5'd1, replicate_8(DLEN,8'h1));
      issue(32'hae20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,8,8'haf,"test_vnmsub_vv_sew8_002");
    end
  endtask

  task automatic test_vnmsub_vv_sew16_003;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd3, replicate_16(DLEN,16'h10));
      vrf_write(5'd2, replicate_16(DLEN,16'h2));
      vrf_write(5'd1, replicate_16(DLEN,16'h3));
      issue(32'hae20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'hffd2,"test_vnmsub_vv_sew16_003");
    end
  endtask

  task automatic test_vnmsub_vv_sew16_004;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd3, replicate_16(DLEN,16'h0));
      vrf_write(5'd2, replicate_16(DLEN,16'h10));
      vrf_write(5'd1, replicate_16(DLEN,16'h2));
      issue(32'hae20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'h10,"test_vnmsub_vv_sew16_004");
    end
  endtask

  task automatic test_vnmsub_vv_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd3, replicate_16(DLEN,16'h50));
      vrf_write(5'd2, replicate_16(DLEN,16'hff));
      vrf_write(5'd1, replicate_16(DLEN,16'h1));
      issue(32'hae20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,16,16'haf,"test_vnmsub_vv_sew16_005");
    end
  endtask

  task automatic test_vnmsub_vv_sew32_006;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd3, replicate_32(DLEN,32'h10));
      vrf_write(5'd2, replicate_32(DLEN,32'h2));
      vrf_write(5'd1, replicate_32(DLEN,32'h3));
      issue(32'hae20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'hffffffd2,"test_vnmsub_vv_sew32_006");
    end
  endtask

  task automatic test_vnmsub_vv_sew32_007;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd3, replicate_32(DLEN,32'h0));
      vrf_write(5'd2, replicate_32(DLEN,32'h10));
      vrf_write(5'd1, replicate_32(DLEN,32'h2));
      issue(32'hae20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'h10,"test_vnmsub_vv_sew32_007");
    end
  endtask

  task automatic test_vnmsub_vv_sew32_008;
    begin issue(32'h01007057); wait_done(100);
      vrf_write(5'd3, replicate_32(DLEN,32'h50));
      vrf_write(5'd2, replicate_32(DLEN,32'hff));
      vrf_write(5'd1, replicate_32(DLEN,32'h1));
      issue(32'hae20a1d7); wait_done(100);
      check_vrf_elem0_sew(5'd3,32,32'haf,"test_vnmsub_vv_sew32_008");
    end
  endtask


  task automatic run_mac_tests;
    begin
      $display("=== MAC TESTS (36) ===");
      test_vmacc_vv_sew8_000();
      test_vmacc_vv_sew8_001();
      test_vmacc_vv_sew8_002();
      test_vmacc_vv_sew16_003();
      test_vmacc_vv_sew16_004();
      test_vmacc_vv_sew16_005();
      test_vmacc_vv_sew32_006();
      test_vmacc_vv_sew32_007();
      test_vmacc_vv_sew32_008();
      test_vnmsac_vv_sew8_000();
      test_vnmsac_vv_sew8_001();
      test_vnmsac_vv_sew8_002();
      test_vnmsac_vv_sew16_003();
      test_vnmsac_vv_sew16_004();
      test_vnmsac_vv_sew16_005();
      test_vnmsac_vv_sew32_006();
      test_vnmsac_vv_sew32_007();
      test_vnmsac_vv_sew32_008();
      test_vmadd_vv_sew8_000();
      test_vmadd_vv_sew8_001();
      test_vmadd_vv_sew8_002();
      test_vmadd_vv_sew16_003();
      test_vmadd_vv_sew16_004();
      test_vmadd_vv_sew16_005();
      test_vmadd_vv_sew32_006();
      test_vmadd_vv_sew32_007();
      test_vmadd_vv_sew32_008();
      test_vnmsub_vv_sew8_000();
      test_vnmsub_vv_sew8_001();
      test_vnmsub_vv_sew8_002();
      test_vnmsub_vv_sew16_003();
      test_vnmsub_vv_sew16_004();
      test_vnmsub_vv_sew16_005();
      test_vnmsub_vv_sew32_006();
      test_vnmsub_vv_sew32_007();
      test_vnmsub_vv_sew32_008();
      $display("MAC: 36 tests done");
    end
  endtask
