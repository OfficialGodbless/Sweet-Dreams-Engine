#!/system/bin/sh
CORTEX="/data/adb/modules/sweet_dreams/cortex"
MODDIR="/data/adb/modules/sweet_dreams"

VSYNC=$(cat "$CORTEX/display/vsync.txt" 2>/dev/null || echo "on")
if [ "$VSYNC" = "off" ]; then
    resetprop debug.sf.hw 1 2>/dev/null
    resetprop ro.surface_flinger.use_content_detection_for_refresh_rate false 2>/dev/null
    settings put global debug.egl.swapinterval -1 2>/dev/null
fi

RES=$(cat "$CORTEX/display/resolution.txt" 2>/dev/null || echo "native")
if [ "$RES" = "native" ]; then
    resetprop --delete persist.sys.sf.render_scale_factor 2>/dev/null
    resetprop --delete debug.hwui.render_resolution 2>/dev/null
    service call SurfaceFlinger 1008 f 1.0 2>/dev/null
    wm size reset 2>/dev/null
    wm density reset 2>/dev/null
else
    resetprop persist.sys.sf.render_scale_factor "$RES" 2>/dev/null
    service call SurfaceFlinger 1008 f "$RES" 2>/dev/null
    PHYS=$(wm size 2>/dev/null | grep -i "Physical size" | grep -o '[0-9]*x[0-9]*')
    PDENS=$(wm density 2>/dev/null | grep -i "Physical density" | grep -o '[0-9]*')
    if [ -n "$PHYS" ]; then
        PW=${PHYS%x*}
        PH=${PHYS#*x}
        NW=$(awk "BEGIN{printf \"%d\", $PW * $RES}")
        NH=$(awk "BEGIN{printf \"%d\", $PH * $RES}")
        if [ -n "$NW" ] && [ -n "$NH" ]; then
            wm size "${NW}x${NH}" 2>/dev/null
        fi
        if [ -n "$PDENS" ]; then
            ND=$(awk "BEGIN{printf \"%d\", $PDENS * $RES}")
            [ -n "$ND" ] && wm density "$ND" 2>/dev/null
        fi
    fi
fi
am force-stop com.android.systemui 2>/dev/null

RENDER=$(cat "$CORTEX/display/render.txt" 2>/dev/null || echo "skiavk")
case "$RENDER" in
    skiavk)
        resetprop debug.hwui.renderer skiavk 2>/dev/null
        resetprop debug.renderengine.backend skiaglthreaded 2>/dev/null
        ;;
    skiagl)
        resetprop debug.hwui.renderer skiagl 2>/dev/null
        resetprop debug.renderengine.backend skiaglthreaded 2>/dev/null
        ;;
    angle)
        resetprop debug.hwui.renderer angle 2>/dev/null
        resetprop debug.renderengine.backend angle 2>/dev/null
        ;;
    opengl)
        resetprop debug.hwui.renderer opengl 2>/dev/null
        resetprop debug.renderengine.backend gles 2>/dev/null
        ;;
esac

TARGET_FPS=$(cat "$CORTEX/display/fps.txt" 2>/dev/null || echo "90")
RR_LOCK=$(cat "$CORTEX/display/rr_lock.txt" 2>/dev/null || echo "off")

settings put system peak_refresh_rate "$TARGET_FPS" 2>/dev/null

case "$RR_LOCK" in
    locked)
        settings put system min_refresh_rate "$TARGET_FPS" 2>/dev/null
        resetprop ro.surface_flinger.use_content_detection_for_refresh_rate false 2>/dev/null
        resetprop debug.sf.use_content_detection_for_refresh_rate false 2>/dev/null
        resetprop persist.sys.disable_rrs 1 2>/dev/null
        echo "rr_locked" > "$CORTEX/display/rr_status.txt"
        ;;
    game)
        settings put system min_refresh_rate 60 2>/dev/null
        resetprop ro.surface_flinger.use_content_detection_for_refresh_rate true 2>/dev/null
        resetprop debug.sf.use_content_detection_for_refresh_rate true 2>/dev/null
        resetprop persist.sys.disable_rrs 0 2>/dev/null
        echo "rr_game_mode" > "$CORTEX/display/rr_status.txt"
        ;;
    off|*)
        settings put system min_refresh_rate 60 2>/dev/null
        resetprop ro.surface_flinger.use_content_detection_for_refresh_rate true 2>/dev/null
        resetprop debug.sf.use_content_detection_for_refresh_rate true 2>/dev/null
        resetprop persist.sys.disable_rrs 0 2>/dev/null
        echo "rr_off" > "$CORTEX/display/rr_status.txt"
        ;;
esac

FPS_LOCK_GAME=$(cat "$CORTEX/display/fps_lock_game.txt" 2>/dev/null || echo "off")
if [ "$FPS_LOCK_GAME" != "off" ]; then
    sh "$CORTEX/fps/engine.sh" "$TARGET_FPS" 2>/dev/null
fi
