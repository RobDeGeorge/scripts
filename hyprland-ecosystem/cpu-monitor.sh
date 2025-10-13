#!/bin/bash

# CPU monitoring script for Waybar that matches htop
# Gets average CPU usage across all cores

# Read CPU stats twice with a small delay for accurate measurement
read -r cpu1_user cpu1_nice cpu1_system cpu1_idle cpu1_iowait cpu1_irq cpu1_softirq cpu1_steal <<< \
    $(awk '/^cpu / {print $2, $3, $4, $5, $6, $7, $8, $9}' /proc/stat)

sleep 0.5

read -r cpu2_user cpu2_nice cpu2_system cpu2_idle cpu2_iowait cpu2_irq cpu2_softirq cpu2_steal <<< \
    $(awk '/^cpu / {print $2, $3, $4, $5, $6, $7, $8, $9}' /proc/stat)

# Calculate differences
diff_user=$((cpu2_user - cpu1_user))
diff_nice=$((cpu2_nice - cpu1_nice))
diff_system=$((cpu2_system - cpu1_system))
diff_idle=$((cpu2_idle - cpu1_idle))
diff_iowait=$((cpu2_iowait - cpu1_iowait))
diff_irq=$((cpu2_irq - cpu1_irq))
diff_softirq=$((cpu2_softirq - cpu1_softirq))
diff_steal=$((cpu2_steal - cpu1_steal))

# Calculate total and usage
total=$((diff_user + diff_nice + diff_system + diff_idle + diff_iowait + diff_irq + diff_softirq + diff_steal))
used=$((diff_user + diff_nice + diff_system + diff_irq + diff_softirq + diff_steal))

# Calculate percentage
if [ $total -gt 0 ]; then
    cpu_percent=$(awk "BEGIN {printf \"%.0f\", ($used * 100) / $total}")
else
    cpu_percent=0
fi

# Output in JSON format for Waybar
echo "{\"text\": \"CPU ${cpu_percent}%\", \"tooltip\": \"CPU: ${cpu_percent}% used\", \"percentage\": $cpu_percent}"
