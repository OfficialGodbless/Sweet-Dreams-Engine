#!/system/bin/sh
CORTEX="/data/adb/modules/sweet_dreams/cortex"
STATUS=$(cat "$CORTEX/net/status.txt" 2>/dev/null || echo "on")
CC=$(cat "$CORTEX/net/congestion.txt" 2>/dev/null || echo "bbr")
DNS_MODE=$(cat "$CORTEX/net/dns_mode.txt" 2>/dev/null || echo "off")
DNS1=$(cat "$CORTEX/net/dns1.txt" 2>/dev/null || echo "1.1.1.1")
DNS2=$(cat "$CORTEX/net/dns2.txt" 2>/dev/null || echo "1.0.0.1")

log_net() { echo "[NET] $1"; }

if [ "$STATUS" = "on" ]; then
    sysctl -w net.ipv4.tcp_low_latency=1 2>/dev/null
    sysctl -w net.ipv4.tcp_rmem="4096 87380 16777216" 2>/dev/null
    sysctl -w net.ipv4.tcp_wmem="4096 65536 16777216" 2>/dev/null

    case "$CC" in
        bbr)
            if sysctl -w net.ipv4.tcp_congestion_control=bbr 2>/dev/null; then
                log_net "CC: bbr"
            else
                sysctl -w net.ipv4.tcp_congestion_control=cubic 2>/dev/null
                log_net "CC: bbr unavailable, fell back to cubic"
            fi
            ;;
        westwood)
            if sysctl -w net.ipv4.tcp_congestion_control=westwood 2>/dev/null; then
                log_net "CC: westwood"
            else
                sysctl -w net.ipv4.tcp_congestion_control=cubic 2>/dev/null
                log_net "CC: westwood unavailable, fell back to cubic"
            fi
            ;;
        cubic)
            sysctl -w net.ipv4.tcp_congestion_control=cubic 2>/dev/null
            log_net "CC: cubic"
            ;;
        reno)
            sysctl -w net.ipv4.tcp_congestion_control=reno 2>/dev/null
            log_net "CC: reno"
            ;;
    esac

    sysctl -w net.ipv4.tcp_no_metrics_save=1 2>/dev/null
    sysctl -w net.ipv4.tcp_timestamps=0    2>/dev/null
    sysctl -w net.ipv4.tcp_sack=1          2>/dev/null
    sysctl -w net.ipv4.tcp_fastopen=3      2>/dev/null
    sysctl -w net.core.rmem_max=16777216   2>/dev/null
    sysctl -w net.core.wmem_max=16777216   2>/dev/null
    sysctl -w net.core.netdev_max_backlog=5000 2>/dev/null
    sysctl -w net.ipv4.tcp_slow_start_after_idle=0 2>/dev/null
    sysctl -w net.ipv4.tcp_mtu_probing=1   2>/dev/null

    if [ "$DNS_MODE" = "custom" ]; then
        settings put global private_dns_mode off 2>/dev/null
        for IFACE in wlan0 rmnet_data0 rmnet0; do
            ndc resolver setifdns "$IFACE" "" "$DNS1" "$DNS2" 2>/dev/null
        done
        log_net "DNS: $DNS1, $DNS2"
    elif [ "$DNS_MODE" = "doh" ]; then
        settings put global private_dns_mode hostname 2>/dev/null
        settings put global private_dns_specifier "$DNS1" 2>/dev/null
        log_net "Private DNS: $DNS1"
    fi
else
    log_net "Network boost off — defaults"
fi

CUR_CC=$(cat /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null || echo "—")
AVAIL_CC=$(cat /proc/sys/net/ipv4/tcp_available_congestion_control 2>/dev/null || echo "—")
echo "${STATUS}|${CUR_CC}|${AVAIL_CC}|${DNS_MODE}|${DNS1}|${DNS2}" > "$CORTEX/net/status_live.txt"
