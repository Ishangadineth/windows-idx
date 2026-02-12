#!/usr/bin/env bash
set -e

### CONFIG ###
ISO_URL="https://go.microsoft.com/fwlink/p/?LinkID=2195443"
ISO_FILE="win11-gamer.iso"

DISK_FILE="/var/win11.qcow2"
DISK_SIZE="64G"

RAM="4G" # IDX එකේ stable වැඩ කිරීමට 4G නිර්දේශ කරයි
CORES="2"

VNC_DISPLAY=":0"
FLAG_FILE="installed.flag"
WORKDIR="$HOME/windows-idx"
CF_BIN="./cf"

### CHECK ###
command -v qemu-system-x86_64 >/dev/null || { echo "❌ No qemu"; exit 1; }

### PREP ###
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# Disk එක නැත්නම් සාදන්න
[ -f "$DISK_FILE" ] || qemu-img create -f qcow2 "$DISK_FILE" "$DISK_SIZE"

# Windows ISO එක download කිරීම
if [ ! -f "$FLAG_FILE" ]; then
  [ -f "$ISO_FILE" ] || {
    echo "📥 Downloading Windows ISO..."
    wget --no-check-certificate -O "$ISO_FILE" "$ISO_URL"
  }
fi

############################
# CLOUDFLARE TUNNEL SETUP  #
############################
if [ ! -f "$CF_BIN" ]; then
    echo "📥 Downloading Cloudflared..."
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cf
    chmod +x cf
fi

# පරණ tunnels නවත්වන්න
pkill -f "./cf tunnel" || true

echo "🌍 Starting Cloudflare Tunnel..."
./cf tunnel --url tcp://localhost:5900 > cloudflare.log 2>&1 &
sleep 5

# Cloudflare Link එක සොයා ගැනීම
CF_URL=$(grep -oE 'https://[a-zA-Z0-9.-]+\.trycloudflare\.com' cloudflare.log | head -n 1)

echo "-------------------------------------------------------"
echo "🌍 VNC PUBLIC LINK : $CF_URL"
echo "👉 Use this link in your Local PC PowerShell command"
echo "-------------------------------------------------------"

#################
# RUN QEMU      #
#################
if [ ! -f "$FLAG_FILE" ]; then
  echo "⚠️  CHẾ ĐỘ CÀI ĐẶT WINDOWS (Installation Mode)"
  echo "👉 Cài xong quay lại nhập: xong"

  qemu-system-x86_64 \
    -m "$RAM" \
    -smp "$CORES" \
    -drive file="$DISK_FILE",format=qcow2 \
    -cdrom "$ISO_FILE" \
    -boot order=d \
    -vnc "$VNC_DISPLAY" \
    -usb -device usb-tablet &

  QEMU_PID=$!

  while true; do
    read -rp "👉 Nhập 'xong' sau khi cài đặt hoàn සිය: " DONE
    if [ "$DONE" = "xong" ]; then
      touch "$FLAG_FILE"
      kill "$QEMU_PID"
      pkill -f "./cf tunnel"
      rm -f "$ISO_FILE"
      echo "✅ Hoàn tất – Windows install වී අවසන්. නැවත run.sh run කරන්න."
      exit 0
    fi
  done

else
  echo "✅ Windows đã cài – boot thường (Normal Boot)"

  qemu-system-x86_64 \
    -m "$RAM" \
    -smp "$CORES" \
    -drive file="$DISK_FILE",format=qcow2 \
    -boot order=c \
    -vnc "$VNC_DISPLAY" \
    -usb -device usb-tablet
fi
