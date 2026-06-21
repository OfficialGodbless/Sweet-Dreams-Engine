#!/system/bin/sh
MODDIR="/data/adb/modules/sweet_dreams"
CORTEX="$MODDIR/cortex"

pkill -f "Frieren_AI_Games"   2>/dev/null
pkill -f "Frieren_FPS"        2>/dev/null
pkill -f "Frieren_Thermal"    2>/dev/null
pkill -f "Frieren_Battery"    2>/dev/null
pkill -f "Frieren_Chipset"    2>/dev/null
pkill -f "$MODDIR/controller" 2>/dev/null
pkill -f "lgtl-thermal"       2>/dev/null
pkill -f "RTI--"              2>/dev/null
pkill -f "$CORTEX/ai/engine.sh"          2>/dev/null
pkill -f "$CORTEX/daemons/game_monitor.sh" 2>/dev/null
sleep 1

iptables-save 2>/dev/null | grep -- "--uid-owner" | while read rule; do
    iptables ${rule#-A } 2>/dev/null || true
    iptables -D ${rule#-A } 2>/dev/null || true
done
ip6tables-save 2>/dev/null | grep -- "--uid-owner" | while read rule; do
    ip6tables -D ${rule#-A } 2>/dev/null || true
done

echo "0"   > /sys/class/power_supply/battery/batt_slate_mode             2>/dev/null
echo "100" > /sys/class/power_supply/battery/charge_control_limit        2>/dev/null
echo "100" > /sys/class/power_supply/battery/charge_stop_level           2>/dev/null
echo "100" > /sys/class/power_supply/mtk-gauge/charge_stop_level         2>/dev/null
resetprop persist.vendor.battery.protect.enable 0    2>/dev/null
resetprop persist.vendor.battery.protect.level "100" 2>/dev/null

resetprop --delete audio.deep_buffer.media               2>/dev/null
resetprop --delete vendor.audio.mmap.enable               2>/dev/null
resetprop --delete persist.vendor.audio.lowlatency.enable 2>/dev/null
resetprop --delete af.fast_track_multiplier                2>/dev/null
resetprop --delete vendor.audio.tunnel.encode              2>/dev/null
resetprop --delete persist.bluetooth.a2dp_offload.disabled  2>/dev/null
resetprop --delete persist.vendor.btstack.enable.lowlatency 2>/dev/null

for IIO_DEV in /sys/bus/iio/devices/iio:device*; do
    [ -f "$IIO_DEV/buffer/enable" ] && echo "1" > "$IIO_DEV/buffer/enable" 2>/dev/null
done

swapoff /dev/block/zram0 2>/dev/null
swapoff /dev/zram0       2>/dev/null
sysctl -w vm.swappiness=100           2>/dev/null
sysctl -w vm.vfs_cache_pressure=100   2>/dev/null
sysctl -w vm.dirty_ratio=30           2>/dev/null
sysctl -w vm.dirty_background_ratio=10 2>/dev/null
sysctl -w vm.page-cluster=3           2>/dev/null

echo "0" > /proc/ppm/policy/hard_userlimit_min_cpu_freq 2>/dev/null

for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo "schedutil" > "$f" 2>/dev/null
done
for i in 0 1 2 3 4 5; do
    echo "500000"  > /sys/devices/system/cpu/cpu${i}/cpufreq/scaling_min_freq 2>/dev/null
    echo "2000000" > /sys/devices/system/cpu/cpu${i}/cpufreq/scaling_max_freq 2>/dev/null
done
for i in 6 7; do
    echo "725000"  > /sys/devices/system/cpu/cpu${i}/cpufreq/scaling_min_freq 2>/dev/null
    echo "2200000" > /sys/devices/system/cpu/cpu${i}/cpufreq/scaling_max_freq 2>/dev/null
done

echo "0"   > /dev/stune/top-app/schedtune.boost       2>/dev/null
echo "0"   > /dev/stune/top-app/schedtune.prefer_idle 2>/dev/null

for tz in /sys/class/thermal/thermal_zone*/mode; do
    echo "enabled" > "$tz" 2>/dev/null
done
start thermal-engine   2>/dev/null
start thermal_manager  2>/dev/null
resetprop persist.thermal.enable 1  2>/dev/null
resetprop vendor.thermal.manager 1  2>/dev/null

pm enable com.mediatek.thermal 2>/dev/null

settings delete system peak_refresh_rate      2>/dev/null
settings delete system min_refresh_rate       2>/dev/null
settings delete global window_animation_scale 2>/dev/null
settings delete global transition_animation_scale 2>/dev/null
settings delete global animator_duration_scale 2>/dev/null
settings delete system pointer_speed          2>/dev/null
settings delete secure long_press_timeout     2>/dev/null
settings delete secure multi_press_timeout    2>/dev/null
wm size reset    2>/dev/null
wm density reset 2>/dev/null
resetprop --delete persist.sys.disable_rrs            2>/dev/null
resetprop ro.surface_flinger.use_content_detection_for_refresh_rate true 2>/dev/null

resetprop --delete debug.hwui.renderer          2>/dev/null
resetprop --delete debug.renderengine.backend   2>/dev/null
resetprop --delete persist.sys.sf.render_scale_factor 2>/dev/null

sh "$CORTEX/chipset/engine.sh" restore 2>/dev/null

sh "$CORTEX/fps/engine.sh" restore 2>/dev/null

resetprop ro.product.brand        "$(getprop ro.product.vendor.brand)"        2>/dev/null
resetprop ro.product.manufacturer "$(getprop ro.product.vendor.manufacturer)" 2>/dev/null
resetprop ro.product.model        "$(getprop ro.product.vendor.model)"        2>/dev/null
resetprop ro.product.device       "$(getprop ro.product.vendor.device)"       2>/dev/null
resetprop ro.build.fingerprint    "$(getprop ro.vendor.build.fingerprint)"    2>/dev/null

echo "0" > /proc/gpufreq/gpufreq_opp_freq 2>/dev/null

rm -rf /data/local/tmp/Frieren_Perf 2>/dev/null

for TAG in SweetDreams_game_launch SweetDreams_game_exit SweetDreams_thermal_override SweetDreams_spoof_active; do
    su 2000 -c "cmd notification cancel $TAG" >/dev/null 2>&1
done

echo "[LGTL] Uninstall cleanup complete"
