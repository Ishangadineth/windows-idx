#!/bin/bash

# Cloudflared download කිරීම
if [ ! -f "./cf" ]; then
    echo "Downloading Cloudflared..."
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cf
    chmod +x cf
fi

# Windows Emulator එක background එකේ start කිරීම
echo "Starting Windows Emulator..."
qemu-system-x86_64 -m 4G -smp 2 -drive file=/var/win11.qcow2,format=qcow2 -vnc :0 &

# Cloudflare Tunnel එක start කිරීම
echo "Starting Cloudflare Tunnel..."
./cf tunnel --url tcp://localhost:5900
