#!/bin/bash
QUERY="$1"
curl -s "https://geocoding-api.open-meteo.com/v1/search?name=${QUERY// /+}&count=6&language=es&format=json" | jq -c '[.results[] // empty | {lat: .latitude, lon: .longitude, name: .name, country: .country, admin1: .admin1, timezone: .timezone}]'
