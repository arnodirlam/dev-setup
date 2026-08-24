#!/bin/zsh

DISPLAY_THRESHOLD=40
LOW_THRESHOLD=20
WARN_THRESHOLD=50

BLUETOOTH_DATA="$(system_profiler SPBluetoothDataType 2>/dev/null)"
ACCESSORY_POWER_DATA="$(pmset -g accps 2>/dev/null)"

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

escape_attr() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//|/-}"
  printf '%s' "$value"
}

icon_for_device() {
  local name_lc="${1:l}"
  local type_lc="${2:l}"

  case "$name_lc" in
    *airpods*|*headphone*|*headset*|*buds*|*beats*)
      printf '%s' ":headphones:"
      return
      ;;
    *speaker*)
      printf '%s' ":hifispeaker.fill:"
      return
      ;;
    *keyboard*)
      printf '%s' ":keyboard.fill:"
      return
      ;;
    *mouse*)
      printf '%s' ":computermouse.fill:"
      return
      ;;
    *trackpad*)
      printf '%s' ":rectangle.and.hand.point.up.left.fill:"
      return
      ;;
  esac

  case "$type_lc" in
    *speaker*)
      printf '%s' ":hifispeaker.fill:"
      ;;
    *mouse*)
      printf '%s' ":computermouse.fill:"
      ;;
    *keyboard*)
      printf '%s' ":keyboard.fill:"
      ;;
    *headset*|*headphone*)
      printf '%s' ":headphones:"
      ;;
    *)
      printf '%s' ":battery.50:"
      ;;
  esac
}

color_for_battery() {
  local percent="$1"

  if ! [[ "$percent" =~ ^[0-9]+$ ]]; then
    printf '%s' "#D1D5DB"
    return
  fi

  if [ "$percent" -le "$LOW_THRESHOLD" ]; then
    printf '%s' "#EF4444"
  elif [ "$percent" -le "$WARN_THRESHOLD" ]; then
    printf '%s' "#EAB308"
  else
    printf '%s' "#22C55E"
  fi
}

DEVICE_LINES="$(
  printf '%s\n' "$BLUETOOTH_DATA" | awk '
    function trim(value) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      return value
    }

    function reset_device() {
      name = ""
      connected = 0
      battery = ""
      minor_type = ""
    }

    function emit_device() {
      if (name != "" && connected) {
        if (battery == "") {
          battery = "--"
        }
        print name "\t" battery "\t" minor_type
      }
    }

    function is_section(value) {
      return value == "Bluetooth" ||
        value == "Bluetooth Controller" ||
        value == "Controller" ||
        value == "Connected" ||
        value == "Not Connected" ||
        value == "Devices" ||
        value ~ /^Devices / ||
        value == "Services" ||
        value == "Incoming Serial Ports" ||
        value == "Outgoing Serial Ports"
    }

    BEGIN {
      section = ""
      reset_device()
    }

    /^[[:space:]]*[^:][^:]*:[[:space:]]*$/ {
      candidate = trim($0)
      sub(/:[[:space:]]*$/, "", candidate)

      if (candidate == "Connected") {
        emit_device()
        section = "connected"
        reset_device()
      } else if (candidate == "Not Connected") {
        emit_device()
        section = "not_connected"
        reset_device()
      } else if (!is_section(candidate)) {
        emit_device()
        name = candidate
        connected = section == "connected" ? 1 : 0
        battery = ""
        minor_type = ""
      }
    }

    /^[[:space:]]*Connected:[[:space:]]*Yes/ {
      connected = 1
    }

    /^[[:space:]]*([[:alpha:] ]+ )?Battery Level:/ {
      if (match($0, /[0-9]+/)) {
        percent = substr($0, RSTART, RLENGTH)
        if (battery == "" || percent + 0 < battery + 0) {
          battery = percent
        }
      }
    }

    /^[[:space:]]*Minor Type:/ {
      minor_type = trim($0)
      sub(/^Minor Type:[[:space:]]*/, "", minor_type)
    }

    END {
      emit_device()
    }
  '
)"

PMSET_LINES="$(
  printf '%s\n' "$ACCESSORY_POWER_DATA" | awk '
    /^ -/ {
      line = $0
      sub(/^[[:space:]]*-/, "", line)
      name = line
      sub(/[[:space:]]*\(id=.*/, "", name)

      if (name == "InternalBattery-0") {
        next
      }

      if (match(line, /[0-9]+%/)) {
        percent = substr(line, RSTART, RLENGTH)
        sub(/%$/, "", percent)
        print name "\t" percent
      }
    }
  '
)"

DEVICE_LINES="$(
  {
    printf '%s\n' "$DEVICE_LINES"
    printf '%s\n' "---PMSET---"
    printf '%s\n' "$PMSET_LINES"
  } | awk -F "\t" '
    $0 == "---PMSET---" {
      pmset = 1
      next
    }

    !pmset && NF >= 2 {
      name = $1
      if (!(name in seen)) {
        seen[name] = 1
        order[++count] = name
      }
      battery[name] = $2
      type[name] = $3
      next
    }

    pmset && NF >= 2 {
      name = $1
      if (!(name in seen)) {
        seen[name] = 1
        order[++count] = name
      }
      battery[name] = $2
      next
    }

    END {
      for (idx = 1; idx <= count; idx++) {
        name = order[idx]
        print name "\t" battery[name] "\t" type[name]
      }
    }
  '
)"

while IFS=$'\t' read -r DEVICE_NAME BATTERY_PERCENT DEVICE_TYPE; do
  [ -n "$DEVICE_NAME" ] || continue
  [ -n "$BATTERY_PERCENT" ] || continue
  [[ "$BATTERY_PERCENT" =~ ^[0-9]+$ ]] || continue
  [ "$BATTERY_PERCENT" -le "$DISPLAY_THRESHOLD" ] || continue
  DISPLAY_BATTERY="${BATTERY_PERCENT}%"
  TOOLTIP_BATTERY="${BATTERY_PERCENT}%"

  ICON="$(icon_for_device "$DEVICE_NAME" "$DEVICE_TYPE")"
  COLOR="$(color_for_battery "$BATTERY_PERCENT")"
  TOOLTIP="$(escape_attr "$DEVICE_NAME: $TOOLTIP_BATTERY")"

  echo "$ICON $DISPLAY_BATTERY | sfcolor=${COLOR} sfsize=13 trim=true tooltip=\"${TOOLTIP}\""
done <<< "$DEVICE_LINES"
