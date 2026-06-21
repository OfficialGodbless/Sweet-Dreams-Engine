#!/system/bin/sh

MODDIR="/data/adb/modules/sweet_dreams"
CORTEX="$MODDIR/cortex"
FPS_CFG="$CORTEX/fps"
FRPERF="/data/local/tmp/Frieren_Perf"
BACKUP_FILE="$FRPERF/fps_backup/refresh_rate.txt"

ARG1="$1"
ARG2="$2"

log_fps() { echo "[FPS] $1"; }

get_foreground_package() {
    dumpsys activity activities 2>/dev/null \
        | grep -E "topResumedActivity|ResumedActivity" \
        | head -1 \
        | grep -oE '[a-zA-Z0-9_.]+/[a-zA-Z0-9_.]+' \
        | head -1 \
        | cut -d/ -f1
}

backup_refresh_rate() {
    [ -f "$BACKUP_FILE" ] && return
    mkdir -p "$FRPERF/fps_backup"
    {
        settings get system peak_refresh_rate 2>/dev/null
        settings get system min_refresh_rate  2>/dev/null
    } > "$BACKUP_FILE" 2>/dev/null
}

apply_frame_pacing() {
    local FPS="$1"

    resetprop debug.sf.early_phase_offset_ns          500000  2>/dev/null
    resetprop debug.sf.early_app_phase_offset_ns       500000  2>/dev/null
    resetprop debug.sf.early_gl_phase_offset_ns        3000000 2>/dev/null
    resetprop debug.sf.high_fps_early_phase_offset_ns  500000  2>/dev/null
    resetprop debug.sf.high_fps_late_app_phase_offset_ns 500000 2>/dev/null
    resetprop debug.sf.late_app_phase_offset_ns        500000  2>/dev/null
    resetprop debug.sf.use_phase_offsets_as_durations  1       2>/dev/null
    resetprop debug.sf.enable_frame_rate_pacing        1       2>/dev/null
    resetprop debug.sf.disable_backpressure            1       2>/dev/null
    resetprop debug.sf.enable_gl_backpressure           0       2>/dev/null
    resetprop debug.sf.latch_unsignaled                 1       2>/dev/null
    resetprop debug.sf.predict_hwc_composition_strategy 1       2>/dev/null
    resetprop debug.sf.enable_hwc_vds                   0       2>/dev/null

    resetprop debug.hwui.render_thread          1     2>/dev/null
    resetprop debug.hwui.use_partial_updates    true  2>/dev/null
    resetprop debug.hwui.use_buffer_age         true  2>/dev/null
    resetprop debug.hwui.skip_empty_damage      true  2>/dev/null
    resetprop debug.hwui.render_dirty_regions   true  2>/dev/null
    resetprop debug.hwui.enable_frame_rate_limit "$FPS" 2>/dev/null
    resetprop debug.hwui.fps_divisor            1     2>/dev/null

    resetprop debug.input.low_latency  true 2>/dev/null
    resetprop touch.pressure.scale     1.0  2>/dev/null
    resetprop windowsmgr.max_events_per_sec "$FPS" 2>/dev/null
    if [ -d /sys/module/cpu_boost/parameters ]; then
        echo "1"  > /sys/module/cpu_boost/parameters/input_boost_enabled     2>/dev/null
        echo "40" > /sys/module/cpu_boost/parameters/input_boost_ms          2>/dev/null
        echo "40" > /sys/module/cpu_boost/parameters/dynamic_stune_boost_ms  2>/dev/null
    fi

    sysctl -w kernel.sched_child_runs_first=0    2>/dev/null
    sysctl -w kernel.sched_latency_ns=6000000    2>/dev/null
    sysctl -w kernel.sched_migration_cost_ns=5000000 2>/dev/null
    [ -e /proc/sys/kernel/sched_cfs_boost ] && echo "1" > /proc/sys/kernel/sched_cfs_boost 2>/dev/null

    resetprop debug.egl.swapinterval -1 2>/dev/null
    settings put system peak_refresh_rate "$FPS" 2>/dev/null

    resetprop persist.vendor.powerhal.adpf 1            2>/dev/null
    resetprop persist.vendor.powerhal.fpsstabilizer "$FPS" 2>/dev/null
    cmd game mode performance "$(get_foreground_package)" 2>/dev/null

    log_fps "Frame pacing applied for ${FPS} fps"
}

apply_adpf_overlay() {
    local FPS="$1"
    local PKG
    PKG=$(get_foreground_package)
    [ -z "$PKG" ] && return
    device_config put game_overlay "$PKG" "mode=2,fps=${FPS}" 2>/dev/null
    log_fps "ADPF game overlay: ${PKG} @ ${FPS} fps"
}

restore_defaults() {
    for P in \
        debug.sf.early_phase_offset_ns debug.sf.early_app_phase_offset_ns \
        debug.sf.early_gl_phase_offset_ns debug.sf.high_fps_early_phase_offset_ns \
        debug.sf.high_fps_late_app_phase_offset_ns debug.sf.late_app_phase_offset_ns \
        debug.sf.use_phase_offsets_as_durations debug.sf.enable_frame_rate_pacing \
        debug.sf.disable_backpressure debug.sf.enable_gl_backpressure \
        debug.sf.latch_unsignaled debug.sf.predict_hwc_composition_strategy \
        debug.sf.enable_hwc_vds debug.hwui.render_thread debug.hwui.use_partial_updates \
        debug.hwui.use_buffer_age debug.hwui.skip_empty_damage debug.hwui.render_dirty_regions \
        debug.hwui.enable_frame_rate_limit debug.hwui.fps_divisor debug.input.low_latency \
        touch.pressure.scale windowsmgr.max_events_per_sec debug.egl.swapinterval \
        persist.vendor.powerhal.adpf persist.vendor.powerhal.fpsstabilizer; do
        resetprop --delete "$P" 2>/dev/null
    done

    [ -d /sys/module/cpu_boost/parameters ] && echo "0" > /sys/module/cpu_boost/parameters/input_boost_enabled 2>/dev/null
    sysctl -w kernel.sched_child_runs_first=1 2>/dev/null

    cmd game mode standard "$(get_foreground_package)" 2>/dev/null

    if [ -f "$BACKUP_FILE" ]; then
        local PEAK MIN
        PEAK=$(sed -n '1p' "$BACKUP_FILE" 2>/dev/null)
        MIN=$(sed -n '2p' "$BACKUP_FILE" 2>/dev/null)
        [ -n "$PEAK" ] && settings put system peak_refresh_rate "$PEAK" 2>/dev/null
        [ -n "$MIN" ]  && settings put system min_refresh_rate  "$MIN"  2>/dev/null
    fi

    log_fps "Restored to defaults"
}

case "$ARG1" in
    restore)
        restore_defaults
        ;;
    ''|*[!0-9]*)
        echo "Usage: engine.sh <fps 1-240> [game] | restore" >&2
        exit 1
        ;;
    *)
        if [ "$ARG1" -lt 1 ] || [ "$ARG1" -gt 240 ]; then
            log_fps "Invalid FPS ($ARG1), ignoring"
            exit 1
        fi
        backup_refresh_rate
        apply_frame_pacing "$ARG1"
        [ "$ARG2" = "game" ] && apply_adpf_overlay "$ARG1"
        ;;
esac
