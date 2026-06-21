#!/system/bin/sh

CORTEX="/data/adb/modules/sweet_dreams/cortex"
SPOOF_CONF="$CORTEX/games/spoof_assignments.txt"

restore_props() {
    resetprop ro.product.brand        "$(getprop ro.product.vendor.brand)"        2>/dev/null
    resetprop ro.product.manufacturer "$(getprop ro.product.vendor.manufacturer)" 2>/dev/null
    resetprop ro.product.model        "$(getprop ro.product.vendor.model)"        2>/dev/null
    resetprop ro.product.device       "$(getprop ro.product.vendor.device)"       2>/dev/null
    resetprop ro.product.name         "$(getprop ro.product.vendor.name)"         2>/dev/null
    resetprop ro.build.fingerprint    "$(getprop ro.vendor.build.fingerprint)"    2>/dev/null
    echo "[spoof] Props restored to real device"
}

set_props() {
    resetprop ro.product.brand        "$1" 2>/dev/null
    resetprop ro.product.manufacturer "$2" 2>/dev/null
    resetprop ro.product.model        "$3" 2>/dev/null
    resetprop ro.product.device       "$4" 2>/dev/null
    resetprop ro.product.name         "$5" 2>/dev/null
    resetprop ro.build.fingerprint    "$6" 2>/dev/null
    echo "[spoof] Props set → $1 $3"
}

MASTER=$(cat "$CORTEX/games/spoof_master.txt" 2>/dev/null || echo "off")
if [ "$MASTER" != "on" ]; then
    restore_props
    exit 0
fi

DEVICE=""
if [ -f "$SPOOF_CONF" ]; then
    while IFS='|' read -r PKG DEV; do
        PKG=$(printf '%s' "$PKG" | tr -d ' \r\n')
        DEV=$(printf '%s' "$DEV" | tr -d ' \r\n')
        [ -n "$PKG" ] && [ -n "$DEV" ] && [ "$DEV" != "off" ] && DEVICE="$DEV" && break
    done < "$SPOOF_CONF"
fi

case "$DEVICE" in
    legion)
        set_props "Lenovo" "Lenovo" "TB-9707F" "TB-9707F" "TB-9707F" \
            "Lenovo/TB-9707F/Lenovo TB-9707F:13/TQ3A.230805.001/20230901:user/release-keys"
        ;;
    redmagic)
        set_props "REDMAGIC" "Nubia" "NX809J" "NX809J" "NX809J" \
            "REDMAGIC/NX809J-UN/NX809J:16/BP2A.250605.031.A3/20251017.000000:user/release-keys"
        ;;
    redmagic9)
        set_props "nubia" "ZTE" "NX769J" "NX769J" "NX769J" \
            "nubia/NX769J/NX769J:14/UKQ1.230917.001/20240813.173312:user/release-keys"
        ;;
    rog)
        set_props "ASUS" "ASUS" "AI2203" "AI2203" "AI2203" \
            "ASUS/AI2203/ROG Phone 6D:14/UP1A.231005.007/20240315:user/release-keys"
        ;;
    blackshark)
        set_props "Black Shark" "Xiaomi" "2SM-X706B" "PRS-H0" "2SM-X706B" \
            "BlackShark/PRS-H0/Black Shark 4:13/TQ3A.230805.001/20230315:user/release-keys"
        ;;
    oneplus)
        set_props "OnePlus" "OnePlus" "PJZ110" "OP5D0DL1" "PJZ110" \
            "OnePlus/PJZ110/OP5D0DL1:15/AP3A.240617.008/V.1bd19a1-1-2:user/release-keys"
        ;;
    samsung)
        set_props "samsung" "samsung" "SM-F9460" "q2q" "q2qzh" \
            "samsung/q2qzh/q2q:15/UP1A.231005.007/F946BXXU1BWK4:user/release-keys"
        ;;
    *)
        restore_props
        ;;
esac
