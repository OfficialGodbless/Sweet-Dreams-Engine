#!/system/bin/sh
CORTEX="/data/adb/modules/sweet_dreams/cortex"
AUD_CFG="$CORTEX/audio"

ACTION="${1:-apply}"
EN=$(cat "$AUD_CFG/enabled.txt"        2>/dev/null || echo "off")
BT_LOW=$(cat "$AUD_CFG/bt_lowlat.txt"  2>/dev/null || echo "off")

log_aud() { echo "[AUDIO] $1"; }

apply_low_latency() {
    resetprop audio.deep_buffer.media false 2>/dev/null

    resetprop vendor.audio.mmap.enable true 2>/dev/null
    resetprop persist.vendor.audio.lowlatency.enable true 2>/dev/null

    resetprop af.fast_track_multiplier 1 2>/dev/null

    resetprop vendor.audio.tunnel.encode false 2>/dev/null

    log_aud "Low-latency audio path enabled"
}

restore_normal_latency() {
    resetprop --delete audio.deep_buffer.media               2>/dev/null
    resetprop --delete vendor.audio.mmap.enable               2>/dev/null
    resetprop --delete persist.vendor.audio.lowlatency.enable 2>/dev/null
    resetprop --delete af.fast_track_multiplier                2>/dev/null
    resetprop --delete vendor.audio.tunnel.encode              2>/dev/null
    log_aud "Audio path restored to system default"
}

apply_bt_low_latency() {
    local STATE="$1"
    if [ "$STATE" = "on" ]; then
        resetprop persist.bluetooth.a2dp_offload.disabled true 2>/dev/null
        resetprop persist.vendor.btstack.enable.lowlatency true 2>/dev/null
        log_aud "BT low-latency mode on (A2DP offload disabled)"
    else
        resetprop --delete persist.bluetooth.a2dp_offload.disabled   2>/dev/null
        resetprop --delete persist.vendor.btstack.enable.lowlatency  2>/dev/null
        log_aud "BT audio restored to default offload path"
    fi
}

if [ "$ACTION" = "restore" ]; then
    restore_normal_latency
    apply_bt_low_latency "off"
    log_aud "Restored to idle (preference preserved for next launch)"
    exit 0
fi

if [ "$EN" = "on" ]; then
    apply_low_latency
else
    restore_normal_latency
fi

apply_bt_low_latency "$BT_LOW"

echo "${EN}|${BT_LOW}" > "$AUD_CFG/status.txt"
