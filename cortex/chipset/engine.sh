#!/system/bin/sh

MODDIR="/data/adb/modules/sweet_dreams"
CORTEX="$MODDIR/cortex"
BACKUP_DIR="/data/local/tmp/frieren_render/backup"
BACKUP_FILE="$BACKUP_DIR/chipset_props.txt"

ACTION="${1:-activate}"

log_chip() { echo "[CHIPSET] $1"; }

PROPS="
persist.sys.powerhal.performance
persist.sys.powerhal.gpu
persist.sys.powerhal.interactive
persist.vendor.powerhal.fpsstabilizer
persist.vendor.powerhal.adpf
persist.vendor.powerhal.rendering
persist.vendor.powerhal.graphics
persist.vendor.powerhal.smart_launch
persist.sys.ui.hw
debug.mediatek.appgamepq
debug.mediatek.appgamepq_compress
debug.mediatek.disp_decompress
debug.mediatek.high_frame_rate_sf_set_big_core_fps_threshold
debug.performance.tuning
debug.gralloc.gfx_ubwc_disable
"

backup_props() {
    [ -f "$BACKUP_FILE" ] && return
    mkdir -p "$BACKUP_DIR"
    : > "$BACKUP_FILE"
    for P in $PROPS; do
        V=$(getprop "$P" 2>/dev/null)
        echo "${P}=${V}" >> "$BACKUP_FILE"
    done
    log_chip "Original props backed up"
}

activate() {
    backup_props

    local SOC
    SOC=$(getprop ro.soc.model 2>/dev/null)
    [ -z "$SOC" ] && SOC=$(getprop ro.hardware 2>/dev/null)
    [ -z "$SOC" ] && SOC="Unknown"

    resetprop debug.mediatek.appgamepq                                    1     2>/dev/null
    resetprop debug.mediatek.appgamepq_compress                           1     2>/dev/null
    resetprop debug.mediatek.disp_decompress                              1     2>/dev/null
    resetprop debug.mediatek.high_frame_rate_sf_set_big_core_fps_threshold 60   2>/dev/null

    resetprop persist.sys.powerhal.performance      1    2>/dev/null
    resetprop persist.sys.powerhal.gpu              1    2>/dev/null
    resetprop persist.sys.powerhal.interactive      1    2>/dev/null
    resetprop persist.vendor.powerhal.fpsstabilizer 1    2>/dev/null
    resetprop persist.vendor.powerhal.adpf          1    2>/dev/null
    resetprop persist.vendor.powerhal.rendering     1    2>/dev/null
    resetprop persist.vendor.powerhal.graphics      1    2>/dev/null
    resetprop persist.vendor.powerhal.smart_launch  1    2>/dev/null
    resetprop persist.sys.ui.hw                     true 2>/dev/null
    resetprop debug.performance.tuning              1    2>/dev/null
    resetprop debug.gralloc.gfx_ubwc_disable        0    2>/dev/null

    log_chip "Processor props activated for ${SOC}"
}

restore() {
    if [ ! -f "$BACKUP_FILE" ]; then
        log_chip "No backup found, nothing to restore"
        return
    fi
    while IFS='=' read -r KEY VAL; do
        [ -z "$KEY" ] && continue
        if [ -z "$VAL" ]; then
            resetprop --delete "$KEY" 2>/dev/null
        else
            resetprop "$KEY" "$VAL" 2>/dev/null
        fi
    done < "$BACKUP_FILE"
    log_chip "Processor properties restored to original values"
}

case "$ACTION" in
    activate) activate ;;
    restore)  restore  ;;
    *)
        echo "Usage: engine.sh activate|restore" >&2
        exit 1
        ;;
esac
