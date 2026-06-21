#!/system/bin/sh
MODDIR="/data/adb/modules/sweet_dreams"
CORTEX="$MODDIR/cortex"
LOGFILE="$MODDIR/boot.log"
FRPERF="/data/local/tmp/Frieren_Perf"

rm -f "$LOGFILE"
log_p() { echo "[$(date '+%H:%M:%S')] $1" >> "$LOGFILE"; }

until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 2; done

WAIT_TRIES=0
while [ "$WAIT_TRIES" -lt 20 ]; do
    SETTINGS_OK=0; PACKAGE_OK=0; GAME_OK=0
    cmd settings get global airplane_mode_on >/dev/null 2>&1 && SETTINGS_OK=1
    pm path android >/dev/null 2>&1 && PACKAGE_OK=1
    cmd game list >/dev/null 2>&1 && GAME_OK=1
    if [ "$SETTINGS_OK" = "1" ] && [ "$PACKAGE_OK" = "1" ] && [ "$GAME_OK" = "1" ]; then
        break
    fi
    sleep 1
    WAIT_TRIES=$((WAIT_TRIES + 1))
done
sleep 1
log_p "Early binder readiness: settings=$SETTINGS_OK package=$PACKAGE_OK game=$GAME_OK (waited ${WAIT_TRIES}s)"

log_p "Boot — Sweet Dreams v1.8.0"

find "$MODDIR/system/bin" -type f ! -name "*.txt" ! -name "*.webp" -exec chmod 0755 {} \;
find "$MODDIR/bin" -type f -exec chmod 0755 {} \;
find "$CORTEX" -name "*.sh" -exec chmod 0755 {} \;
chmod 0755 "$MODDIR/controller" 2>/dev/null
chmod 0644 "$MODDIR/COPG.json" 2>/dev/null
chcon u:object_r:system_file:s0 "$MODDIR/COPG.json" 2>/dev/null

mkdir -p "$FRPERF/fps_backup"
mkdir -p "/data/local/tmp/frieren_render/backup"
echo "on" > "$FRPERF/ai.txt"
cp "$MODDIR/system/bin/gamelist.txt" "$FRPERF/gamelist.txt" 2>/dev/null

sh "$CORTEX/thermal/apply.sh"  >> "$LOGFILE" 2>&1 && log_p "Thermal done"
sh "$CORTEX/cpu/apply.sh"      >> "$LOGFILE" 2>&1 && log_p "CPU done"
sh "$CORTEX/gpu/apply.sh"      >> "$LOGFILE" 2>&1 && log_p "GPU done"
sh "$CORTEX/net/apply.sh"      >> "$LOGFILE" 2>&1 && log_p "Net done"
sh "$CORTEX/sched/apply.sh"    >> "$LOGFILE" 2>&1 && log_p "Sched done"

ARCH=$(uname -m)
case "$ARCH" in
    aarch64) "$MODDIR/bin/RTI--aarch64" >> "$LOGFILE" 2>&1 ;;
    arm*|aarch32) "$MODDIR/bin/RTI--arm" >> "$LOGFILE" 2>&1 ;;
esac
log_p "Touch daemon done"

sh "$CORTEX/chipset/engine.sh" activate >> "$LOGFILE" 2>&1
log_p "Chipset tuning done"

TARGET_FPS=$(cat "$CORTEX/display/fps.txt" 2>/dev/null || echo "90")
sh "$CORTEX/fps/engine.sh" "$TARGET_FPS" >> "$LOGFILE" 2>&1
log_p "FPS engine done"

SPOOF_ON=$(cat "$CORTEX/games/spoof_master.txt" 2>/dev/null || echo "off")
if [ "$SPOOF_ON" = "on" ]; then
    sh "$CORTEX/games/build_spoof_json.sh" >> "$LOGFILE" 2>&1
    log_p "Spoof JSON built"
    sh "$CORTEX/games/spoof.sh" >> "$LOGFILE" 2>&1
    log_p "Global prop spoof applied"
    pkill -f "$MODDIR/controller" 2>/dev/null
    sleep 1
    nohup "$MODDIR/controller" > /dev/null 2>&1 &
    log_p "LGTL Spoof Engine PID $!"
else
    sh "$CORTEX/games/spoof.sh" >> "$LOGFILE" 2>&1
fi

until [ "$(getprop init.svc.bootanim)" = "stopped" ]; do sleep 2; done
sleep 5
log_p "System settled"

WAIT=0
while [ "$WAIT" -lt 20 ]; do
    S_OK=0; W_OK=0; A_OK=0; G_OK=0
    cmd settings get global airplane_mode_on >/dev/null 2>&1 && S_OK=1
    dumpsys window displays >/dev/null 2>&1 && W_OK=1
    dumpsys activity activities >/dev/null 2>&1 && A_OK=1
    cmd game list >/dev/null 2>&1 && G_OK=1
    if [ "$S_OK" = "1" ] && [ "$W_OK" = "1" ] && [ "$A_OK" = "1" ] && [ "$G_OK" = "1" ]; then
        break
    fi
    sleep 1
    WAIT=$((WAIT + 1))
