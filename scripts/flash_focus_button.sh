#!/usr/bin/env bash
#
# flash_focus_button.sh — flash Focus Button firmware from macOS / Linux.
#
# This is the macOS counterpart to the Windows in-app firmware updater
# (FocusButtonApp/FirmwareUpdater.cs). It mirrors the same safe flow:
#
#   1. Find the Focus Button's USB-serial port.
#   2. Detect the chip over the ROM bootloader (ESP32-S3 = M5Dial "M50",
#      ESP32-C3 = VIEWE "C30").
#   3. Refuse to flash a firmware.bin built for a different chip (the image
#      header carries the chip id), so you can't brick the wrong board.
#   4. (Optional) back up the current app image first.
#   5. Write firmware.bin at the application offset 0x10000.
#
# A normal upgrade only rewrites the application at 0x10000; the bootloader
# (0x0) and partition table (0x8000) do not change between releases, and a
# failed write at 0x10000 never touches the bootloader, so the device stays
# recoverable by simply re-running this script.
#
# Requirements: esptool (pip install esptool, or `brew install esptool`).
#
# Usage:
#   tools/flash_focus_button.sh --bin path/to/firmware.bin [options]
#
# Options:
#   --bin PATH       Application image to flash (firmware.bin). Required.
#   --port PORT      Serial port (default: auto-detect /dev/cu.usbmodem* or
#                    /dev/ttyACM* / /dev/ttyUSB*).
#   --baud RATE      Flashing baud rate (default: 921600).
#   --backup         Read the current app region to backup-<timestamp>.bin first.
#   --full DIR       Full flash: also write DIR/bootloader.bin @ 0x0 and
#                    DIR/partitions.bin @ 0x8000 (DIR must also contain
#                    firmware.bin). Use only for a blank/bricked board.
#   --esptool CMD    esptool command to use (default: esptool.py, then esptool).
#   -h, --help       Show this help.
#
set -euo pipefail

BIN=""
PORT=""
BAUD=921600
DO_BACKUP=0
FULL_DIR=""
ESPTOOL=""
APP_OFFSET=0x10000
BOOTLOADER_OFFSET=0x0
PARTITIONS_OFFSET=0x8000
# Generous span to back up the app partition (covers typical 3 MB app slots).
BACKUP_SIZE=0x300000

err()  { printf '\033[31m%s\033[0m\n' "$*" >&2; }
info() { printf '\033[36m%s\033[0m\n' "$*"; }
ok()   { printf '\033[32m%s\033[0m\n' "$*"; }

usage() { sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --bin)     BIN="$2"; shift 2 ;;
    --port)    PORT="$2"; shift 2 ;;
    --baud)    BAUD="$2"; shift 2 ;;
    --backup)  DO_BACKUP=1; shift ;;
    --full)    FULL_DIR="$2"; shift 2 ;;
    --esptool) ESPTOOL="$2"; shift 2 ;;
    -h|--help) usage 0 ;;
    *) err "Unknown argument: $1"; usage 1 ;;
  esac
done

# ---- locate esptool --------------------------------------------------------
if [ -z "$ESPTOOL" ]; then
  if command -v esptool.py >/dev/null 2>&1; then ESPTOOL="esptool.py";
  elif command -v esptool >/dev/null 2>&1; then ESPTOOL="esptool";
  else err "esptool not found. Install it: pip install esptool  (or brew install esptool)"; exit 1;
  fi
fi

# ---- resolve the firmware image --------------------------------------------
if [ -n "$FULL_DIR" ]; then
  BIN="$FULL_DIR/firmware.bin"
fi
if [ -z "$BIN" ]; then err "Missing --bin path/to/firmware.bin"; usage 1; fi
if [ ! -f "$BIN" ]; then err "Firmware image not found: $BIN"; exit 1; fi

# ---- auto-detect the serial port -------------------------------------------
if [ -z "$PORT" ]; then
  for p in /dev/cu.usbmodem* /dev/cu.usbserial* /dev/ttyACM* /dev/ttyUSB*; do
    [ -e "$p" ] && { PORT="$p"; break; }
  done
  [ -z "$PORT" ] && { err "No serial port found. Plug in the Focus Button or pass --port."; exit 1; }
  info "Auto-detected port: $PORT"
fi

