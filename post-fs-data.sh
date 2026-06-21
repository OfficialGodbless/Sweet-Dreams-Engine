#!/system/bin/sh
MODDIR=${0%/*}
CORTEX="$MODDIR/cortex"
RENDER=$(cat "$CORTEX/display/render.txt" 2>/dev/null || echo "skiavk")
case "$RENDER" in
    skiavk)
        resetprop debug.hwui.renderer skiavk
        resetprop debug.renderengine.backend skiaglthreaded
        resetprop -n persist.sys.gpu_rendering skiavk
        ;;
    skiagl)
        resetprop debug.hwui.renderer skiagl
        resetprop debug.renderengine.backend skiaglthreaded
        ;;
    angle)
        resetprop debug.hwui.renderer angle
        resetprop debug.renderengine.backend angle
        ;;
    opengl)
        resetprop debug.hwui.renderer opengl
        resetprop debug.renderengine.backend gles
        ;;
esac
resetprop debug.renderengine.skia_use_perfetto_track_events false
