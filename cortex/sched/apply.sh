#!/system/bin/sh
sysctl -w kernel.sched_latency_ns=1000000 2>/dev/null
sysctl -w kernel.sched_wakeup_granularity_ns=500000 2>/dev/null
sysctl -w kernel.sched_migration_cost_ns=500000 2>/dev/null
sysctl -w kernel.sched_nr_migrate=64 2>/dev/null
sysctl -w kernel.sched_min_task_util_for_colocation=0 2>/dev/null
sysctl -w kernel.sched_min_task_util_for_boost=0 2>/dev/null

[ -f /dev/cpuset/top-app/cpus ]           && echo "0-7" > /dev/cpuset/top-app/cpus 2>/dev/null
[ -f /dev/cpuset/foreground/cpus ]        && echo "0-7" > /dev/cpuset/foreground/cpus 2>/dev/null
[ -f /dev/cpuset/background/cpus ]        && echo "0-3" > /dev/cpuset/background/cpus 2>/dev/null
[ -f /dev/cpuset/system-background/cpus ] && echo "0-3" > /dev/cpuset/system-background/cpus 2>/dev/null
[ -f /proc/sys/kernel/perf_event_paranoid ] && echo "1" > /proc/sys/kernel/perf_event_paranoid 2>/dev/null