# ---- read the chip id out of the image header ------------------------------
# ESP image: byte 0 == 0xE9 (magic); chip_id is a little-endian uint16 at byte 12.
read_image_chip_id() {
  local f="$1"
  local magic b12 b13
  magic=$(od -An -tx1 -N1 "$f" | tr -d ' \n')
  [ "$magic" = "e9" ] || { echo "NONE"; return; }
  b12=$(od -An -tx1 -j12 -N1 "$f" | tr -d ' \n')
  b13=$(od -An -tx1 -j13 -N1 "$f" | tr -d ' \n')
  echo "0x${b13}${b12}"   # little-endian -> high byte first
}

chip_name_for_image_id() {
  case "$1" in
    0x0000) echo "ESP32" ;;
    0x0002) echo "ESP32-S2" ;;
    0x0005) echo "ESP32-C3" ;;
    0x0009) echo "ESP32-S3" ;;
    0x000d) echo "ESP32-C6" ;;
    *)      echo "UNKNOWN" ;;
  esac
}

IMAGE_CHIP_ID=$(read_image_chip_id "$BIN")
IMAGE_CHIP=$(chip_name_for_image_id "$IMAGE_CHIP_ID")
info "Firmware image: $BIN"
info "  image chip id: $IMAGE_CHIP_ID ($IMAGE_CHIP)"

# ---- detect the connected chip ---------------------------------------------
info "Detecting connected chip on $PORT ..."
DETECT_OUT=$("$ESPTOOL" --port "$PORT" flash_id 2>&1) || { err "$DETECT_OUT"; err "Could not talk to the bootloader. Is the Focus Button plugged in?"; exit 1; }
DETECTED_CHIP=$(printf '%s\n' "$DETECT_OUT" | grep -ioE 'ESP32(-[A-Z0-9]+)?' | head -1)
[ -z "$DETECTED_CHIP" ] && { err "Could not determine chip type from esptool output:"; err "$DETECT_OUT"; exit 1; }

case "$DETECTED_CHIP" in
  ESP32-S3) HW="M50 (M5Dial)" ;;
  ESP32-C3) HW="C30 (VIEWE ESP32-C3-MD50E)" ;;
  *)        HW="(unknown board)" ;;
esac
ok "Detected $DETECTED_CHIP — $HW"

# ---- guard: image must match the connected chip ----------------------------
if [ "$IMAGE_CHIP" != "UNKNOWN" ] && [ "$IMAGE_CHIP" != "$DETECTED_CHIP" ]; then
  err "Refusing to flash: image is for $IMAGE_CHIP but the connected board is $DETECTED_CHIP."
  err "Use the firmware.bin built for $DETECTED_CHIP (m5stack-stamps3 = ESP32-S3, lcd_c3 = ESP32-C3)."
  exit 1
fi

# ---- optional backup of the current app image ------------------------------
if [ "$DO_BACKUP" = "1" ]; then
  TS=$(date +%Y%m%d-%H%M%S)
  BK="backup-app-${DETECTED_CHIP}-${TS}.bin"
  info "Backing up current app region ($APP_OFFSET, $BACKUP_SIZE) to $BK ..."
  "$ESPTOOL" --port "$PORT" --baud "$BAUD" read_flash "$APP_OFFSET" "$BACKUP_SIZE" "$BK"
  ok "Backup saved: $BK (restore with: $ESPTOOL --port $PORT write_flash $APP_OFFSET $BK)"
fi

# ---- flash -----------------------------------------------------------------
# --before default_reset works for both classic UART bridges and the native
# USB-Serial/JTAG on S3/C3. --after hard_reset reboots straight into the app.
WRITE_ARGS=( --port "$PORT" --baud "$BAUD" --before default_reset --after hard_reset write_flash )
if [ -n "$FULL_DIR" ]; then
  info "Full flash from $FULL_DIR (bootloader + partitions + app) ..."
  "$ESPTOOL" "${WRITE_ARGS[@]}" \
    "$BOOTLOADER_OFFSET" "$FULL_DIR/bootloader.bin" \
    "$PARTITIONS_OFFSET" "$FULL_DIR/partitions.bin" \
    "$APP_OFFSET" "$FULL_DIR/firmware.bin"
else
  info "Flashing app image at $APP_OFFSET ..."
  "$ESPTOOL" "${WRITE_ARGS[@]}" "$APP_OFFSET" "$BIN"
fi

ok "Done. The Focus Button should reboot into the new firmware."
echo "Tip: confirm the version with  GET|FIRMWAREVER  over the serial port (expect FIRMWAREVER|${HW%% *}-<version>)."
