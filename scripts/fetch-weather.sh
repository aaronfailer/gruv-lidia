#!/bin/bash
CONFIG_FILE="$HOME/.config/quickshell/weather_location.json"

if [ -n "$1" ]; then
  LAT="$1"
  LON="$2"
  NAME="$3"
elif [ -f "$CONFIG_FILE" ]; then
  LAT=$(jq -r '.lat' "$CONFIG_FILE")
  LON=$(jq -r '.lon' "$CONFIG_FILE")
  NAME=$(jq -r '.name' "$CONFIG_FILE")
else
  LAT="-38.95"
  LON="-67.92"
  NAME="Gral. Fernández Oro"
fi

curl -s "https://api.open-meteo.com/v1/forecast?latitude=$LAT&longitude=$LON&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation_probability,weather_code,wind_speed_10m&hourly=temperature_2m,precipitation_probability,weather_code,wind_speed_10m&daily=temperature_2m_max,temperature_2m_min,weather_code,precipitation_probability_max,wind_speed_10m_max&timezone=auto&forecast_days=7" | jq -c "{current: .current, hourly: .hourly, daily: .daily, location: \"$NAME\", lat: $LAT, lon: $LON}"
