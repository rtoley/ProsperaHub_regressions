// VPU v0.5c - VIOTA/VCOMPRESS Tests (18 tests)
// Guarded by TEST_VIOTA_VCOMPRESS define
// All expected values are DLEN-aware (work at 64-bit and 256-bit configs)

  // ========== viota.m tests ==========

  // viota.m SEW=8: mask=0x2B (0b00101011) -> prefix sums [0,1,2,2,3,3,4,4,4,4,...]
  task automatic test_viota_m_sew8_000;
    logic [DLEN-1:0] expected;
    logic [7:0] psum;
    logic [7:0] mask_val;
    begin
      issue(32'h00007057); wait_done(100); // vsetvli SEW=8 LMUL=1
      // vs2 = mask source (0x2B = 0b00101011)
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h2B});
      vrf_write(5'd3, {DLEN{1'b0}});
      // Compute expected: prefix sum of mask bits
      expected = '0;
      mask_val = 8'h2B;
      psum = 0;
      for (int i = 0; i < DLEN/8; i++) begin
        expected[i*8 +: 8] = psum;
        if (i < 8) psum = psum + {7'b0, mask_val[i]};
      end
      issue(encode_viota_m(5'd3, 5'd2)); wait_done(100);
      check_vrf(5'd3, expected, "test_viota_m_sew8_000 - mask=0x2B");
    end
  endtask

  // viota.m SEW=8: mask=0xFF (all set) -> prefix sums [0,1,2,3,4,5,6,7,8,8,...]
  task automatic test_viota_m_sew8_001;
    logic [DLEN-1:0] expected;
    logic [7:0] psum;
    logic [7:0] mask_val;
    begin
      issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'hFF});
      vrf_write(5'd3, {DLEN{1'b0}});
      expected = '0;
      mask_val = 8'hFF;
      psum = 0;
      for (int i = 0; i < DLEN/8; i++) begin
        expected[i*8 +: 8] = psum;
        if (i < 8) psum = psum + {7'b0, mask_val[i]};
      end
      issue(encode_viota_m(5'd3, 5'd2)); wait_done(100);
      check_vrf(5'd3, expected, "test_viota_m_sew8_001 - mask=0xFF");
    end
  endtask

  // viota.m SEW=8: mask=0x00 (none set) -> all zeros
  task automatic test_viota_m_sew8_002;
    begin
      issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, {DLEN{1'b0}});
      vrf_write(5'd3, {DLEN{1'b1}}); // pre-fill with ones
      issue(encode_viota_m(5'd3, 5'd2)); wait_done(100);
      check_vrf(5'd3, {DLEN{1'b0}}, "test_viota_m_sew8_002 - mask=0x00");
    end
  endtask

  // viota.m SEW=16: mask=0x0B -> prefix sums [0,1,2,2,3,3,...]
  task automatic test_viota_m_sew16_003;
    logic [DLEN-1:0] expected;
    logic [15:0] psum;
    logic [3:0] mask_val;
    begin
      issue(32'h00807057); wait_done(100); // vsetvli SEW=16 LMUL=1
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h0B}); // mask bits: 1,1,0,1
      vrf_write(5'd3, {DLEN{1'b0}});
      expected = '0;
      mask_val = 4'hB; // 1011
      psum = 0;
      for (int i = 0; i < DLEN/16; i++) begin
        expected[i*16 +: 16] = psum;
        if (i < 4) psum = psum + {15'b0, mask_val[i]};
      end
      issue(encode_viota_m(5'd3, 5'd2)); wait_done(100);
      check_vrf(5'd3, expected, "test_viota_m_sew16_003 - mask=0x0B");
    end
  endtask

  // viota.m SEW=32: mask=0x03 -> prefix sums [0,1,2,2,...]
  task automatic test_viota_m_sew32_004;
    logic [DLEN-1:0] expected;
    logic [31:0] psum;
    logic [1:0] mask_val;
    begin
      issue(32'h01007057); wait_done(100); // vsetvli SEW=32 LMUL=1
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h03}); // mask bits: 1,1
      vrf_write(5'd3, {DLEN{1'b0}});
      expected = '0;
      mask_val = 2'b11;
      psum = 0;
      for (int i = 0; i < DLEN/32; i++) begin
        expected[i*32 +: 32] = psum;
        if (i < 2) psum = psum + {31'b0, mask_val[i]};
      end
      issue(encode_viota_m(5'd3, 5'd2)); wait_done(100);
      check_vrf(5'd3, expected, "test_viota_m_sew32_004 - mask=0x03");
    end
  endtask

  // viota.m SEW=8: mask=0x01 (single bit) -> [0,1,1,1,...]
  task automatic test_viota_m_sew8_005;
    logic [DLEN-1:0] expected;
    logic [7:0] psum;
    begin
      issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h01});
      vrf_write(5'd3, {DLEN{1'b0}});
      expected = '0;
      psum = 0;
      for (int i = 0; i < DLEN/8; i++) begin
        expected[i*8 +: 8] = psum;
        if (i == 0) psum = psum + 1;
      end
      issue(encode_viota_m(5'd3, 5'd2)); wait_done(100);
      check_vrf(5'd3, expected, "test_viota_m_sew8_005 - mask=0x01");
    end
  endtask

  // ========== vcompress.vm tests ==========

  // vcompress.vm SEW=8: mask=0x2B, compress 4 of 8 elements
  task automatic test_vcompress_vm_sew8_006;
    logic [DLEN-1:0] vs1_data, vs2_data, old_vd, expected;
    logic [7:0] mask_val;
    int pos;
    begin
      issue(32'h00007057); wait_done(100); // vsetvli SEW=8 LMUL=1
      // vs1 = mask (0x2B = bits 0,1,3,5 set)
      mask_val = 8'h2B;
      vs1_data = {{DLEN-8{1'b0}}, mask_val};
      // vs2 = data source: elements 0x10,0x20,...,0x80
      vs2_data = '0;
      for (int i = 0; i < DLEN/8; i++) begin
        if (i < 8) vs2_data[i*8 +: 8] = (i+1) * 8'h10;
        else vs2_data[i*8 +: 8] = 8'h00;
      end
      // old_vd = 0xFF in all positions
      old_vd = {DLEN/8{8'hFF}};
      vrf_write(5'd1, vs1_data);
      vrf_write(5'd2, vs2_data);
      vrf_write(5'd3, old_vd);
      // Expected: active elements packed, rest from old_vd
      expected = old_vd;
      pos = 0;
      for (int i = 0; i < DLEN/8; i++) begin
        if (i < 8 && mask_val[i]) begin
          expected[pos*8 +: 8] = vs2_data[i*8 +: 8];
          pos++;
        end
      end
      issue(encode_vcompress_vm(5'd3, 5'd2, 5'd1)); wait_done(100);
      check_vrf(5'd3, expected, "test_vcompress_vm_sew8_006 - mask=0x2B");
    end
  endtask

  // vcompress.vm SEW=8: mask=0xFF (all active) -> identity copy from vs2
  task automatic test_vcompress_vm_sew8_007;
    logic [DLEN-1:0] vs2_data, old_vd, expected;
    int pos;
    begin
      issue(32'h00007057); wait_done(100);
      vs2_data = '0;
      for (int i = 0; i < DLEN/8; i++) begin
        if (i < 8) vs2_data[i*8 +: 8] = i[7:0] + 1;
      end
      old_vd = {DLEN/8{8'hAA}};
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'hFF});
      vrf_write(5'd2, vs2_data);
      vrf_write(5'd3, old_vd);
      // All 8 elements active -> first 8 positions = vs2[0..7], rest = old_vd
      expected = old_vd;
      pos = 0;
      for (int i = 0; i < 8; i++) begin
        expected[pos*8 +: 8] = vs2_data[i*8 +: 8];
        pos++;
      end
      issue(encode_vcompress_vm(5'd3, 5'd2, 5'd1)); wait_done(100);
      check_vrf(5'd3, expected, "test_vcompress_vm_sew8_007 - mask=0xFF (all active)");
    end
  endtask

  // vcompress.vm SEW=8: mask=0x00 (none active) -> preserve old_vd
  task automatic test_vcompress_vm_sew8_008;
    logic [DLEN-1:0] old_vd;
    begin
      issue(32'h00007057); wait_done(100);
      old_vd = {DLEN/8{8'hBB}};
      vrf_write(5'd1, {DLEN{1'b0}}); // no mask bits set
      vrf_write(5'd2, {DLEN/8{8'h55}}); // data (should not appear)
      vrf_write(5'd3, old_vd);
      issue(encode_vcompress_vm(5'd3, 5'd2, 5'd1)); wait_done(100);
      check_vrf(5'd3, old_vd, "test_vcompress_vm_sew8_008 - mask=0x00 (preserve old_vd)");
    end
  endtask

  // vcompress.vm SEW=16: mask=0x05 (bits 0,2 set)
  task automatic test_vcompress_vm_sew16_009;
    logic [DLEN-1:0] vs1_data, vs2_data, old_vd, expected;
    logic [3:0] mask_val;
    int pos;
    begin
      issue(32'h00807057); wait_done(100); // SEW=16
      mask_val = 4'h5; // bits 0,2
      vs1_data = {{DLEN-8{1'b0}}, 4'b0, mask_val};
      vs2_data = '0;
      for (int i = 0; i < DLEN/16; i++) begin
        if (i < 4) vs2_data[i*16 +: 16] = (i+1) * 16'h1000;
      end
      old_vd = {DLEN/16{16'hDDDD}};
      vrf_write(5'd1, vs1_data);
      vrf_write(5'd2, vs2_data);
      vrf_write(5'd3, old_vd);
      expected = old_vd;
      pos = 0;
      for (int i = 0; i < DLEN/16; i++) begin
        if (i < 4 && mask_val[i]) begin
          expected[pos*16 +: 16] = vs2_data[i*16 +: 16];
          pos++;
        end
      end
      issue(encode_vcompress_vm(5'd3, 5'd2, 5'd1)); wait_done(100);
      check_vrf(5'd3, expected, "test_vcompress_vm_sew16_009 - mask=0x5");
    end
  endtask

  // vcompress.vm SEW=32: mask=0x01 (bit 0 only)
  task automatic test_vcompress_vm_sew32_010;
    logic [DLEN-1:0] vs2_data, old_vd, expected;
    begin
      issue(32'h01007057); wait_done(100); // SEW=32
      vs2_data = '0;
      for (int i = 0; i < DLEN/32; i++) begin
        if (i < 2) vs2_data[i*32 +: 32] = (i+1) * 32'h11111111;
      end
      old_vd = {DLEN/32{32'hCCCCCCCC}};
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h01}); // bit 0 only
      vrf_write(5'd2, vs2_data);
      vrf_write(5'd3, old_vd);
      expected = old_vd;
      expected[0*32 +: 32] = vs2_data[0*32 +: 32]; // only elem 0 active
      issue(encode_vcompress_vm(5'd3, 5'd2, 5'd1)); wait_done(100);
      check_vrf(5'd3, expected, "test_vcompress_vm_sew32_010 - mask=0x01");
    end
  endtask

  // vcompress.vm SEW=8: mask=0x80 (only bit 7 set)
  task automatic test_vcompress_vm_sew8_011;
    logic [DLEN-1:0] vs2_data, old_vd, expected;
    begin
      issue(32'h00007057); wait_done(100);
      vs2_data = '0;
      for (int i = 0; i < DLEN/8; i++) begin
        if (i < 8) vs2_data[i*8 +: 8] = (i+1) * 8'h10;
      end
      old_vd = {DLEN/8{8'hEE}};
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h80}); // only bit 7
      vrf_write(5'd2, vs2_data);
      vrf_write(5'd3, old_vd);
      expected = old_vd;
      expected[0*8 +: 8] = vs2_data[7*8 +: 8]; // element 7 -> position 0
      issue(encode_vcompress_vm(5'd3, 5'd2, 5'd1)); wait_done(100);
      check_vrf(5'd3, expected, "test_vcompress_vm_sew8_011 - mask=0x80 (last elem only)");
    end
  endtask

  // ========== viota/vcompress with different dest registers ==========

  // viota.m writing to v5 (different dest)
  task automatic test_viota_m_sew8_012;
    logic [DLEN-1:0] expected;
    logic [7:0] psum;
    begin
      issue(32'h00007057); wait_done(100);
      vrf_write(5'd4, {{DLEN-8{1'b0}}, 8'hAA}); // mask=0xAA: bits 1,3,5,7
      vrf_write(5'd5, {DLEN{1'b0}});
      expected = '0;
      psum = 0;
      for (int i = 0; i < DLEN/8; i++) begin
        expected[i*8 +: 8] = psum;
        if (i < 8) psum = psum + {7'b0, ((8'hAA >> i) & 1'b1)};
      end
      issue(encode_viota_m(5'd5, 5'd4)); wait_done(100);
      check_vrf(5'd5, expected, "test_viota_m_sew8_012 - mask=0xAA to v5");
    end
  endtask

  // vcompress.vm using v4,v5,v6
  task automatic test_vcompress_vm_sew8_013;
    logic [DLEN-1:0] vs2_data, old_vd, expected;
    logic [7:0] mask_val;
    int pos;
    begin
      issue(32'h00007057); wait_done(100);
      mask_val = 8'h55; // bits 0,2,4,6
      vrf_write(5'd4, {{DLEN-8{1'b0}}, mask_val});
      vs2_data = '0;
      for (int i = 0; i < DLEN/8; i++) begin
        if (i < 8) vs2_data[i*8 +: 8] = 8'hA0 + i[7:0];
      end
      old_vd = {DLEN/8{8'h00}};
      vrf_write(5'd5, vs2_data);
      vrf_write(5'd6, old_vd);
      expected = old_vd;
      pos = 0;
      for (int i = 0; i < 8; i++) begin
        if (mask_val[i]) begin
          expected[pos*8 +: 8] = vs2_data[i*8 +: 8];
          pos++;
        end
      end
      issue(encode_vcompress_vm(5'd6, 5'd5, 5'd4)); wait_done(100);
      check_vrf(5'd6, expected, "test_vcompress_vm_sew8_013 - mask=0x55 to v6");
    end
  endtask

  // ========== Back-to-back pipeline tests (hazard-adjacent) ==========

  // vadd then viota (no register conflict - should not stall)
  task automatic test_viota_after_vadd_014;
    logic [DLEN-1:0] expected;
    logic [7:0] psum;
    begin
      issue(32'h00007057); wait_done(100);
      vrf_write(5'd1, {DLEN/8{8'h01}});
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h0F}); // mask for viota
      vrf_write(5'd3, {DLEN/8{8'h02}});
      // vadd v4, v1, v3 -> issue first
      issue(encode_vadd_vv(5'd4, 5'd3, 5'd1)); wait_done(100);
      // viota.m v5, v2 -> no conflict with v4
      expected = '0;
      psum = 0;
      for (int i = 0; i < DLEN/8; i++) begin
        expected[i*8 +: 8] = psum;
        if (i < 4) psum = psum + 1; // mask 0x0F has first 4 bits set
      end
      issue(encode_viota_m(5'd5, 5'd2)); wait_done(100);
      check_vrf(5'd5, expected, "test_viota_after_vadd_014");
    end
  endtask

  // vadd writes v3, then vcompress reads v3 as old_vd (RAW on vs3)
  task automatic test_vcompress_raw_vs3_015;
    logic [DLEN-1:0] vs2_data, vadd_result, expected;
    logic [7:0] mask_val;
    int pos;
    begin
      issue(32'h00007057); wait_done(100);
      // Setup: v1=0x01 per elem, v2=0x02 per elem
      vrf_write(5'd1, {DLEN/8{8'h01}});
      vrf_write(5'd2, {DLEN/8{8'h02}});
      // vadd v3, v1, v2 -> v3 = 0x03 per elem
      issue(encode_vadd_vv(5'd3, 5'd2, 5'd1)); wait_done(100);
      // Now setup compress: vs1(mask)=v4, vs2(data)=v5, vd(old_vd)=v3
      mask_val = 8'h03; // bits 0,1
      vrf_write(5'd4, {{DLEN-8{1'b0}}, mask_val});
      vs2_data = '0;
      for (int i = 0; i < DLEN/8; i++) begin
        if (i < 8) vs2_data[i*8 +: 8] = 8'hF0 + i[7:0];
      end
      vrf_write(5'd5, vs2_data);
      // v3 now has vadd result (0x03 per elem) - compress should use this as old_vd
      vadd_result = {DLEN/8{8'h03}};
      expected = vadd_result;
      pos = 0;
      for (int i = 0; i < 8; i++) begin
        if (mask_val[i]) begin
          expected[pos*8 +: 8] = vs2_data[i*8 +: 8];
          pos++;
        end
      end
      issue(encode_vcompress_vm(5'd3, 5'd5, 5'd4)); wait_done(100);
      check_vrf(5'd3, expected, "test_vcompress_raw_vs3_015 - RAW on old_vd");
    end
  endtask

  // viota.m SEW=8: mask=0x55 (alternating) -> [0,0,1,1,2,2,3,3,4,4,...]
  task automatic test_viota_m_sew8_016;
    logic [DLEN-1:0] expected;
    logic [7:0] psum;
    begin
      issue(32'h00007057); wait_done(100);
      vrf_write(5'd2, {{DLEN-8{1'b0}}, 8'h55});
      vrf_write(5'd3, {DLEN{1'b0}});
      expected = '0;
      psum = 0;
      for (int i = 0; i < DLEN/8; i++) begin
        expected[i*8 +: 8] = psum;
        if (i < 8) psum = psum + {7'b0, ((8'h55 >> i) & 1'b1)};
      end
      issue(encode_viota_m(5'd3, 5'd2)); wait_done(100);
      check_vrf(5'd3, expected, "test_viota_m_sew8_016 - mask=0x55");
    end
  endtask

  // vcompress.vm SEW=16: mask=0x0F (all 4 active) -> identity
  task automatic test_vcompress_vm_sew16_017;
    logic [DLEN-1:0] vs2_data, old_vd, expected;
    int pos;
    begin
      issue(32'h00807057); wait_done(100); // SEW=16
      vs2_data = '0;
      for (int i = 0; i < DLEN/16; i++) begin
        if (i < 4) vs2_data[i*16 +: 16] = (i+1) * 16'h1111;
      end
      old_vd = {DLEN/16{16'hBEEF}};
      vrf_write(5'd1, {{DLEN-8{1'b0}}, 8'h0F}); // all 4 active
      vrf_write(5'd2, vs2_data);
      vrf_write(5'd3, old_vd);
      expected = old_vd;
      pos = 0;
      for (int i = 0; i < 4; i++) begin
        expected[pos*16 +: 16] = vs2_data[i*16 +: 16];
        pos++;
      end
      issue(encode_vcompress_vm(5'd3, 5'd2, 5'd1)); wait_done(100);
      check_vrf(5'd3, expected, "test_vcompress_vm_sew16_017 - mask=0x0F (identity)");
    end
  endtask

  // ========== Runner ==========

  task automatic run_viota_vcompress_tests;
    begin
      $display("=== VIOTA/VCOMPRESS TESTS (18) ===");
      // viota.m
      test_viota_m_sew8_000();
      test_viota_m_sew8_001();
      test_viota_m_sew8_002();
      test_viota_m_sew16_003();
      test_viota_m_sew32_004();
      test_viota_m_sew8_005();
      // vcompress.vm
      test_vcompress_vm_sew8_006();
      test_vcompress_vm_sew8_007();
      test_vcompress_vm_sew8_008();
      test_vcompress_vm_sew16_009();
      test_vcompress_vm_sew32_010();
      test_vcompress_vm_sew8_011();
      // Different register combos
      test_viota_m_sew8_012();
      test_vcompress_vm_sew8_013();
      // Pipeline / hazard adjacent
      test_viota_after_vadd_014();
      test_vcompress_raw_vs3_015();
      test_viota_m_sew8_016();
      test_vcompress_vm_sew16_017();
      $display("VIOTA/VCOMPRESS: 18 tests done");
    end
  endtask
