#!/system/bin/sh

MODDIR="/data/adb/modules/sweet_dreams"
CORTEX="$MODDIR/cortex"
NOTIFY_CFG="$CORTEX/notify"
LOGFILE="$MODDIR/boot.log"

log_notify() { echo "[NOTIFY] $1" >> "$LOGFILE"; }

CATEGORY="$1"
TITLE="$2"
TEXT="$3"

if [ -z "$CATEGORY" ] || [ -z "$TITLE" ]; then
    exit 0
fi

MASTER=$(cat "$NOTIFY_CFG/enabled.txt" 2>/dev/null || echo "on")
if [ "$MASTER" != "on" ]; then
    exit 0
fi

CAT_EN=$(cat "$NOTIFY_CFG/${CATEGORY}.txt" 2>/dev/null || echo "off")
if [ "$CAT_EN" != "on" ]; then
    exit 0
fi

TAG="SweetDreams_${CATEGORY}"

OUT=$(cmd notification post -S bigtext -t "$TITLE" "$TAG" "$TEXT" 2>&1)
RC=$?
if [ "$RC" -eq 0 ]; then
    log_notify "Posted [$CATEGORY]: $TITLE — $TEXT"
else
    log_notify "FAILED [$CATEGORY] (exit $RC): $OUT"
fi
