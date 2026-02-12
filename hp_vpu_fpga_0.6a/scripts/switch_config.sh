#!/bin/bash
# Switch VPU configuration
# Usage: ./scripts/switch_config.sh [256|64|arty7] [--enable-csr|--disable-csr]

set -e

ENABLE_CSR_OPT=""

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        256)
            cp config/vpu_config_256.json config/vpu_config.json
            echo "Switched to 256-bit config (VLEN=256, DLEN=256)"
            ;;
        128)
            cp config/vpu_config_128.json config/vpu_config.json
            echo "Switched to 128-bit config (VLEN=128, DLEN=128)"
            ;;
        64|arty7)
            cp config/vpu_config_arty7.json config/vpu_config.json
            echo "Switched to Arty7 config (VLEN=64, DLEN=64)"
            ;;
        csr|with-csr)
            cp config/vpu_config_with_csr.json config/vpu_config.json
            echo "Switched to config with CSR enabled"
            ;;
        --enable-csr)
            ENABLE_CSR_OPT="true"
            ;;
        --disable-csr)
            ENABLE_CSR_OPT="false"
            ;;
        -h|--help)
            echo "Usage: $0 [config] [options]"
            echo ""
            echo "Configs:"
            echo "  256      - Full 256-bit config"
            echo "  128      - 128-bit config (most common RISC-V V)"
            echo "  64       - 64-bit config for small FPGAs"
            echo "  arty7    - Same as 64 (Arty A7-100T target)"
            echo "  csr      - 64-bit with CSR module enabled"
            echo ""
            echo "Options:"
            echo "  --enable-csr   - Enable CSR module (~500 extra cells)"
            echo "  --disable-csr  - Disable CSR module (default)"
            echo ""
            echo "Examples:"
            echo "  $0 64 --enable-csr   # 64-bit with CSR"
            echo "  $0 256               # 256-bit, CSR from config file"
            exit 0
            ;;
    esac
done

# Apply CSR override if specified
if [ "$ENABLE_CSR_OPT" = "true" ]; then
    # Use sed to change enable_csr to true
    if grep -q '"enable_csr"' config/vpu_config.json; then
        sed -i 's/"enable_csr"[[:space:]]*:[[:space:]]*false/"enable_csr": true/' config/vpu_config.json
    else
        # Add enable_csr if not present (insert before last } in features block)
        sed -i '/"lmul_multi_uop"/s/$/,\n    "enable_csr": true/' config/vpu_config.json
    fi
    echo "CSR module: ENABLED"
elif [ "$ENABLE_CSR_OPT" = "false" ]; then
    sed -i 's/"enable_csr"[[:space:]]*:[[:space:]]*true/"enable_csr": false/' config/vpu_config.json
    echo "CSR module: DISABLED"
fi

# Regenerate package
python3 scripts/gen_pkg.py

# Show current config
echo ""
echo "Current config:"
grep -E '"VLEN"|"DLEN"|"enable_csr"' config/vpu_config.json | sed 's/^/  /'
