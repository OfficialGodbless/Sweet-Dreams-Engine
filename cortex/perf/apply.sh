#!/system/bin/sh
CORTEX="/data/adb/modules/sweet_dreams/cortex"

GAME_PKG="$1"
ACTION="${2:-boost}"

log_perf() { echo "[PERF] $1"; }

trigger_perf_scenario() {
    local SCENARIO="$1"
    echo "$SCENARIO" > /proc/perfmgr/legacy/perfserv_ta 2>/dev/null && \
        log_perf "perfserv_ta=$SCENARIO" && return
    echo "$SCENARIO" > /proc/perfmgr/perf_ioctl 2>/dev/null
    echo "1" > /sys/devices/system/cpu/perf_boost_enable 2>/dev/null
}

set_dvfs_headroom() {
    local PCT="$1"
    echo "$PCT" > /sys/module/mtk_freq_bound/parameters/ut_freq_bound 2>/dev/null
    echo "$PCT" > /proc/mtk_dvfs/ut_headroom 2>/dev/null
}

set_eas_hint() {
    local STATE="$1"
    echo "$STATE" > /sys/kernel/eas/game_hint 2>/dev/null
    echo "$STATE" > /proc/mtk_eas/game_mode   2>/dev/null
}

set_gpu_game_mode() {
    local STATE="$1"
    echo "$STATE" > /sys/class/misc/mali0/device/devfreq/mali0/mali_ondemand_game_mode 2>/dev/null
    echo "$STATE" > /sys/class/misc/mali0/device/power_policy 2>/dev/null
    echo "$STATE" > /sys/class/misc/mali0/device/highfreq_hint 2>/dev/null
}

case "$ACTION" in
    boost)
        log_perf "Game boost: ${GAME_PKG:-unknown}"
        trigger_perf_scenario 2
        set_dvfs_headroom 15
        set_eas_hint 1
        set_gpu_game_mode 1
        echo "boost" > "$CORTEX/perf/state.txt"
        ;;
    restore)
        log_perf "Restoring perf state"
        trigger_perf_scenario 0
        set_dvfs_headroom 0
        set_eas_hint 0
        set_gpu_game_mode 0
        echo "idle" > "$CORTEX/perf/state.txt"
        ;;
esac
