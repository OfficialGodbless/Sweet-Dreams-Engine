#!/system/bin/sh
CORTEX="/data/adb/modules/sweet_dreams/cortex"
PROFILE=$(cat "$CORTEX/cpu/profile.txt" 2>/dev/null || echo "gaming")

set_gov() {
    for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo "$1" > "$f" 2>/dev/null
    done
}

set_a55() {
    for i in 0 1 2 3 4 5; do
        echo "$1" > /sys/devices/system/cpu/cpu${i}/cpufreq/scaling_min_freq 2>/dev/null
        echo "$2" > /sys/devices/system/cpu/cpu${i}/cpufreq/scaling_max_freq 2>/dev/null
    done
}

set_a76() {
    for i in 6 7; do
        echo "$1" > /sys/devices/system/cpu/cpu${i}/cpufreq/scaling_min_freq 2>/dev/null
        echo "$2" > /sys/devices/system/cpu/cpu${i}/cpufreq/scaling_max_freq 2>/dev/null
    done
}

case "$PROFILE" in
    gaming)
        set_gov "performance"
        set_a55 1800000 2000000
        set_a76 2000000 2200000
        ;;
    balanced)
        set_gov "schedutil"
        set_a55 500000 2000000
        set_a76 725000 2200000
        ;;
    battery)
        set_gov "powersave"
        set_a55 500000 1200000
        set_a76 725000 1500000
        ;;
esac

sysctl -w vm.swappiness=10 2>/dev/null
sysctl -w vm.vfs_cache_pressure=80 2>/dev/null
sysctl -w vm.dirty_expire_centisecs=500 2>/dev/null
sysctl -w vm.dirty_writeback_centisecs=3000 2>/dev/null
