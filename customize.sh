#!/system/bin/sh
ui_print ""
ui_print "  Sweet Dreams v1.0 — by Lil G Tech Labs"
ui_print "  Infinix HOT 60 Pro+ — t.me/LilGTechLabs"
ui_print ""

mkdir -p "$MODPATH/cortex/thermal"
mkdir -p "$MODPATH/cortex/cpu"
mkdir -p "$MODPATH/cortex/gpu"
mkdir -p "$MODPATH/cortex/touch"
mkdir -p "$MODPATH/cortex/net"
mkdir -p "$MODPATH/cortex/sched"
mkdir -p "$MODPATH/cortex/display"
mkdir -p "$MODPATH/cortex/games"
mkdir -p "$MODPATH/cortex/ram"
mkdir -p "$MODPATH/cortex/battery"
mkdir -p "$MODPATH/cortex/sensor"
mkdir -p "$MODPATH/cortex/perf"
mkdir -p "$MODPATH/cortex/audio"
mkdir -p "$MODPATH/cortex/ai"
mkdir -p "$MODPATH/cortex/fps"
mkdir -p "$MODPATH/cortex/chipset"
mkdir -p "$MODPATH/cortex/notify"
mkdir -p "$MODPATH/cortex/daemons"
mkdir -p "$MODPATH/cortex/storage"

echo "disabled" > "$MODPATH/cortex/thermal/status.txt"
echo "extreme"  > "$MODPATH/cortex/thermal/mode.txt"
echo "gaming"   > "$MODPATH/cortex/cpu/profile.txt"
echo "on"       > "$MODPATH/cortex/touch/status.txt"
echo "on"       > "$MODPATH/cortex/touch/input_booster.txt"
echo "240"      > "$MODPATH/cortex/touch/report_rate.txt"
echo "off"      > "$MODPATH/cortex/touch/noise_filter.txt"
echo "medium"   > "$MODPATH/cortex/touch/tap_sens.txt"
echo "on"       > "$MODPATH/cortex/net/status.txt"
echo "bbr"      > "$MODPATH/cortex/net/congestion.txt"
echo "off"      > "$MODPATH/cortex/net/dns_mode.txt"
echo "1.1.1.1"  > "$MODPATH/cortex/net/dns1.txt"
echo "1.0.0.1"  > "$MODPATH/cortex/net/dns2.txt"
echo ""         > "$MODPATH/cortex/net/status_live.txt"
echo "90"       > "$MODPATH/cortex/display/fps.txt"
echo "balanced" > "$MODPATH/cortex/ram/mode.txt"
echo "on"       > "$MODPATH/cortex/ram/zram_enabled.txt"
echo "2"        > "$MODPATH/cortex/ram/zram_size.txt"
echo "lz4"     > "$MODPATH/cortex/ram/compressor.txt"
echo ""         > "$MODPATH/cortex/ram/status.txt"
echo "off"      > "$MODPATH/cortex/battery/limit_enabled.txt"
echo "80"       > "$MODPATH/cortex/battery/limit_pct.txt"
echo ""         > "$MODPATH/cortex/battery/status.txt"
echo "off"      > "$MODPATH/cortex/sensor/enabled.txt"
echo "idle"     > "$MODPATH/cortex/sensor/state.txt"
echo "on"       > "$MODPATH/cortex/perf/enabled.txt"
echo "idle"     > "$MODPATH/cortex/perf/state.txt"
echo "off"      > "$MODPATH/cortex/audio/enabled.txt"
echo "off"      > "$MODPATH/cortex/audio/bt_lowlat.txt"
echo ""         > "$MODPATH/cortex/audio/status.txt"
echo "on"       > "$MODPATH/cortex/ai/enabled.txt"
echo "off"      > "$MODPATH/cortex/ai/override_active.txt"
echo ""         > "$MODPATH/cortex/ai/status.txt"
echo ""         > "$MODPATH/cortex/ai/saved_profile.txt"
echo ""         > "$MODPATH/cortex/storage/last_freed_kb.txt"
echo "on"       > "$MODPATH/cortex/notify/enabled.txt"
echo "on"       > "$MODPATH/cortex/notify/game_launch.txt"
echo "on"       > "$MODPATH/cortex/notify/game_exit.txt"
echo "on"       > "$MODPATH/cortex/notify/thermal_override.txt"
echo "on"       > "$MODPATH/cortex/notify/spoof_active.txt"
echo "off"      > "$MODPATH/cortex/display/fps_lock_game.txt"
echo "rr_off"   > "$MODPATH/cortex/display/rr_status.txt"
echo "on"       > "$MODPATH/cortex/display/vsync.txt"
echo "skiavk"   > "$MODPATH/cortex/display/render.txt"
echo "0.5"      > "$MODPATH/cortex/display/anim_scale.txt"
echo "native"   > "$MODPATH/cortex/display/resolution.txt"
echo "8"        > "$MODPATH/cortex/touch/swipe_px.txt"
echo "400"      > "$MODPATH/cortex/touch/lp_timeout.txt"
echo "off"      > "$MODPATH/cortex/games/kill_bg_enabled.txt"
echo "off"      > "$MODPATH/cortex/games/restrict_net_enabled.txt"
echo "off"      > "$MODPATH/cortex/games/spoof_master.txt"
echo "com.activision.callofduty.shooter|legion" > "$MODPATH/cortex/games/spoof_assignments.txt"
cat > "$MODPATH/cortex/games/kill_bg_whitelist.txt" << 'WLEOF'
com.whatsapp
com.discord
com.spotify.music
WLEOF
echo "com.activision.callofduty.shooter" > "$MODPATH/cortex/games/selected.txt"

