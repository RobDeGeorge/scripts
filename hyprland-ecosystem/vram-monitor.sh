#!/bin/bash

# VRAM monitoring script for Waybar
# Queries NVIDIA GPU for VRAM usage

# Get VRAM usage from nvidia-smi
vram_info=$(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null)

if [ $? -eq 0 ]; then
    # Parse the output and calculate values using awk
    echo "$vram_info" | awk -F', ' '{
        vram_used = $1
        vram_total = $2

        # Convert MB to GB for display (with 1 decimal)
        vram_used_gb = sprintf("%.1f", vram_used / 1024)
        vram_total_gb = sprintf("%.1f", vram_total / 1024)

        # Calculate percentage
        vram_percent = int((vram_used * 100) / vram_total)

        # Output in JSON format for Waybar
        printf "{\"text\": \"%sG/%sG\", \"tooltip\": \"VRAM: %d%% used\", \"percentage\": %d}\n",
               vram_used_gb, vram_total_gb, vram_percent, vram_percent
    }'
else
    # Fallback if nvidia-smi fails
    echo "{\"text\": \"N/A\", \"tooltip\": \"nvidia-smi unavailable\"}"
fi