done
log_p "Binder readiness: settings=$S_OK window=$W_OK activity=$A_OK game=$G_OK (waited ${WAIT}s)"

settings put system pointer_speed 0 2>/dev/null
settings put secure long_press_timeout "$(cat "$CORTEX/touch/lp_timeout.txt" 2>/dev/null || echo 400)" 2>/dev/null
settings put secure multi_press_timeout 300 2>/dev/null
settings put system peak_refresh_rate "$TARGET_FPS" 2>/dev/null
settings put system min_refresh_rate 60 2>/dev/null
log_p "System settings applied"

ANIM=$(cat "$CORTEX/display/anim_scale.txt" 2>/dev/null || echo "0.5")
settings put global window_animation_scale "$ANIM" 2>/dev/null
settings put global transition_animation_scale "$ANIM" 2>/dev/null
settings put global animator_duration_scale "$ANIM" 2>/dev/null

log_p "Display done"

sh "$CORTEX/touch/apply.sh" >> "$LOGFILE" 2>&1 && log_p "Touch done"

sh "$CORTEX/display/apply.sh" >> "$LOGFILE" 2>&1 && log_p "Display RR/lock done"

sh "$CORTEX/ram/apply.sh" >> "$LOGFILE" 2>&1 && log_p "RAM management applied"

sh "$CORTEX/battery/apply.sh" >> "$LOGFILE" 2>&1 && log_p "Battery charge limiter applied"

(
BAT_CFG="$CORTEX/battery"
while true; do
    LIMIT_EN=$(cat "$BAT_CFG/limit_enabled.txt" 2>/dev/null || echo "off")
    if [ "$LIMIT_EN" = "on" ]; then
        sh "$CORTEX/battery/apply.sh" 2>/dev/null
    fi
    sleep 60
done
) &

(
RAM_CFG="$CORTEX/ram"
while true; do
    MODE=$(cat "$RAM_CFG/mode.txt" 2>/dev/null || echo "balanced")
    FREE_KB=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    FREE_MB=$((FREE_KB / 1024))
    TOTAL_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    TOTAL_MB=$((TOTAL_KB / 1024))
    ZRAM_EN=$(cat "$RAM_CFG/zram_enabled.txt" 2>/dev/null || echo "on")
    ZRAM_SIZE=$(cat "$RAM_CFG/zram_size.txt" 2>/dev/null || echo "2")
    COMP=$(cat "$RAM_CFG/compressor.txt" 2>/dev/null || echo "lz4")

    SWAP_USED_KB=$(awk '/zram/ {print $4*4}' /proc/swaps 2>/dev/null | head -1)
    SWAP_USED_MB=$(( (${SWAP_USED_KB:-0}) / 1024 ))
    SWAP_TOTAL_KB=$(awk '/zram/ {print $3*4}' /proc/swaps 2>/dev/null | head -1)
    SWAP_TOTAL_MB=$(( (${SWAP_TOTAL_KB:-0}) / 1024 ))

    echo "${MODE}|${TOTAL_MB}|${FREE_MB}|${ZRAM_EN}|${ZRAM_SIZE}|${COMP}|${SWAP_USED_MB}|${SWAP_TOTAL_MB}" \
        > "$RAM_CFG/status.txt"

    case "$MODE" in
        gaming)       LOW_MB=600  ; CRIT_MB=350  ;;
        balanced)     LOW_MB=400  ; CRIT_MB=200  ;;
        memory_saver) LOW_MB=300  ; CRIT_MB=150  ;;
        *)            LOW_MB=400  ; CRIT_MB=200  ;;
    esac

    if [ "$FREE_MB" -lt "$CRIT_MB" ]; then
        sync
        echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
        cmd activity send-trim-memory 0 COMPLETE 2>/dev/null
        am send-trim-memory 0 2>/dev/null || true
    elif [ "$FREE_MB" -lt "$LOW_MB" ]; then
        sync
        echo 1 > /proc/sys/vm/drop_caches 2>/dev/null
    fi

    SELECTED=$(cat "$CORTEX/games/selected.txt" 2>/dev/null || echo "")
    IN_GAME=0
    for PKG in $SELECTED; do
        pidof "$PKG" >/dev/null 2>&1 && IN_GAME=1 && break
    done

    [ "$IN_GAME" = "1" ] && sleep 10 || sleep 30
done
) &

mkdir -p "$MODDIR/run"
pkill -f "$CORTEX/ai/engine.sh" 2>/dev/null
nohup sh "$CORTEX/ai/engine.sh" >> "$LOGFILE" 2>&1 &
log_p "Sweet Dreams Engine PID $!"

SELECTED=$(cat "$CORTEX/games/selected.txt" 2>/dev/null || echo "com.activision.callofduty.shooter")

mkdir -p "$MODDIR/run"
nohup sh "$CORTEX/daemons/game_monitor.sh" >> "$LOGFILE" 2>&1 &
log_p "OOM Watcher / Game Monitor PID $!"

log_p "Sweet Dreams v1.8.0 fully running"
