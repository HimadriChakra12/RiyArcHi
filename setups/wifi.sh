#!/usr/bin/env bash
set -e
sudo pacman -S iw wireless_tools
sudo pacman -S iperf3

echo "[*] Detecting Wi-Fi interface..."
IFACE=$(iw dev | awk '$1=="Interface"{print $2}')

if [[ -z "$IFACE" ]]; then
    echo "[-] No Wi-Fi interface detected."
    exit 1
fi

echo "[+] Interface detected: $IFACE"

echo "[*] Disabling runtime power saving..."
iw dev "$IFACE" set power_save off || true

echo "[*] Configuring NetworkManager power saving..."
mkdir -p /etc/NetworkManager/conf.d
cat > /etc/NetworkManager/conf.d/wifi-powersave.conf <<EOF
[connection]
wifi.powersave = 2
EOF

echo "[*] Forcing Intel iwlmvm performance mode..."
cat > /etc/modprobe.d/iwlmvm.conf <<EOF
options iwlmvm power_scheme=1
EOF

echo "[*] Checking active connection..."
CONN=$(nmcli -t -f NAME,TYPE connection show --active | grep wifi | cut -d: -f1)

if [[ -n "$CONN" ]]; then
    echo "[+] Active Wi-Fi connection: $CONN"
    echo "[*] Forcing 5GHz band preference..."
    nmcli connection modify "$CONN" 802-11-wireless.band a || true
    nmcli connection up "$CONN" || true
fi

echo "[*] Rebuilding initramfs..."
mkinitcpio -P

echo "[+] Done. Reboot recommended."

#!/usr/bin/env bash
set -e

echo "[*] Detecting Wi-Fi interface..."
IFACE=$(iw dev | awk '$1=="Interface"{print $2}')

if [[ -z "$IFACE" ]]; then
    echo "[-] No Wi-Fi interface detected."
    exit 1
fi

echo "[+] Interface detected: $IFACE"

echo "[*] Disabling runtime power saving..."
iw dev "$IFACE" set power_save off || true

echo "[*] Configuring NetworkManager power saving..."
mkdir -p /etc/NetworkManager/conf.d
cat > /etc/NetworkManager/conf.d/wifi-powersave.conf <<EOF
[connection]
wifi.powersave = 2
EOF

echo "[*] Forcing Intel iwlmvm performance mode..."
cat > /etc/modprobe.d/iwlmvm.conf <<EOF
options iwlmvm power_scheme=1
EOF

echo "[*] Checking active connection..."
CONN=$(nmcli -t -f NAME,TYPE connection show --active | grep wifi | cut -d: -f1)

if [[ -n "$CONN" ]]; then
    echo "[+] Active Wi-Fi connection: $CONN"
    echo "[*] Forcing 5GHz band preference..."
    nmcli connection modify "$CONN" 802-11-wireless.band a || true
    nmcli connection up "$CONN" || true
fi

echo "[*] Rebuilding initramfs..."
mkinitcpio -P

echo "[+] Done. Reboot recommended."
