// VPU v0.3c - MASK Tests (56 tests)

  task automatic test_vmand_mm_000;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h00});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h00});
      vrf_write(5'd0, 64'h0);
      issue(32'h6620a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-8{1'b0}}, 8'h00}, "test_vmand_mm_000");
    end
  endtask

  task automatic test_vmand_mm_001;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'hff});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'hff});
      vrf_write(5'd0, 64'h0);
      issue(32'h6620a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-8{1'b0}}, 8'hff}, "test_vmand_mm_001");
    end
  endtask

  task automatic test_vmand_mm_002;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'haa});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h55});
      vrf_write(5'd0, 64'h0);
      issue(32'h6620a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-8{1'b0}}, 8'h00}, "test_vmand_mm_002");
    end
  endtask

  task automatic test_vmand_mm_003;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h0f});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'hf0});
      vrf_write(5'd0, 64'h0);
      issue(32'h6620a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-8{1'b0}}, 8'h00}, "test_vmand_mm_003");
    end
  endtask

  task automatic test_vmand_mm_004;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h33});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'hcc});
      vrf_write(5'd0, 64'h0);
      issue(32'h6620a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-8{1'b0}}, 8'h00}, "test_vmand_mm_004");
    end
  endtask

  task automatic test_vmand_mm_005;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h01});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h80});
      vrf_write(5'd0, 64'h0);
      issue(32'h6620a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-8{1'b0}}, 8'h00}, "test_vmand_mm_005");
    end
  endtask

  task automatic test_vmand_mm_006;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'hfe});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h01});
      vrf_write(5'd0, 64'h0);
      issue(32'h6620a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-8{1'b0}}, 8'h00}, "test_vmand_mm_006");
    end
  endtask

  task automatic test_vmnand_mm_000;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h00});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h00});
      vrf_write(5'd0, 64'h0);
      issue(32'h7620a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-VLMAX_8{1'b0}}, {VLMAX_8-8{1'b1}}, 8'hff}, "test_vmnand_mm_000");
    end
  endtask

  task automatic test_vmnand_mm_001;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'hff});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'hff});
      vrf_write(5'd0, 64'h0);
      issue(32'h7620a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-VLMAX_8{1'b0}}, {VLMAX_8-8{1'b1}}, 8'h00}, "test_vmnand_mm_001");
    end
  endtask

  task automatic test_vmnand_mm_002;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'haa});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h55});
      vrf_write(5'd0, 64'h0);
      issue(32'h7620a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-VLMAX_8{1'b0}}, {VLMAX_8-8{1'b1}}, 8'hff}, "test_vmnand_mm_002");
    end
  endtask

  task automatic test_vmnand_mm_003;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h0f});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'hf0});
      vrf_write(5'd0, 64'h0);
      issue(32'h7620a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-VLMAX_8{1'b0}}, {VLMAX_8-8{1'b1}}, 8'hff}, "test_vmnand_mm_003");
    end
  endtask

  task automatic test_vmnand_mm_004;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h33});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'hcc});
      vrf_write(5'd0, 64'h0);
      issue(32'h7620a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-VLMAX_8{1'b0}}, {VLMAX_8-8{1'b1}}, 8'hff}, "test_vmnand_mm_004");
    end
  endtask

  task automatic test_vmnand_mm_005;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h01});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h80});
      vrf_write(5'd0, 64'h0);
      issue(32'h7620a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-VLMAX_8{1'b0}}, {VLMAX_8-8{1'b1}}, 8'hff}, "test_vmnand_mm_005");
    end
  endtask

  task automatic test_vmnand_mm_006;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'hfe});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h01});
      vrf_write(5'd0, 64'h0);
      issue(32'h7620a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-VLMAX_8{1'b0}}, {VLMAX_8-8{1'b1}}, 8'hff}, "test_vmnand_mm_006");
    end
  endtask

  task automatic test_vmandn_mm_000;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h00});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h00});
      vrf_write(5'd0, 64'h0);
      issue(32'h6220a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-8{1'b0}}, 8'h00}, "test_vmandn_mm_000");
    end
  endtask

  task automatic test_vmandn_mm_001;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'hff});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'hff});
      vrf_write(5'd0, 64'h0);
      issue(32'h6220a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-8{1'b0}}, 8'h00}, "test_vmandn_mm_001");
    end
  endtask

  task automatic test_vmandn_mm_002;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'haa});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h55});
      vrf_write(5'd0, 64'h0);
      issue(32'h6220a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-8{1'b0}}, 8'haa}, "test_vmandn_mm_002");
    end
  endtask

  task automatic test_vmandn_mm_003;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h0f});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'hf0});
      vrf_write(5'd0, 64'h0);
      issue(32'h6220a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-8{1'b0}}, 8'h0f}, "test_vmandn_mm_003");
    end
  endtask

  task automatic test_vmandn_mm_004;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h33});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'hcc});
      vrf_write(5'd0, 64'h0);
      issue(32'h6220a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-8{1'b0}}, 8'h33}, "test_vmandn_mm_004");
    end
  endtask

  task automatic test_vmandn_mm_005;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h01});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h80});
      vrf_write(5'd0, 64'h0);
      issue(32'h6220a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-8{1'b0}}, 8'h01}, "test_vmandn_mm_005");
    end
  endtask

  task automatic test_vmandn_mm_006;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'hfe});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h01});
      vrf_write(5'd0, 64'h0);
      issue(32'h6220a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-8{1'b0}}, 8'hfe}, "test_vmandn_mm_006");
    end
  endtask

  task automatic test_vmxor_mm_000;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h00});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h00});
      vrf_write(5'd0, 64'h0);
      issue(32'h6e20a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-8{1'b0}}, 8'h00}, "test_vmxor_mm_000");
    end
  endtask

  task automatic test_vmxor_mm_001;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'hff});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'hff});
      vrf_write(5'd0, 64'h0);
      issue(32'h6e20a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-8{1'b0}}, 8'h00}, "test_vmxor_mm_001");
    end
  endtask

  task automatic test_vmxor_mm_002;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'haa});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h55});
      vrf_write(5'd0, 64'h0);
      issue(32'h6e20a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-8{1'b0}}, 8'hff}, "test_vmxor_mm_002");
    end
  endtask

  task automatic test_vmxor_mm_003;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h0f});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'hf0});
      vrf_write(5'd0, 64'h0);
      issue(32'h6e20a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-8{1'b0}}, 8'hff}, "test_vmxor_mm_003");
    end
  endtask

  task automatic test_vmxor_mm_004;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h33});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'hcc});
      vrf_write(5'd0, 64'h0);
      issue(32'h6e20a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-8{1'b0}}, 8'hff}, "test_vmxor_mm_004");
    end
  endtask

  task automatic test_vmxor_mm_005;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h01});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h80});
      vrf_write(5'd0, 64'h0);
      issue(32'h6e20a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-8{1'b0}}, 8'h81}, "test_vmxor_mm_005");
    end
  endtask

  task automatic test_vmxor_mm_006;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'hfe});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h01});
      vrf_write(5'd0, 64'h0);
      issue(32'h6e20a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-8{1'b0}}, 8'hff}, "test_vmxor_mm_006");
    end
  endtask

  task automatic test_vmor_mm_000;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h00});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h00});
      vrf_write(5'd0, 64'h0);
      issue(32'h6a20a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-8{1'b0}}, 8'h00}, "test_vmor_mm_000");
    end
  endtask

  task automatic test_vmor_mm_001;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'hff});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'hff});
      vrf_write(5'd0, 64'h0);
      issue(32'h6a20a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-8{1'b0}}, 8'hff}, "test_vmor_mm_001");
    end
  endtask

  task automatic test_vmor_mm_002;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'haa});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h55});
      vrf_write(5'd0, 64'h0);
      issue(32'h6a20a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-8{1'b0}}, 8'hff}, "test_vmor_mm_002");
    end
  endtask

  task automatic test_vmor_mm_003;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h0f});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'hf0});
      vrf_write(5'd0, 64'h0);
      issue(32'h6a20a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-8{1'b0}}, 8'hff}, "test_vmor_mm_003");
    end
  endtask

  task automatic test_vmor_mm_004;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h33});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'hcc});
      vrf_write(5'd0, 64'h0);
      issue(32'h6a20a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-8{1'b0}}, 8'hff}, "test_vmor_mm_004");
    end
  endtask

  task automatic test_vmor_mm_005;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h01});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h80});
      vrf_write(5'd0, 64'h0);
      issue(32'h6a20a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-8{1'b0}}, 8'h81}, "test_vmor_mm_005");
    end
  endtask

  task automatic test_vmor_mm_006;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'hfe});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h01});
      vrf_write(5'd0, 64'h0);
      issue(32'h6a20a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-8{1'b0}}, 8'hff}, "test_vmor_mm_006");
    end
  endtask

  task automatic test_vmnor_mm_000;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h00});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h00});
      vrf_write(5'd0, 64'h0);
      issue(32'h7a20a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-VLMAX_8{1'b0}}, {VLMAX_8-8{1'b1}}, 8'hff}, "test_vmnor_mm_000");
    end
  endtask

  task automatic test_vmnor_mm_001;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'hff});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'hff});
      vrf_write(5'd0, 64'h0);
      issue(32'h7a20a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-VLMAX_8{1'b0}}, {VLMAX_8-8{1'b1}}, 8'h00}, "test_vmnor_mm_001");
    end
  endtask

  task automatic test_vmnor_mm_002;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'haa});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h55});
      vrf_write(5'd0, 64'h0);
      issue(32'h7a20a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-VLMAX_8{1'b0}}, {VLMAX_8-8{1'b1}}, 8'h00}, "test_vmnor_mm_002");
    end
  endtask

  task automatic test_vmnor_mm_003;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h0f});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'hf0});
      vrf_write(5'd0, 64'h0);
      issue(32'h7a20a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-VLMAX_8{1'b0}}, {VLMAX_8-8{1'b1}}, 8'h00}, "test_vmnor_mm_003");
    end
  endtask

  task automatic test_vmnor_mm_004;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h33});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'hcc});
      vrf_write(5'd0, 64'h0);
      issue(32'h7a20a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-VLMAX_8{1'b0}}, {VLMAX_8-8{1'b1}}, 8'h00}, "test_vmnor_mm_004");
    end
  endtask

  task automatic test_vmnor_mm_005;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h01});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h80});
      vrf_write(5'd0, 64'h0);
      issue(32'h7a20a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-VLMAX_8{1'b0}}, {VLMAX_8-8{1'b1}}, 8'h7e}, "test_vmnor_mm_005");
    end
  endtask

  task automatic test_vmnor_mm_006;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'hfe});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h01});
      vrf_write(5'd0, 64'h0);
      issue(32'h7a20a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-VLMAX_8{1'b0}}, {VLMAX_8-8{1'b1}}, 8'h00}, "test_vmnor_mm_006");
    end
  endtask

  task automatic test_vmorn_mm_000;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h00});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h00});
      vrf_write(5'd0, 64'h0);
      issue(32'h7220a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-VLMAX_8{1'b0}}, {VLMAX_8-8{1'b1}}, 8'hff}, "test_vmorn_mm_000");
    end
  endtask

  task automatic test_vmorn_mm_001;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'hff});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'hff});
      vrf_write(5'd0, 64'h0);
      issue(32'h7220a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-VLMAX_8{1'b0}}, {VLMAX_8-8{1'b1}}, 8'hff}, "test_vmorn_mm_001");
    end
  endtask

  task automatic test_vmorn_mm_002;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'haa});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h55});
      vrf_write(5'd0, 64'h0);
      issue(32'h7220a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-VLMAX_8{1'b0}}, {VLMAX_8-8{1'b1}}, 8'haa}, "test_vmorn_mm_002");
    end
  endtask

  task automatic test_vmorn_mm_003;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h0f});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'hf0});
      vrf_write(5'd0, 64'h0);
      issue(32'h7220a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-VLMAX_8{1'b0}}, {VLMAX_8-8{1'b1}}, 8'h0f}, "test_vmorn_mm_003");
    end
  endtask

  task automatic test_vmorn_mm_004;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h33});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'hcc});
      vrf_write(5'd0, 64'h0);
      issue(32'h7220a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-VLMAX_8{1'b0}}, {VLMAX_8-8{1'b1}}, 8'h33}, "test_vmorn_mm_004");
    end
  endtask

  task automatic test_vmorn_mm_005;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h01});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h80});
      vrf_write(5'd0, 64'h0);
      issue(32'h7220a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-VLMAX_8{1'b0}}, {VLMAX_8-8{1'b1}}, 8'h7f}, "test_vmorn_mm_005");
    end
  endtask

  task automatic test_vmorn_mm_006;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'hfe});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h01});
      vrf_write(5'd0, 64'h0);
      issue(32'h7220a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-VLMAX_8{1'b0}}, {VLMAX_8-8{1'b1}}, 8'hfe}, "test_vmorn_mm_006");
    end
  endtask

  task automatic test_vmxnor_mm_000;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h00});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h00});
      vrf_write(5'd0, 64'h0);
      issue(32'h7e20a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-VLMAX_8{1'b0}}, {VLMAX_8-8{1'b1}}, 8'hff}, "test_vmxnor_mm_000");
    end
  endtask

  task automatic test_vmxnor_mm_001;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'hff});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'hff});
      vrf_write(5'd0, 64'h0);
      issue(32'h7e20a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-VLMAX_8{1'b0}}, {VLMAX_8-8{1'b1}}, 8'hff}, "test_vmxnor_mm_001");
    end
  endtask

  task automatic test_vmxnor_mm_002;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'haa});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h55});
      vrf_write(5'd0, 64'h0);
      issue(32'h7e20a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-VLMAX_8{1'b0}}, {VLMAX_8-8{1'b1}}, 8'h00}, "test_vmxnor_mm_002");
    end
  endtask

  task automatic test_vmxnor_mm_003;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h0f});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'hf0});
      vrf_write(5'd0, 64'h0);
      issue(32'h7e20a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-VLMAX_8{1'b0}}, {VLMAX_8-8{1'b1}}, 8'h00}, "test_vmxnor_mm_003");
    end
  endtask

  task automatic test_vmxnor_mm_004;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h33});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'hcc});
      vrf_write(5'd0, 64'h0);
      issue(32'h7e20a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-VLMAX_8{1'b0}}, {VLMAX_8-8{1'b1}}, 8'h00}, "test_vmxnor_mm_004");
    end
  endtask

  task automatic test_vmxnor_mm_005;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h01});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h80});
      vrf_write(5'd0, 64'h0);
      issue(32'h7e20a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-VLMAX_8{1'b0}}, {VLMAX_8-8{1'b1}}, 8'h7e}, "test_vmxnor_mm_005");
    end
  endtask

  task automatic test_vmxnor_mm_006;
    begin issue(32'h00007057); wait_done(100);
      // Load mask operands into v2 and v1 (mask bits in LSBs)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'hfe});
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h01});
      vrf_write(5'd0, 64'h0);
      issue(32'h7e20a057); wait_done(100);
      check_vrf_mask(5'd0, {{DLEN-VLMAX_8{1'b0}}, {VLMAX_8-8{1'b1}}, 8'h00}, "test_vmxnor_mm_006");
    end
  endtask


  task automatic run_mask_tests;
    begin
      $display("=== MASK TESTS (56) ===");
      test_vmand_mm_000();
      test_vmand_mm_001();
      test_vmand_mm_002();
      test_vmand_mm_003();
      test_vmand_mm_004();
      test_vmand_mm_005();
      test_vmand_mm_006();
      test_vmnand_mm_000();
      test_vmnand_mm_001();
      test_vmnand_mm_002();
      test_vmnand_mm_003();
      test_vmnand_mm_004();
      test_vmnand_mm_005();
      test_vmnand_mm_006();
      test_vmandn_mm_000();
      test_vmandn_mm_001();
      test_vmandn_mm_002();
      test_vmandn_mm_003();
      test_vmandn_mm_004();
      test_vmandn_mm_005();
      test_vmandn_mm_006();
      test_vmxor_mm_000();
      test_vmxor_mm_001();
      test_vmxor_mm_002();
      test_vmxor_mm_003();
      test_vmxor_mm_004();
      test_vmxor_mm_005();
      test_vmxor_mm_006();
      test_vmor_mm_000();
      test_vmor_mm_001();
      test_vmor_mm_002();
      test_vmor_mm_003();
      test_vmor_mm_004();
      test_vmor_mm_005();
      test_vmor_mm_006();
      test_vmnor_mm_000();
      test_vmnor_mm_001();
      test_vmnor_mm_002();
      test_vmnor_mm_003();
      test_vmnor_mm_004();
      test_vmnor_mm_005();
      test_vmnor_mm_006();
      test_vmorn_mm_000();
      test_vmorn_mm_001();
      test_vmorn_mm_002();
      test_vmorn_mm_003();
      test_vmorn_mm_004();
      test_vmorn_mm_005();
      test_vmorn_mm_006();
      test_vmxnor_mm_000();
      test_vmxnor_mm_001();
      test_vmxnor_mm_002();
      test_vmxnor_mm_003();
      test_vmxnor_mm_004();
      test_vmxnor_mm_005();
      test_vmxnor_mm_006();
      $display("MASK: 56 tests done");
    end
  endtask
