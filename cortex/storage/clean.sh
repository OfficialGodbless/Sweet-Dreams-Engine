#!/system/bin/sh
CORTEX="/data/adb/modules/sweet_dreams/cortex"

BEFORE_KB=$(df /data 2>/dev/null | awk 'NR==2{print $4}')

pm trim-caches 999999999999 2>/dev/null
sync

AFTER_KB=$(df /data 2>/dev/null | awk 'NR==2{print $4}')

FREED_KB=0
if [ -n "$BEFORE_KB" ] && [ -n "$AFTER_KB" ]; then
    FREED_KB=$((AFTER_KB - BEFORE_KB))
    [ "$FREED_KB" -lt 0 ] && FREED_KB=0
fi

echo "$FREED_KB" > "$CORTEX/storage/last_freed_kb.txt" 2>/dev/null
echo "freed_kb:$FREED_KB"
