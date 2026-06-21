#!/system/bin/sh
MODDIR="/data/adb/modules/sweet_dreams"
CORTEX="$MODDIR/cortex"
BIN="$MODDIR/bin"
STATUS=$(cat "$CORTEX/thermal/status.txt" 2>/dev/null || echo "disabled")
MODE=$(cat "$CORTEX/thermal/mode.txt" 2>/dev/null || echo "extreme")

run_bg() {
    local b="$BIN/$1"
    [ -f "$b" ] && chmod 0755 "$b" && nohup "$b" >/dev/null 2>&1 &
}

if [ "$STATUS" = "disabled" ]; then
    for tz in /sys/class/thermal/thermal_zone*/mode; do
        echo "disabled" > "$tz" 2>/dev/null
    done
    stop thermal-engine 2>/dev/null
    stop thermal_manager 2>/dev/null
    stop thermalloadalgod 2>/dev/null
    stop mi_thermald 2>/dev/null
    pm suspend --user 0 com.mediatek.thermal 2>/dev/null || \
    pm disable-user --user 0 com.mediatek.thermal 2>/dev/null
    resetprop persist.thermal.enable 0 2>/dev/null
    resetprop vendor.thermal.manager 0 2>/dev/null
    resetprop vendor.thermal.link_ready 0 2>/dev/null
    case "$MODE" in
        extreme) run_bg "lgtl-thermal-extreme" ;;
        lite)    run_bg "lgtl-thermal-lite" ;;
    esac
else
    for tz in /sys/class/thermal/thermal_zone*/mode; do
        echo "enabled" > "$tz" 2>/dev/null
    done
    start thermal-engine 2>/dev/null
    resetprop persist.thermal.enable 1 2>/dev/null
    run_bg "lgtl-thermal-backup"
fi
