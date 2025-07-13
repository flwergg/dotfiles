#!/bin/bash

# Battery monitoring script for Hyprland

# Configuration
BATTERY_LOW=15      # Percentage for low battery notification
BATTERY_CRITICAL=5  # Critical percentage
CHECK_INTERVAL=60   # Check interval in seconds

# Function to get battery percentage
get_battery_level() {
    cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1
}

# Function to check if charger is connected
is_charging() {
    local status=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1)
    [[ "$status" == "Charging" ]] || [[ "$status" == "Full" ]]
}

# Variables for notification control
low_notified=false
critical_notified=false

echo "🔋 Battery monitor started"
echo "⚠️  Low notification at: ${BATTERY_LOW}%"
echo "🚨 Critical at: ${BATTERY_CRITICAL}%"

while true; do
    battery_level=$(get_battery_level)
    
    if [[ -z "$battery_level" ]]; then
        echo "❌ Could not get battery level"
        sleep $CHECK_INTERVAL
        continue
    fi
    
    echo "🔋 Current battery: ${battery_level}%"
    
    if is_charging; then
        echo "🔌 Charging..."
        # Reset notifications when charging
        low_notified=false
        critical_notified=false
    else
        echo "🔋 Discharging..."
        
        # Critical notification (5%)
        if [[ $battery_level -le $BATTERY_CRITICAL ]] && [[ "$critical_notified" == false ]]; then
            notify-send -u critical -t 0 \
                "🚨 CRITICAL BATTERY" \
                "Only ${battery_level}% remaining! System will shutdown soon." \
                -i battery-caution
            
            # Also play alert sound if pactl is available
            if command -v pactl &> /dev/null; then
                pactl play-sample bell-terminal 2>/dev/null || true
            fi
            
            critical_notified=true
            echo "🚨 Critical notification sent"
            
        # Low battery notification (15%)
        elif [[ $battery_level -le $BATTERY_LOW ]] && [[ "$low_notified" == false ]]; then
            notify-send -u normal -t 5000 \
                "⚠️ Low Battery" \
                "${battery_level}% battery remaining." \
                -i battery-low
            
            low_notified=true
            echo "⚠️ Low battery notification sent"
        fi
    fi
    
    sleep $CHECK_INTERVAL
done