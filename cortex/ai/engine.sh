#!/system/bin/sh

MODDIR="/data/adb/modules/sweet_dreams"
CORTEX="$MODDIR/cortex"
AI_CFG="$CORTEX/ai"
RUNDIR="$MODDIR/run"
LOGFILE="$MODDIR/boot.log"

mkdir -p "$RUNDIR"
echo "$$" > "$RUNDIR/ai_engine.pid"

log_ai() { echo "[AI] $1" >> "$LOGFILE"; }

TEMP_WARN=420
TEMP_CRIT=470
TEMP_RECOVER=400
RAM_CRIT_MB=150

OVERRIDE_ACTIVE="off"

read_battery_temp() {
    cat /sys/class/power_supply/battery/temp 2>/dev/null || echo 0
}

read_free_ram_mb() {
    local kb
    kb=$(grep MemAvailable /proc/meminfo 2>/dev/null | awk '{print $2}')
    echo $(( ${kb:-0} / 1024 ))
}

apply_safety_override() {
    if [ "$OVERRIDE_ACTIVE" = "off" ]; then
        cp "$CORTEX/cpu/profile.txt" "$AI_CFG/saved_profile.txt" 2>/dev/null
        log_ai "Thermal override ENGAGED — forcing battery profile to cool down"
        sh "$CORTEX/notify/post.sh" thermal_override "Sweet Dreams ⚠️" \
            "Cooling override: ${BATT_TEMP_C}°C — forced to Battery profile" 2>/dev/null
    fi
    echo "battery" > "$CORTEX/cpu/profile.txt"
    sh "$CORTEX/cpu/apply.sh"  2>/dev/null
    sh "$CORTEX/gpu/apply.sh"  2>/dev/null
    OVERRIDE_ACTIVE="on"
    echo "on" > "$AI_CFG/override_active.txt"
}

release_safety_override() {
    [ "$OVERRIDE_ACTIVE" = "off" ] && return
    local SAVED
    SAVED=$(cat "$AI_CFG/saved_profile.txt" 2>/dev/null || echo "balanced")
    echo "$SAVED" > "$CORTEX/cpu/profile.txt"
    sh "$CORTEX/cpu/apply.sh" 2>/dev/null
    sh "$CORTEX/gpu/apply.sh" 2>/dev/null
    log_ai "Thermal override RELEASED — restored profile: $SAVED"
    sh "$CORTEX/notify/post.sh" thermal_override "Sweet Dreams" \
        "Cooled to ${BATT_TEMP_C:-—}°C — restored to ${SAVED} profile" 2>/dev/null
    OVERRIDE_ACTIVE="off"
    echo "off" > "$AI_CFG/override_active.txt"
}

[ "$(cat "$AI_CFG/override_active.txt" 2>/dev/null)" = "on" ] && OVERRIDE_ACTIVE="on"

log_ai "Engine started (PID $$) — native telemetry supervisor"

while true; do
    EN=$(cat "$AI_CFG/enabled.txt" 2>/dev/null || echo "on")
    if [ "$EN" != "on" ]; then
        release_safety_override
        sleep 5
        continue
    fi

    BATT_TEMP=$(read_battery_temp)
    BATT_TEMP_C=$(( BATT_TEMP / 10 ))
    FREE_RAM=$(read_free_ram_mb)
    BATT_PCT=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null || echo "—")
    GOV=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "—")
    PROFILE=$(cat "$CORTEX/cpu/profile.txt" 2>/dev/null || echo "—")

    if [ "$BATT_TEMP" -ge "$TEMP_CRIT" ] 2>/dev/null; then
        apply_safety_override
    elif [ "$BATT_TEMP" -le "$TEMP_RECOVER" ] 2>/dev/null && [ "$OVERRIDE_ACTIVE" = "on" ]; then
        release_safety_override
    elif [ "$BATT_TEMP" -ge "$TEMP_WARN" ] 2>/dev/null; then
        log_ai "Temp ${BATT_TEMP_C}C — watching (warn threshold, no action yet)"
    fi

    if [ "$FREE_RAM" -lt "$RAM_CRIT_MB" ] 2>/dev/null; then
        sync
        echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
        log_ai "Critical RAM (${FREE_RAM}MB free) — dropped caches"
    fi

    echo "${BATT_TEMP_C}|${BATT_PCT}|${FREE_RAM}|${GOV}|${PROFILE}|${OVERRIDE_ACTIVE}" \
        > "$AI_CFG/status.txt"

    sleep 5
done
