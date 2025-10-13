#!/bin/bash

# Memory monitoring script for Waybar that matches htop
# htop shows: Total - Available (which includes cache that can be freed)

# Read memory info
read -r mem_total mem_available <<< $(awk '/MemTotal:|MemAvailable:/ {print $2}' /proc/meminfo | xargs)

# Convert from KB to GB
mem_total_gb=$(awk "BEGIN {printf \"%.1f\", $mem_total / 1024 / 1024}")
mem_available_gb=$(awk "BEGIN {printf \"%.1f\", $mem_available / 1024 / 1024}")

# Calculate used memory (total - available) like htop does
mem_used_gb=$(awk "BEGIN {printf \"%.1f\", ($mem_total - $mem_available) / 1024 / 1024}")

# Calculate percentage
mem_percent=$(awk "BEGIN {printf \"%.0f\", (($mem_total - $mem_available) * 100) / $mem_total}")

# Output in JSON format for Waybar
echo "{\"text\": \"RAM ${mem_used_gb}G/${mem_total_gb}G\", \"tooltip\": \"RAM: ${mem_percent}% used\", \"percentage\": $mem_percent}"
