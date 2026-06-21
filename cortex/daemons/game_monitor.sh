#!/system/bin/sh
MODDIR="/data/adb/modules/sweet_dreams"
CORTEX="$MODDIR/cortex"
LOGFILE="$MODDIR/boot.log"
RUNDIR="$MODDIR/run"
mkdir -p "$RUNDIR"
echo "$$" > "$RUNDIR/game_monitor.pid"

log_p() { echo "[$(date '+%H:%M:%S')] $1" >> "$LOGFILE"; }

HAS_SCHEDTUNE=0
[ -e /dev/stune/top-app/schedtune.boost ] && HAS_SCHEDTUNE=1
HAS_PPM=0
[ -e /proc/ppm/policy/hard_userlimit_min_cpu_freq ] && HAS_PPM=1
HAS_UCLAMP=0
[ -e /dev/cpuctl/top-app/cpu.uclamp.min ] && HAS_UCLAMP=1
log_p "Capability probe: schedtune=$HAS_SCHEDTUNE ppm=$HAS_PPM uclamp=$HAS_UCLAMP"

enforce_cpu_floor() {
    local P="$1"
    [ "$P" = "battery" ] && return
    for i in 0 1 2 3 4 5; do
        echo "1800000" > /sys/devices/system/cpu/cpu${i}/cpufreq/scaling_min_freq 2>/dev/null
    done
    for i in 6 7; do
        echo "2000000" > /sys/devices/system/cpu/cpu${i}/cpufreq/scaling_min_freq 2>/dev/null
        echo "2200000" > /sys/devices/system/cpu/cpu${i}/cpufreq/scaling_max_freq 2>/dev/null
    done
    if [ "$HAS_PPM" = "1" ]; then
        echo "0 1800000" > /proc/ppm/policy/hard_userlimit_min_cpu_freq 2>/dev/null
        echo "1 2000000" > /proc/ppm/policy/hard_userlimit_min_cpu_freq 2>/dev/null
    fi
}

boost_pids() {
    local PKG="$1"
    for PID in $(pidof "$PKG" 2>/dev/null); do
        echo "-1000" > /proc/$PID/oom_score_adj    2>/dev/null
        echo "0"     > /proc/$PID/timerslack_ns    2>/dev/null
        echo "$PID"  > /dev/cpuset/top-app/tasks   2>/dev/null
        if [ "$HAS_SCHEDTUNE" = "1" ]; then
            echo "100" > /dev/stune/top-app/schedtune.boost       2>/dev/null
            echo "1"   > /dev/stune/top-app/schedtune.prefer_idle 2>/dev/null
        fi
        if [ "$HAS_UCLAMP" = "1" ]; then
            echo "max" > /dev/cpuctl/top-app/cpu.uclamp.min 2>/dev/null
        fi
    done
}

lock_rr() {
    local T="$1"
    settings put system peak_refresh_rate "$T" 2>/dev/null
    settings put system min_refresh_rate  "$T" 2>/dev/null
    resetprop ro.surface_flinger.use_content_detection_for_refresh_rate false 2>/dev/null
    resetprop debug.sf.use_content_detection_for_refresh_rate false            2>/dev/null
    resetprop persist.sys.disable_rrs 1                                        2>/dev/null
}

unlock_rr() {
    local T="$1"
    settings put system peak_refresh_rate "$T" 2>/dev/null
    settings put system min_refresh_rate  60   2>/dev/null
    resetprop ro.surface_flinger.use_content_detection_for_refresh_rate true 2>/dev/null
    resetprop debug.sf.use_content_detection_for_refresh_rate true           2>/dev/null
    resetprop persist.sys.disable_rrs 0                                      2>/dev/null
}

enforce_fps_lock() {
    local CAP="$1"
    sh "$CORTEX/fps/engine.sh" "$CAP" game 2>/dev/null
    service call SurfaceFlinger 1035 i32 "$CAP" 2>/dev/null
    echo "$CAP" > /sys/kernel/debug/mtk_mira/fps_limit       2>/dev/null
    echo "$CAP" > /proc/perfmgr/legacy/perfserv_ta            2>/dev/null
    case "$CAP" in
        30)  echo "180000000" > /proc/gpufreq/gpufreq_opp_freq 2>/dev/null ;;
        45)  echo "280000000" > /proc/gpufreq/gpufreq_opp_freq 2>/dev/null ;;
        60)  echo "360000000" > /proc/gpufreq/gpufreq_opp_freq 2>/dev/null ;;
        90)  echo "530000000" > /proc/gpufreq/gpufreq_opp_freq 2>/dev/null ;;
        120) echo "680000000" > /proc/gpufreq/gpufreq_opp_freq 2>/dev/null ;;
    esac
}

release_fps_lock() {
    local T="$1"
    sh "$CORTEX/fps/engine.sh" restore 2>/dev/null
    service call SurfaceFlinger 1035 i32 0 2>/dev/null
    echo "0" > /proc/gpufreq/gpufreq_opp_freq 2>/dev/null
}

