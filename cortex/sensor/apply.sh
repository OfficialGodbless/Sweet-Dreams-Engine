#!/system/bin/sh
CORTEX="/data/adb/modules/sweet_dreams/cortex"
SEN_CFG="$CORTEX/sensor"
ACTION="${1:-restore}"

log_sen() { echo "[SENSOR] $1"; }

DISABLE_SENSORS="
barometer
pressure
bmp
significant_motion
step_counter
step_detector
gravity
game_rotation_vector
geomagnetic
magnetic_field
orientation
linear_acceleration
"

toggle_iio() {
    local STATE="$1"
    for IIO_DEV in /sys/bus/iio/devices/iio:device*; do
        [ -f "$IIO_DEV/name" ] || continue
        DEVNAME=$(cat "$IIO_DEV/name" 2>/dev/null | tr '[:upper:]' '[:lower:]')
        for SEN in $DISABLE_SENSORS; do
            case "$DEVNAME" in *"$SEN"*)
                [ -f "$IIO_DEV/buffer/enable" ]  && echo "$STATE" > "$IIO_DEV/buffer/enable"  2>/dev/null
                [ -f "$IIO_DEV/scan_elements/in_accel_en" ] && continue
                log_sen "${STATE}: $DEVNAME"
                ;;
            esac
        done
    done
}

toggle_sensors_dumpsys() {
    local STATE="$1"
    local SENSOR_LIST="barometer|pressure|magnetic|significant|step_count|step_detect|gravity|orientation|linear_accel"
    dumpsys sensorservice 2>/dev/null | grep -iE "$SENSOR_LIST" | awk '{print $1}' | while read -r HANDLE; do
        [ -n "$HANDLE" ] && service call sensorservice 15 i32 "$HANDLE" i32 "$( [ "$STATE" = "disable" ] && echo 0 || echo 1 )" 2>/dev/null
    done
}

toggle_sensor_power() {
    local STATE="$1"
    for NODE in \
        /sys/class/sensor/barometer/enable \
        /sys/class/sensor/magnetic/enable \
        /sys/class/sensor/step_counter/enable \
        /sys/class/sensor/significant_motion/enable; do
        [ -f "$NODE" ] && echo "$STATE" > "$NODE" 2>/dev/null
    done
}

case "$ACTION" in
    game)
        SEN_EN=$(cat "$SEN_CFG/enabled.txt" 2>/dev/null || echo "off")
        [ "$SEN_EN" != "on" ] && exit 0
        log_sen "Disabling non-essential sensors for gaming"
        toggle_iio 0
        toggle_sensor_power 0
        echo "game" > "$SEN_CFG/state.txt"
        ;;
    restore)
        log_sen "Restoring all sensors"
        toggle_iio 1
        toggle_sensor_power 1
        echo "idle" > "$SEN_CFG/state.txt"
        ;;
esac
