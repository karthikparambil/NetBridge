#!/bin/bash

# ==========================
# Kali Hotspot Setup Script
# ==========================

# Configuration
HOTSPOT_IF="wlan0"          # Built-in Wi-Fi adapter
INTERNET_IF="wlan1"         # TP-Link adapter connected to Internet
SSID="KaliHotspot"
PASSWORD="Password123"

echo "[+] Restarting NetworkManager..."
sudo systemctl restart NetworkManager

echo "[+] Removing old hotspot (if any)..."
sudo nmcli connection delete Hotspot >/dev/null 2>&1

echo "[+] Creating hotspot..."
sudo nmcli device wifi hotspot \
    ifname "$HOTSPOT_IF" \
    ssid "$SSID" \
    password "$PASSWORD"

echo "[+] Configuring IPv4 sharing..."
sudo nmcli connection modify Hotspot ipv4.method shared

echo "[+] Restarting hotspot..."
sudo nmcli connection down Hotspot >/dev/null 2>&1
sudo nmcli connection up Hotspot

echo "[+] Enabling IPv4 forwarding..."
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward >/dev/null

echo "[+] Adding NAT rule..."
sudo iptables -t nat -C POSTROUTING -s 10.42.0.0/24 -o "$INTERNET_IF" -j MASQUERADE 2>/dev/null || \
sudo iptables -t nat -A POSTROUTING -s 10.42.0.0/24 -o "$INTERNET_IF" -j MASQUERADE

echo "[+] Adding forwarding rules..."
sudo iptables -C FORWARD -i "$INTERNET_IF" -o "$HOTSPOT_IF" -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || \
sudo iptables -A FORWARD -i "$INTERNET_IF" -o "$HOTSPOT_IF" -m state --state RELATED,ESTABLISHED -j ACCEPT

sudo iptables -C FORWARD -i "$HOTSPOT_IF" -o "$INTERNET_IF" -j ACCEPT 2>/dev/null || \
sudo iptables -A FORWARD -i "$HOTSPOT_IF" -o "$INTERNET_IF" -j ACCEPT

echo
echo "========== STATUS =========="
nmcli connection show Hotspot | grep ipv4.method
echo
echo "IP Forwarding: $(cat /proc/sys/net/ipv4/ip_forward)"
echo
echo "Testing Internet..."
ping -c 4 8.8.8.8

echo
echo "=========================================="
echo "Hotspot Name : $SSID"
echo "Password     : $PASSWORD"
echo "Hotspot IF   : $HOTSPOT_IF"
echo "Internet IF  : $INTERNET_IF"
echo "=========================================="