ABI_LIST=$(getprop ro.product.cpu.abilist)
if echo "$ABI_LIST" | grep -q "arm64-v8a"; then
    mv "$MODPATH/controller_arm64" "$MODPATH/controller" 2>/dev/null
    rm -f "$MODPATH/controller_armv7" 2>/dev/null
    ui_print "  [✓] Controller: ARM64"
else
    mv "$MODPATH/controller_armv7" "$MODPATH/controller" 2>/dev/null
    rm -f "$MODPATH/controller_arm64" 2>/dev/null
    ui_print "  [✓] Controller: ARM32"
fi

rm -f "$MODPATH/zygisk/x86.so" "$MODPATH/zygisk/x86_64.so" 2>/dev/null

set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm_recursive "$MODPATH/bin" 0 0 0755 0755
set_perm_recursive "$MODPATH/system/bin" 0 2000 0755 0755
set_perm_recursive "$MODPATH/zygisk" 0 0 0755 0644
set_perm "$MODPATH/controller"      0 0 0755
set_perm "$MODPATH/COPG.json"       0 0 0644
set_perm "$MODPATH/cpuinfo_spoof"   0 0 0444
set_perm "$MODPATH/service.sh"      0 0 0755
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh"    0 0 0755
find "$MODPATH/cortex" -name "*.sh" -exec chmod 0755 {} \;

chcon u:object_r:system_file:s0 "$MODPATH/COPG.json" 2>/dev/null
chcon u:object_r:system_file:s0 "$MODPATH/cpuinfo_spoof" 2>/dev/null
chcon u:object_r:system_file:s0 "$MODPATH/service.sh" 2>/dev/null

ui_print "  [✓] Profile: GAMING"
ui_print "  [✓] Thermal: Extreme mode"
ui_print "  [✓] Zygisk spoof engine ready"
ui_print "  [✓] RTI + IDC: mtk-tpd"
ui_print "  [✓] SkiaVK (Vulkan 1.3.177)"
ui_print ""
ui_print "  NOTE: Zygisk Next must be installed"
ui_print "  Open WebUI via KSU module page"
ui_print ""
