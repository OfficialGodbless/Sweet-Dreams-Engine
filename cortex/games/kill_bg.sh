#!/system/bin/sh
GAME_PKG="$1"
CORTEX="/data/adb/modules/sweet_dreams/cortex"
WHITELIST="$CORTEX/games/kill_bg_whitelist.txt"

HARDCODED_SAFE="
com.android.systemui
com.google.android.gms
com.google.android.gsf
com.android.phone
com.android.dialer
com.android.inputmethod.latin
com.google.android.inputmethod.latin
com.samsung.android.honeyboard
com.touchtype.swiftkey
com.android.vending
com.google.android.gmscore
com.mediatek.gba
com.mediatek.ims
com.android.server.telecom
com.android.providers.telephony
com.android.providers.settings
com.android.providers.contacts
com.android.settings
android
com.android.bluetooth
com.transsion.hilauncher
com.itel.launcher
com.infinix.launcher
"

is_safe() {
    local PKG="$1"
    [ "$PKG" = "$GAME_PKG" ] && return 0
    echo "$HARDCODED_SAFE" | grep -qxF "$PKG" && return 0
    [ -f "$WHITELIST" ] && grep -qxF "$PKG" "$WHITELIST" && return 0
    return 1
}

for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2); do
    is_safe "$pkg" && continue
    am kill "$pkg" 2>/dev/null
done
