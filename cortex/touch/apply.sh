#!/system/bin/sh
CORTEX="/data/adb/modules/sweet_dreams/cortex"
STATUS=$(cat "$CORTEX/touch/status.txt" 2>/dev/null || echo "on")

if [ "$STATUS" = "on" ]; then
    IB=$(cat "$CORTEX/touch/input_booster.txt" 2>/dev/null || echo "on")
    IB_VAL=$([ "$IB" = "on" ] && echo "1" || echo "0")
    for p in \
        /sys/module/mtk_ib/parameters/enable \
        /sys/module/mtk_input_booster/parameters/enabled; do
        [ -f "$p" ] && echo "$IB_VAL" > "$p" 2>/dev/null
    done

    SWIPE=$(cat "$CORTEX/touch/swipe_px.txt" 2>/dev/null || echo "8")
    for p in /sys/module/mtk_tpd/parameters/tpd_filter_pixel_num; do
        [ -f "$p" ] && echo "$SWIPE" > "$p" 2>/dev/null
    done

    RATE=$(cat "$CORTEX/touch/report_rate.txt" 2>/dev/null || echo "240")
    for p in \
        /sys/bus/i2c/devices/*/report_rate \
        /proc/touchpanel/report_rate \
        /sys/kernel/tpd/report_rate; do
        [ -f "$p" ] && echo "$RATE" > "$p" 2>/dev/null
    done

    NFILTER=$(cat "$CORTEX/touch/noise_filter.txt" 2>/dev/null || echo "off")
    NF_VAL=$([ "$NFILTER" = "on" ] && echo "1" || echo "0")
    for p in \
        /sys/module/touch_filter/parameters/enable \
        /proc/touchpanel/noise_filter; do
        [ -f "$p" ] && echo "$NF_VAL" > "$p" 2>/dev/null
    done

    TAPSENS=$(cat "$CORTEX/touch/tap_sens.txt" 2>/dev/null || echo "medium")
    case "$TAPSENS" in
        low)    TAP_V=8  ;;
        medium) TAP_V=4  ;;
        high)   TAP_V=2  ;;
    esac
    for p in /sys/module/mtk_tpd/parameters/tpd_calibrate_variance; do
        [ -f "$p" ] && echo "$TAP_V" > "$p" 2>/dev/null
    done
fi
