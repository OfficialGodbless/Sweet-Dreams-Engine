#!/system/bin/sh
GAME_PKG="$1"
ACTION="${2:-on}"

GAME_UID=$(dumpsys package "$GAME_PKG" 2>/dev/null | grep -m1 "userId=" | sed -n 's/.*userId=\([0-9][0-9]*\).*/\1/p')
[ -z "$GAME_UID" ] && exit 1

flush_rules() {
    while iptables -D OUTPUT -m owner ! --uid-owner "$GAME_UID" -j DROP 2>/dev/null; do :; done
    while iptables -D INPUT  -m owner ! --uid-owner "$GAME_UID" -j DROP 2>/dev/null; do :; done
    while ip6tables -D OUTPUT -m owner ! --uid-owner "$GAME_UID" -j DROP 2>/dev/null; do :; done
    while ip6tables -D INPUT  -m owner ! --uid-owner "$GAME_UID" -j DROP 2>/dev/null; do :; done
}

if [ "$ACTION" = "on" ]; then
    flush_rules
    iptables -I OUTPUT -m owner ! --uid-owner "$GAME_UID" -j DROP 2>/dev/null
    iptables -I INPUT  -m owner ! --uid-owner "$GAME_UID" -j DROP 2>/dev/null
    ip6tables -I OUTPUT -m owner ! --uid-owner "$GAME_UID" -j DROP 2>/dev/null
    ip6tables -I INPUT  -m owner ! --uid-owner "$GAME_UID" -j DROP 2>/dev/null
else
    flush_rules
fi
