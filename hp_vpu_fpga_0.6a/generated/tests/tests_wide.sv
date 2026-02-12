// VPU v0.3c - WIDE Tests (82 tests)

  task automatic test_vwaddu_vv_sew8_000;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'h1));
      vrf_write(5'd1, replicate_8(DLEN, 8'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hc2208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'h2, "test_vwaddu_vv_sew8_000");
    end
  endtask

  task automatic test_vwaddu_vv_sew8_001;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'h7f));
      vrf_write(5'd1, replicate_8(DLEN, 8'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hc2208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'h80, "test_vwaddu_vv_sew8_001");
    end
  endtask

  task automatic test_vwaddu_vv_sew8_002;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'h80));
      vrf_write(5'd1, replicate_8(DLEN, 8'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hc2208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'h81, "test_vwaddu_vv_sew8_002");
    end
  endtask

  task automatic test_vwaddu_vv_sew8_003;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'hff));
      vrf_write(5'd1, replicate_8(DLEN, 8'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hc2208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'h100, "test_vwaddu_vv_sew8_003");
    end
  endtask

  task automatic test_vwaddu_vv_sew8_004;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'h55));
      vrf_write(5'd1, replicate_8(DLEN, 8'haa));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hc2208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'hff, "test_vwaddu_vv_sew8_004");
    end
  endtask

  task automatic test_vwaddu_vv_sew16_005;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'h1));
      vrf_write(5'd1, replicate_16(DLEN, 16'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hc2208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'h2, "test_vwaddu_vv_sew16_005");
    end
  endtask

  task automatic test_vwaddu_vv_sew16_006;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'h7f));
      vrf_write(5'd1, replicate_16(DLEN, 16'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hc2208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'h80, "test_vwaddu_vv_sew16_006");
    end
  endtask

  task automatic test_vwaddu_vv_sew16_007;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'h80));
      vrf_write(5'd1, replicate_16(DLEN, 16'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hc2208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'h81, "test_vwaddu_vv_sew16_007");
    end
  endtask

  task automatic test_vwaddu_vv_sew16_008;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'hff));
      vrf_write(5'd1, replicate_16(DLEN, 16'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hc2208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'h100, "test_vwaddu_vv_sew16_008");
    end
  endtask

  task automatic test_vwaddu_vv_sew16_009;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'h55));
      vrf_write(5'd1, replicate_16(DLEN, 16'haa));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hc2208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'hff, "test_vwaddu_vv_sew16_009");
    end
  endtask

  task automatic test_vwadd_vv_sew8_010;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'h1));
      vrf_write(5'd1, replicate_8(DLEN, 8'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hc6208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'h2, "test_vwadd_vv_sew8_010");
    end
  endtask

  task automatic test_vwadd_vv_sew8_011;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'h7f));
      vrf_write(5'd1, replicate_8(DLEN, 8'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hc6208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'h80, "test_vwadd_vv_sew8_011");
    end
  endtask

  task automatic test_vwadd_vv_sew8_012;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'h80));
      vrf_write(5'd1, replicate_8(DLEN, 8'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hc6208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'hff81, "test_vwadd_vv_sew8_012");
    end
  endtask

  task automatic test_vwadd_vv_sew8_013;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'hff));
      vrf_write(5'd1, replicate_8(DLEN, 8'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hc6208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'h0, "test_vwadd_vv_sew8_013");
    end
  endtask

  task automatic test_vwadd_vv_sew8_014;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'h55));
      vrf_write(5'd1, replicate_8(DLEN, 8'haa));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hc6208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'hffff, "test_vwadd_vv_sew8_014");
    end
  endtask

  task automatic test_vwadd_vv_sew16_015;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'h1));
      vrf_write(5'd1, replicate_16(DLEN, 16'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hc6208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'h2, "test_vwadd_vv_sew16_015");
    end
  endtask

  task automatic test_vwadd_vv_sew16_016;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'h7f));
      vrf_write(5'd1, replicate_16(DLEN, 16'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hc6208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'h80, "test_vwadd_vv_sew16_016");
    end
  endtask

  task automatic test_vwadd_vv_sew16_017;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'h80));
      vrf_write(5'd1, replicate_16(DLEN, 16'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hc6208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'h81, "test_vwadd_vv_sew16_017");
    end
  endtask

  task automatic test_vwadd_vv_sew16_018;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'hff));
      vrf_write(5'd1, replicate_16(DLEN, 16'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hc6208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'h100, "test_vwadd_vv_sew16_018");
    end
  endtask

  task automatic test_vwadd_vv_sew16_019;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'h55));
      vrf_write(5'd1, replicate_16(DLEN, 16'haa));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hc6208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'hff, "test_vwadd_vv_sew16_019");
    end
  endtask

  task automatic test_vwsubu_vv_sew8_020;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'h1));
      vrf_write(5'd1, replicate_8(DLEN, 8'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hca208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'h0, "test_vwsubu_vv_sew8_020");
    end
  endtask

  task automatic test_vwsubu_vv_sew8_021;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'h7f));
      vrf_write(5'd1, replicate_8(DLEN, 8'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hca208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'h7e, "test_vwsubu_vv_sew8_021");
    end
  endtask

  task automatic test_vwsubu_vv_sew8_022;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'h80));
      vrf_write(5'd1, replicate_8(DLEN, 8'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hca208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'h7f, "test_vwsubu_vv_sew8_022");
    end
  endtask

  task automatic test_vwsubu_vv_sew8_023;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'hff));
      vrf_write(5'd1, replicate_8(DLEN, 8'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hca208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'hfe, "test_vwsubu_vv_sew8_023");
    end
  endtask

  task automatic test_vwsubu_vv_sew8_024;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'h55));
      vrf_write(5'd1, replicate_8(DLEN, 8'haa));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hca208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'hffab, "test_vwsubu_vv_sew8_024");
    end
  endtask

  task automatic test_vwsubu_vv_sew16_025;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'h1));
      vrf_write(5'd1, replicate_16(DLEN, 16'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hca208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'h0, "test_vwsubu_vv_sew16_025");
    end
  endtask

  task automatic test_vwsubu_vv_sew16_026;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'h7f));
      vrf_write(5'd1, replicate_16(DLEN, 16'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hca208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'h7e, "test_vwsubu_vv_sew16_026");
    end
  endtask

  task automatic test_vwsubu_vv_sew16_027;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'h80));
      vrf_write(5'd1, replicate_16(DLEN, 16'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hca208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'h7f, "test_vwsubu_vv_sew16_027");
    end
  endtask

  task automatic test_vwsubu_vv_sew16_028;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'hff));
      vrf_write(5'd1, replicate_16(DLEN, 16'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hca208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'hfe, "test_vwsubu_vv_sew16_028");
    end
  endtask

  task automatic test_vwsubu_vv_sew16_029;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'h55));
      vrf_write(5'd1, replicate_16(DLEN, 16'haa));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hca208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'hffffffab, "test_vwsubu_vv_sew16_029");
    end
  endtask

  task automatic test_vwsub_vv_sew8_030;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'h1));
      vrf_write(5'd1, replicate_8(DLEN, 8'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hce208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'h0, "test_vwsub_vv_sew8_030");
    end
  endtask

  task automatic test_vwsub_vv_sew8_031;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'h7f));
      vrf_write(5'd1, replicate_8(DLEN, 8'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hce208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'h7e, "test_vwsub_vv_sew8_031");
    end
  endtask

  task automatic test_vwsub_vv_sew8_032;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'h80));
      vrf_write(5'd1, replicate_8(DLEN, 8'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hce208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'hff7f, "test_vwsub_vv_sew8_032");
    end
  endtask

  task automatic test_vwsub_vv_sew8_033;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'hff));
      vrf_write(5'd1, replicate_8(DLEN, 8'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hce208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'hfffe, "test_vwsub_vv_sew8_033");
    end
  endtask

  task automatic test_vwsub_vv_sew8_034;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'h55));
      vrf_write(5'd1, replicate_8(DLEN, 8'haa));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hce208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'hab, "test_vwsub_vv_sew8_034");
    end
  endtask

  task automatic test_vwsub_vv_sew16_035;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'h1));
      vrf_write(5'd1, replicate_16(DLEN, 16'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hce208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'h0, "test_vwsub_vv_sew16_035");
    end
  endtask

  task automatic test_vwsub_vv_sew16_036;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'h7f));
      vrf_write(5'd1, replicate_16(DLEN, 16'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hce208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'h7e, "test_vwsub_vv_sew16_036");
    end
  endtask

  task automatic test_vwsub_vv_sew16_037;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'h80));
      vrf_write(5'd1, replicate_16(DLEN, 16'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hce208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'h7f, "test_vwsub_vv_sew16_037");
    end
  endtask

  task automatic test_vwsub_vv_sew16_038;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'hff));
      vrf_write(5'd1, replicate_16(DLEN, 16'h1));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hce208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'hfe, "test_vwsub_vv_sew16_038");
    end
  endtask

  task automatic test_vwsub_vv_sew16_039;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'h55));
      vrf_write(5'd1, replicate_16(DLEN, 16'haa));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hce208257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'hffffffab, "test_vwsub_vv_sew16_039");
    end
  endtask

  task automatic test_vwmulu_vv_sew8_040;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'h2));
      vrf_write(5'd1, replicate_8(DLEN, 8'h3));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'he220a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'h6, "test_vwmulu_vv_sew8_040");
    end
  endtask

  task automatic test_vwmulu_vv_sew8_041;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'h7f));
      vrf_write(5'd1, replicate_8(DLEN, 8'h2));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'he220a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'hfe, "test_vwmulu_vv_sew8_041");
    end
  endtask

  task automatic test_vwmulu_vv_sew8_042;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'h80));
      vrf_write(5'd1, replicate_8(DLEN, 8'h2));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'he220a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'h100, "test_vwmulu_vv_sew8_042");
    end
  endtask

  task automatic test_vwmulu_vv_sew8_043;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'hff));
      vrf_write(5'd1, replicate_8(DLEN, 8'h2));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'he220a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'h1fe, "test_vwmulu_vv_sew8_043");
    end
  endtask

  task automatic test_vwmulu_vv_sew16_044;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'h2));
      vrf_write(5'd1, replicate_16(DLEN, 16'h3));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'he220a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'h6, "test_vwmulu_vv_sew16_044");
    end
  endtask

  task automatic test_vwmulu_vv_sew16_045;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'h7f));
      vrf_write(5'd1, replicate_16(DLEN, 16'h2));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'he220a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'hfe, "test_vwmulu_vv_sew16_045");
    end
  endtask

  task automatic test_vwmulu_vv_sew16_046;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'h80));
      vrf_write(5'd1, replicate_16(DLEN, 16'h2));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'he220a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'h100, "test_vwmulu_vv_sew16_046");
    end
  endtask

  task automatic test_vwmulu_vv_sew16_047;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'hff));
      vrf_write(5'd1, replicate_16(DLEN, 16'h2));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'he220a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'h1fe, "test_vwmulu_vv_sew16_047");
    end
  endtask

  task automatic test_vwmulsu_vv_sew8_048;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'h2));
      vrf_write(5'd1, replicate_8(DLEN, 8'h3));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hea20a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'h6, "test_vwmulsu_vv_sew8_048");
    end
  endtask

  task automatic test_vwmulsu_vv_sew8_049;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'h7f));
      vrf_write(5'd1, replicate_8(DLEN, 8'h2));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hea20a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'hfe, "test_vwmulsu_vv_sew8_049");
    end
  endtask

  task automatic test_vwmulsu_vv_sew8_050;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'h80));
      vrf_write(5'd1, replicate_8(DLEN, 8'h2));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hea20a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'hff00, "test_vwmulsu_vv_sew8_050");
    end
  endtask

  task automatic test_vwmulsu_vv_sew8_051;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'hff));
      vrf_write(5'd1, replicate_8(DLEN, 8'h2));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hea20a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'hfffe, "test_vwmulsu_vv_sew8_051");
    end
  endtask

  task automatic test_vwmulsu_vv_sew16_052;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'h2));
      vrf_write(5'd1, replicate_16(DLEN, 16'h3));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hea20a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'h6, "test_vwmulsu_vv_sew16_052");
    end
  endtask

  task automatic test_vwmulsu_vv_sew16_053;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'h7f));
      vrf_write(5'd1, replicate_16(DLEN, 16'h2));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hea20a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'hfe, "test_vwmulsu_vv_sew16_053");
    end
  endtask

  task automatic test_vwmulsu_vv_sew16_054;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'h80));
      vrf_write(5'd1, replicate_16(DLEN, 16'h2));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hea20a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'h100, "test_vwmulsu_vv_sew16_054");
    end
  endtask

  task automatic test_vwmulsu_vv_sew16_055;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'hff));
      vrf_write(5'd1, replicate_16(DLEN, 16'h2));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hea20a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'h1fe, "test_vwmulsu_vv_sew16_055");
    end
  endtask

  task automatic test_vwmul_vv_sew8_056;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'h2));
      vrf_write(5'd1, replicate_8(DLEN, 8'h3));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hee20a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'h6, "test_vwmul_vv_sew8_056");
    end
  endtask

  task automatic test_vwmul_vv_sew8_057;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'h7f));
      vrf_write(5'd1, replicate_8(DLEN, 8'h2));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hee20a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'hfe, "test_vwmul_vv_sew8_057");
    end
  endtask

  task automatic test_vwmul_vv_sew8_058;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'h80));
      vrf_write(5'd1, replicate_8(DLEN, 8'h2));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hee20a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'hff00, "test_vwmul_vv_sew8_058");
    end
  endtask

  task automatic test_vwmul_vv_sew8_059;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, replicate_8(DLEN, 8'hff));
      vrf_write(5'd1, replicate_8(DLEN, 8'h2));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hee20a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'hfffe, "test_vwmul_vv_sew8_059");
    end
  endtask

  task automatic test_vwmul_vv_sew16_060;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'h2));
      vrf_write(5'd1, replicate_16(DLEN, 16'h3));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hee20a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'h6, "test_vwmul_vv_sew16_060");
    end
  endtask

  task automatic test_vwmul_vv_sew16_061;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'h7f));
      vrf_write(5'd1, replicate_16(DLEN, 16'h2));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hee20a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'hfe, "test_vwmul_vv_sew16_061");
    end
  endtask

  task automatic test_vwmul_vv_sew16_062;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'h80));
      vrf_write(5'd1, replicate_16(DLEN, 16'h2));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hee20a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'h100, "test_vwmul_vv_sew16_062");
    end
  endtask

  task automatic test_vwmul_vv_sew16_063;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd2, replicate_16(DLEN, 16'hff));
      vrf_write(5'd1, replicate_16(DLEN, 16'h2));
      vrf_write(5'd4, {DLEN{1'b0}});
      issue(32'hee20a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'h1fe, "test_vwmul_vv_sew16_063");
    end
  endtask

  task automatic test_vwmaccu_vv_sew8_064;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd4, replicate_16(DLEN, 16'h10));  // Wide accumulator
      vrf_write(5'd2, replicate_8(DLEN, 8'h2));
      vrf_write(5'd1, replicate_8(DLEN, 8'h3));
      issue(32'hf220a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'h16, "test_vwmaccu_vv_sew8_064");
    end
  endtask

  task automatic test_vwmaccu_vv_sew8_065;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd4, replicate_16(DLEN, 16'h0));  // Wide accumulator
      vrf_write(5'd2, replicate_8(DLEN, 8'h7f));
      vrf_write(5'd1, replicate_8(DLEN, 8'h2));
      issue(32'hf220a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'hfe, "test_vwmaccu_vv_sew8_065");
    end
  endtask

  task automatic test_vwmaccu_vv_sew8_066;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd4, replicate_16(DLEN, 16'h100));  // Wide accumulator
      vrf_write(5'd2, replicate_8(DLEN, 8'h10));
      vrf_write(5'd1, replicate_8(DLEN, 8'h10));
      issue(32'hf220a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'h200, "test_vwmaccu_vv_sew8_066");
    end
  endtask

  task automatic test_vwmaccu_vv_sew16_067;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd4, replicate_32(DLEN, 32'h10));  // Wide accumulator
      vrf_write(5'd2, replicate_16(DLEN, 16'h2));
      vrf_write(5'd1, replicate_16(DLEN, 16'h3));
      issue(32'hf220a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'h16, "test_vwmaccu_vv_sew16_067");
    end
  endtask

  task automatic test_vwmaccu_vv_sew16_068;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd4, replicate_32(DLEN, 32'h0));  // Wide accumulator
      vrf_write(5'd2, replicate_16(DLEN, 16'h7f));
      vrf_write(5'd1, replicate_16(DLEN, 16'h2));
      issue(32'hf220a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'hfe, "test_vwmaccu_vv_sew16_068");
    end
  endtask

  task automatic test_vwmaccu_vv_sew16_069;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd4, replicate_32(DLEN, 32'h100));  // Wide accumulator
      vrf_write(5'd2, replicate_16(DLEN, 16'h10));
      vrf_write(5'd1, replicate_16(DLEN, 16'h10));
      issue(32'hf220a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'h200, "test_vwmaccu_vv_sew16_069");
    end
  endtask

  task automatic test_vwmacc_vv_sew8_070;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd4, replicate_16(DLEN, 16'h10));  // Wide accumulator
      vrf_write(5'd2, replicate_8(DLEN, 8'h2));
      vrf_write(5'd1, replicate_8(DLEN, 8'h3));
      issue(32'hf620a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'h16, "test_vwmacc_vv_sew8_070");
    end
  endtask

  task automatic test_vwmacc_vv_sew8_071;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd4, replicate_16(DLEN, 16'h0));  // Wide accumulator
      vrf_write(5'd2, replicate_8(DLEN, 8'h7f));
      vrf_write(5'd1, replicate_8(DLEN, 8'h2));
      issue(32'hf620a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'hfe, "test_vwmacc_vv_sew8_071");
    end
  endtask

  task automatic test_vwmacc_vv_sew8_072;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd4, replicate_16(DLEN, 16'h100));  // Wide accumulator
      vrf_write(5'd2, replicate_8(DLEN, 8'h10));
      vrf_write(5'd1, replicate_8(DLEN, 8'h10));
      issue(32'hf620a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'h200, "test_vwmacc_vv_sew8_072");
    end
  endtask

  task automatic test_vwmacc_vv_sew16_073;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd4, replicate_32(DLEN, 32'h10));  // Wide accumulator
      vrf_write(5'd2, replicate_16(DLEN, 16'h2));
      vrf_write(5'd1, replicate_16(DLEN, 16'h3));
      issue(32'hf620a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'h16, "test_vwmacc_vv_sew16_073");
    end
  endtask

  task automatic test_vwmacc_vv_sew16_074;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd4, replicate_32(DLEN, 32'h0));  // Wide accumulator
      vrf_write(5'd2, replicate_16(DLEN, 16'h7f));
      vrf_write(5'd1, replicate_16(DLEN, 16'h2));
      issue(32'hf620a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'hfe, "test_vwmacc_vv_sew16_074");
    end
  endtask

  task automatic test_vwmacc_vv_sew16_075;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd4, replicate_32(DLEN, 32'h100));  // Wide accumulator
      vrf_write(5'd2, replicate_16(DLEN, 16'h10));
      vrf_write(5'd1, replicate_16(DLEN, 16'h10));
      issue(32'hf620a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'h200, "test_vwmacc_vv_sew16_075");
    end
  endtask

  task automatic test_vwmaccsu_vv_sew8_076;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd4, replicate_16(DLEN, 16'h10));  // Wide accumulator
      vrf_write(5'd2, replicate_8(DLEN, 8'h2));
      vrf_write(5'd1, replicate_8(DLEN, 8'h3));
      issue(32'hfe20a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'h16, "test_vwmaccsu_vv_sew8_076");
    end
  endtask

  task automatic test_vwmaccsu_vv_sew8_077;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd4, replicate_16(DLEN, 16'h0));  // Wide accumulator
      vrf_write(5'd2, replicate_8(DLEN, 8'h7f));
      vrf_write(5'd1, replicate_8(DLEN, 8'h2));
      issue(32'hfe20a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'hfe, "test_vwmaccsu_vv_sew8_077");
    end
  endtask

  task automatic test_vwmaccsu_vv_sew8_078;
    begin issue(32'h00007057); wait_done(100);
      vrf_write(5'd4, replicate_16(DLEN, 16'h100));  // Wide accumulator
      vrf_write(5'd2, replicate_8(DLEN, 8'h10));
      vrf_write(5'd1, replicate_8(DLEN, 8'h10));
      issue(32'hfe20a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 16, 16'h200, "test_vwmaccsu_vv_sew8_078");
    end
  endtask

  task automatic test_vwmaccsu_vv_sew16_079;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd4, replicate_32(DLEN, 32'h10));  // Wide accumulator
      vrf_write(5'd2, replicate_16(DLEN, 16'h2));
      vrf_write(5'd1, replicate_16(DLEN, 16'h3));
      issue(32'hfe20a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'h16, "test_vwmaccsu_vv_sew16_079");
    end
  endtask

  task automatic test_vwmaccsu_vv_sew16_080;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd4, replicate_32(DLEN, 32'h0));  // Wide accumulator
      vrf_write(5'd2, replicate_16(DLEN, 16'h7f));
      vrf_write(5'd1, replicate_16(DLEN, 16'h2));
      issue(32'hfe20a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'hfe, "test_vwmaccsu_vv_sew16_080");
    end
  endtask

  task automatic test_vwmaccsu_vv_sew16_081;
    begin issue(32'h00807057); wait_done(100);
      vrf_write(5'd4, replicate_32(DLEN, 32'h100));  // Wide accumulator
      vrf_write(5'd2, replicate_16(DLEN, 16'h10));
      vrf_write(5'd1, replicate_16(DLEN, 16'h10));
      issue(32'hfe20a257); wait_done(100);
      check_vrf_elem0_sew(5'd4, 32, 32'h200, "test_vwmaccsu_vv_sew16_081");
    end
  endtask


  task automatic run_wide_tests;
    begin
      $display("=== WIDE TESTS (82) ===");
      test_vwaddu_vv_sew8_000();
      test_vwaddu_vv_sew8_001();
      test_vwaddu_vv_sew8_002();
      test_vwaddu_vv_sew8_003();
      test_vwaddu_vv_sew8_004();
      test_vwaddu_vv_sew16_005();
      test_vwaddu_vv_sew16_006();
      test_vwaddu_vv_sew16_007();
      test_vwaddu_vv_sew16_008();
      test_vwaddu_vv_sew16_009();
      test_vwadd_vv_sew8_010();
      test_vwadd_vv_sew8_011();
      test_vwadd_vv_sew8_012();
      test_vwadd_vv_sew8_013();
      test_vwadd_vv_sew8_014();
      test_vwadd_vv_sew16_015();
      test_vwadd_vv_sew16_016();
      test_vwadd_vv_sew16_017();
      test_vwadd_vv_sew16_018();
      test_vwadd_vv_sew16_019();
      test_vwsubu_vv_sew8_020();
      test_vwsubu_vv_sew8_021();
      test_vwsubu_vv_sew8_022();
      test_vwsubu_vv_sew8_023();
      test_vwsubu_vv_sew8_024();
      test_vwsubu_vv_sew16_025();
      test_vwsubu_vv_sew16_026();
      test_vwsubu_vv_sew16_027();
      test_vwsubu_vv_sew16_028();
      test_vwsubu_vv_sew16_029();
      test_vwsub_vv_sew8_030();
      test_vwsub_vv_sew8_031();
      test_vwsub_vv_sew8_032();
      test_vwsub_vv_sew8_033();
      test_vwsub_vv_sew8_034();
      test_vwsub_vv_sew16_035();
      test_vwsub_vv_sew16_036();
      test_vwsub_vv_sew16_037();
      test_vwsub_vv_sew16_038();
      test_vwsub_vv_sew16_039();
      test_vwmulu_vv_sew8_040();
      test_vwmulu_vv_sew8_041();
      test_vwmulu_vv_sew8_042();
      test_vwmulu_vv_sew8_043();
      test_vwmulu_vv_sew16_044();
      test_vwmulu_vv_sew16_045();
      test_vwmulu_vv_sew16_046();
      test_vwmulu_vv_sew16_047();
      test_vwmulsu_vv_sew8_048();
      test_vwmulsu_vv_sew8_049();
      test_vwmulsu_vv_sew8_050();
      test_vwmulsu_vv_sew8_051();
      test_vwmulsu_vv_sew16_052();
      test_vwmulsu_vv_sew16_053();
      test_vwmulsu_vv_sew16_054();
      test_vwmulsu_vv_sew16_055();
      test_vwmul_vv_sew8_056();
      test_vwmul_vv_sew8_057();
      test_vwmul_vv_sew8_058();
      test_vwmul_vv_sew8_059();
      test_vwmul_vv_sew16_060();
      test_vwmul_vv_sew16_061();
      test_vwmul_vv_sew16_062();
      test_vwmul_vv_sew16_063();
      test_vwmaccu_vv_sew8_064();
      test_vwmaccu_vv_sew8_065();
      test_vwmaccu_vv_sew8_066();
      test_vwmaccu_vv_sew16_067();
      test_vwmaccu_vv_sew16_068();
      test_vwmaccu_vv_sew16_069();
      test_vwmacc_vv_sew8_070();
      test_vwmacc_vv_sew8_071();
      test_vwmacc_vv_sew8_072();
      test_vwmacc_vv_sew16_073();
      test_vwmacc_vv_sew16_074();
      test_vwmacc_vv_sew16_075();
      test_vwmaccsu_vv_sew8_076();
      test_vwmaccsu_vv_sew8_077();
      test_vwmaccsu_vv_sew8_078();
      test_vwmaccsu_vv_sew16_079();
      test_vwmaccsu_vv_sew16_080();
      test_vwmaccsu_vv_sew16_081();
      $display("WIDE: 82 tests done");
    end
  endtask