restore_cpu() {
    [ "$HAS_PPM" = "1" ] && echo "0" > /proc/ppm/policy/hard_userlimit_min_cpu_freq 2>/dev/null
    sh "$CORTEX/cpu/apply.sh" 2>/dev/null
    if [ "$HAS_SCHEDTUNE" = "1" ]; then
        echo "0" > /dev/stune/top-app/schedtune.boost       2>/dev/null
        echo "0" > /dev/stune/top-app/schedtune.prefer_idle 2>/dev/null
    fi
}

LAST_GAME=""
LOOP_ITER=0

while true; do
    SELECTED=$(cat "$CORTEX/games/selected.txt" 2>/dev/null || echo "")
    PROFILE=$(cat "$CORTEX/cpu/profile.txt"         2>/dev/null || echo "gaming")
    RR_LOCK=$(cat "$CORTEX/display/rr_lock.txt"     2>/dev/null || echo "off")
    FPS_LOCK=$(cat "$CORTEX/display/fps_lock_game.txt" 2>/dev/null || echo "off")
    TARGET_FPS=$(cat "$CORTEX/display/fps.txt"      2>/dev/null || echo "90")
    KILL_BG=$(cat "$CORTEX/games/kill_bg_enabled.txt"    2>/dev/null || echo "off")
    NET_BLOCK=$(cat "$CORTEX/games/restrict_net_enabled.txt" 2>/dev/null || echo "off")

    RUNNING_GAME=""
    for PKG in $SELECTED; do
        pidof "$PKG" >/dev/null 2>&1 && RUNNING_GAME="$PKG" && break
    done

    if [ -n "$RUNNING_GAME" ]; then

        if [ "$RUNNING_GAME" != "$LAST_GAME" ]; then
            log_p "Game ON: $RUNNING_GAME"
            [ "$KILL_BG"   = "on" ] && sh "$CORTEX/games/kill_bg.sh" "$RUNNING_GAME" 2>/dev/null
            [ "$NET_BLOCK" = "on" ] && sh "$CORTEX/games/restrict_net.sh" "$RUNNING_GAME" on 2>/dev/null
            PERF_EN=$(cat "$CORTEX/perf/enabled.txt" 2>/dev/null || echo "on")
            [ "$PERF_EN" = "on" ] && sh "$CORTEX/perf/apply.sh" "$RUNNING_GAME" boost 2>/dev/null
            SENSOR_EN=$(cat "$CORTEX/sensor/enabled.txt" 2>/dev/null || echo "off")
            [ "$SENSOR_EN" = "on" ] && sh "$CORTEX/sensor/apply.sh" game 2>/dev/null
            AUDIO_EN=$(cat "$CORTEX/audio/enabled.txt" 2>/dev/null || echo "off")
            [ "$AUDIO_EN" = "on" ] && sh "$CORTEX/audio/apply.sh" 2>/dev/null
            GAME_LABEL=$(echo "$RUNNING_GAME" | awk -F. '{print $NF}')
            PROFILE_NOW=$(cat "$CORTEX/cpu/profile.txt" 2>/dev/null || echo "gaming")
            sh "$CORTEX/notify/post.sh" game_launch "Sweet Dreams" \
                "Boost active for ${GAME_LABEL} — ${TARGET_FPS}fps · ${PROFILE_NOW} profile" 2>/dev/null
            LAST_GAME="$RUNNING_GAME"
            LOOP_ITER=0
        fi

        boost_pids "$RUNNING_GAME"

        enforce_cpu_floor "$PROFILE"

        if [ "$RR_LOCK" = "game" ] || [ "$RR_LOCK" = "locked" ]; then
            lock_rr "$TARGET_FPS"
            echo "rr_locked_ingame" > "$CORTEX/display/rr_status.txt"
        fi

        if [ "$FPS_LOCK" != "off" ]; then
            enforce_fps_lock "$FPS_LOCK"
            echo "fps_locked_${FPS_LOCK}" > "$CORTEX/display/rr_status.txt"
        fi

        LOOP_ITER=$((LOOP_ITER + 1))

        sleep 2

    else
        if [ -n "$LAST_GAME" ]; then
            log_p "Game OFF: $LAST_GAME"
            [ "$NET_BLOCK" = "on" ] && sh "$CORTEX/games/restrict_net.sh" "$LAST_GAME" off 2>/dev/null
            unlock_rr "$TARGET_FPS"
            release_fps_lock "$TARGET_FPS"
            restore_cpu
            sh "$CORTEX/perf/apply.sh" "" restore 2>/dev/null
            sh "$CORTEX/sensor/apply.sh" restore 2>/dev/null
            sh "$CORTEX/audio/apply.sh" restore 2>/dev/null
            echo "rr_game_idle" > "$CORTEX/display/rr_status.txt"
            GAME_LABEL_OFF=$(echo "$LAST_GAME" | awk -F. '{print $NF}')
            sh "$CORTEX/notify/post.sh" game_exit "Sweet Dreams" \
                "Boost released for ${GAME_LABEL_OFF} — back to ${PROFILE} profile" 2>/dev/null
            LAST_GAME=""
            LOOP_ITER=0
        fi
        sleep 5
    fi
done
