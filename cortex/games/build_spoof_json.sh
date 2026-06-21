#!/system/bin/sh

CORTEX="/data/adb/modules/sweet_dreams/cortex"
MODDIR="/data/adb/modules/sweet_dreams"
SPOOF_CONF="$CORTEX/games/spoof_assignments.txt"
OUT="$MODDIR/COPG.json"
TMP="${OUT}.tmp"

device_profile_name() {
    case "$1" in
        legion)      echo "LEGION_Y700_2023" ;;
        redmagic)    echo "REDMAGIC_11_PRO" ;;
        redmagic9)   echo "REDMAGIC_9_PRO" ;;
        rog)         echo "ROG_PHONE_6D_ULTIMATE" ;;
        blackshark)  echo "BLACK_SHARK_4" ;;
        oneplus)     echo "ONEPLUS_13" ;;
        samsung)     echo "GALAXY_Z_FOLD_5" ;;
    esac
}

device_block_json() {
    case "$1" in
        legion)
            cat <<'BLOCK'
    "BRAND": "Lenovo",
    "DEVICE": "TB-9707F",
    "MANUFACTURER": "Lenovo",
    "MODEL": "TB-9707F",
    "FINGERPRINT": "Lenovo/TB-9707F/Lenovo TB-9707F:13/TQ3A.230805.001/20230901:user/release-keys",
    "PRODUCT": "TB-9707F",
    "SDK_INT": 33,
    "ANDROID_VERSION": "13"
BLOCK
            ;;
        redmagic)
            cat <<'BLOCK'
    "BRAND": "REDMAGIC",
    "DEVICE": "NX809J",
    "MANUFACTURER": "Nubia",
    "MODEL": "NX809J",
    "FINGERPRINT": "REDMAGIC/NX809J-UN/NX809J:16/BP2A.250605.031.A3/20251017.000000:user/release-keys",
    "PRODUCT": "NX809J",
    "SDK_INT": 36,
    "ANDROID_VERSION": "16"
BLOCK
            ;;
        redmagic9)
            cat <<'BLOCK'
    "BRAND": "nubia",
    "DEVICE": "NX769J",
    "MANUFACTURER": "ZTE",
    "MODEL": "NX769J",
    "FINGERPRINT": "nubia/NX769J/NX769J:14/UKQ1.230917.001/20240813.173312:user/release-keys",
    "PRODUCT": "NX769J",
    "SDK_INT": 34,
    "ANDROID_VERSION": "14"
BLOCK
            ;;
        rog)
            cat <<'BLOCK'
    "BRAND": "ASUS",
    "DEVICE": "AI2203",
    "MANUFACTURER": "ASUS",
    "MODEL": "AI2203",
    "FINGERPRINT": "ASUS/AI2203/ROG Phone 6D:14/UP1A.231005.007/20240315:user/release-keys",
    "PRODUCT": "AI2203",
    "SDK_INT": 34,
    "ANDROID_VERSION": "14"
BLOCK
            ;;
        blackshark)
            cat <<'BLOCK'
    "BRAND": "Black Shark",
    "DEVICE": "PRS-H0",
    "MANUFACTURER": "Xiaomi",
    "MODEL": "2SM-X706B",
    "FINGERPRINT": "BlackShark/PRS-H0/Black Shark 4:13/TQ3A.230805.001/20230315:user/release-keys",
    "PRODUCT": "2SM-X706B",
    "SDK_INT": 33,
    "ANDROID_VERSION": "13"
BLOCK
            ;;
        oneplus)
            cat <<'BLOCK'
    "BRAND": "OnePlus",
    "DEVICE": "OP5D0DL1",
    "MANUFACTURER": "OnePlus",
    "MODEL": "PJZ110",
    "FINGERPRINT": "OnePlus/PJZ110/OP5D0DL1:15/AP3A.240617.008/V.1bd19a1-1-2:user/release-keys",
    "PRODUCT": "PJZ110",
    "SDK_INT": 35,
    "ANDROID_VERSION": "15"
BLOCK
            ;;
        samsung)
            cat <<'BLOCK'
    "BRAND": "samsung",
    "DEVICE": "q2q",
    "MANUFACTURER": "samsung",
    "MODEL": "SM-F9460",
    "FINGERPRINT": "samsung/q2qzh/q2q:15/UP1A.231005.007/F946BXXU1BWK4:user/release-keys",
    "PRODUCT": "q2qzh",
    "SDK_INT": 35,
    "ANDROID_VERSION": "15"
BLOCK
            ;;
    esac
}

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

if [ -f "$SPOOF_CONF" ]; then
    while IFS='|' read -r PKG DEVICE; do
        PKG=$(printf '%s' "$PKG" | tr -d ' \r\n')
        DEVICE=$(printf '%s' "$DEVICE" | tr -d ' \r\n')
        [ -z "$PKG" ] || [ -z "$DEVICE" ] && continue
        case "$DEVICE" in
            legion|redmagic|redmagic9|rog|blackshark|oneplus|samsung) ;;
            *) continue ;;
        esac
        echo "$PKG" >> "$WORKDIR/$DEVICE.pkgs"
    done < "$SPOOF_CONF"
fi

{
    printf '{\n'
    printf '  "cpu_spoof": {\n'
    printf '    "blacklist": [],\n'
    printf '    "cpu_only_packages": []\n'
    printf '  }'

    for DEVICE in legion redmagic redmagic9 rog blackshark oneplus samsung; do
        [ -f "$WORKDIR/$DEVICE.pkgs" ] || continue
        NAME=$(device_profile_name "$DEVICE")
        [ -z "$NAME" ] && continue

        UNIQ_PKGS=$(awk '!seen[$0]++' "$WORKDIR/$DEVICE.pkgs")

        printf ',\n  "PACKAGES_%s": [\n' "$NAME"
        FIRST=1
        while IFS= read -r P; do
            [ -z "$P" ] && continue
            if [ "$FIRST" = "1" ]; then
                printf '    "%s"' "$P"
                FIRST=0
            else
                printf ',\n    "%s"' "$P"
            fi
        done <<EOF2
$UNIQ_PKGS
EOF2
        printf '\n  ],\n'

        printf '  "PACKAGES_%s_DEVICE": {\n' "$NAME"
        device_block_json "$DEVICE"
        printf '\n  }'
    done

    printf '\n}\n'
} > "$TMP"

if [ -s "$TMP" ] && grep -q '"cpu_spoof"' "$TMP" && grep -q '^{' "$TMP"; then
    mv -f "$TMP" "$OUT"
    chmod 0644 "$OUT" 2>/dev/null
    chcon u:object_r:system_file:s0 "$OUT" 2>/dev/null
    ENTRY_COUNT=$(grep -c '"PACKAGES_[A-Z0-9_]*": \[' "$OUT" 2>/dev/null || echo 0)
    echo "[spoof] COPG.json built OK - ${ENTRY_COUNT} device profile(s)"
else
    rm -f "$TMP"
    echo "[spoof] ERROR: JSON build failed, keeping previous COPG.json"
    exit 1
fi
