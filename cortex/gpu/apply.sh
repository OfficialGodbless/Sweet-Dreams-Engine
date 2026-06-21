#!/system/bin/sh
CORTEX="/data/adb/modules/sweet_dreams/cortex"
PROFILE=$(cat "$CORTEX/cpu/profile.txt" 2>/dev/null || echo "gaming")

set_gov() {
    local GOV="$1"
    for p in \
        /sys/class/misc/mali0/device/devfreq/mali0/governor \
        /sys/class/misc/mali0/device/devfreq/*/governor \
        /sys/kernel/gpu/gpu_governor \
        /sys/class/devfreq/gpufreq/governor \
        /sys/devices/platform/mali.0/devfreq/mali.0/governor; do
        [ -f "$p" ] && echo "$GOV" > "$p" 2>/dev/null
    done
}

case "$PROFILE" in
    gaming)
        set_gov "performance"
        ;;
    balanced)
        set_gov "mali_ondemand" || set_gov "simple_ondemand" || set_gov "coarse_demand"
        ;;
    battery)
        set_gov "powersave" || set_gov "simple_ondemand"
        ;;
    *)
        set_gov "mali_ondemand" || set_gov "simple_ondemand"
        ;;
esac
