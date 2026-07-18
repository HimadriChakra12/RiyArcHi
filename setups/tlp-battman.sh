#!/usr/bin/env bash
set -e

echo "== Installing power management packages =="
sudo pacman -S --needed --noconfirm \
    tlp tlp-rdw thermald powertop cpupower \
    brightnessctl acpi acpid

echo "== Removing power-profiles-daemon (conflicts with TLP) =="
sudo systemctl disable power-profiles-daemon.service 2>/dev/null || true
sudo pacman -Rns --noconfirm power-profiles-daemon 2>/dev/null || true

echo "== Enabling services =="
sudo systemctl enable tlp.service
sudo systemctl enable thermald.service
sudo systemctl enable cpupower.service
sudo systemctl enable acpid.service

echo "== Starting services =="
sudo systemctl start tlp.service
sudo systemctl start thermald.service
sudo systemctl start acpid.service

echo "== Setting CPU governor to schedutil (better thermals) =="
sudo sed -i "s/^#*governor=.*/governor='schedutil'/" /etc/default/cpupower || \
echo "governor='schedutil'" | sudo tee /etc/default/cpupower

sudo systemctl restart cpupower.service

echo "== Enabling Intel iGPU power saving safely =="
echo "options i915 enable_psr=1 enable_fbc=1 enable_guc=2" | \
sudo tee /etc/modprobe.d/i915-power.conf

echo "== Enabling WiFi power saving (NetworkManager) =="
sudo mkdir -p /etc/NetworkManager/conf.d
echo -e "[connection]\nwifi.powersave = 3" | \
sudo tee /etc/NetworkManager/conf.d/wifi-powersave.conf

echo "== Configuring TLP (Balanced thermal profile) =="
sudo tee /etc/tlp.d/99-custom.conf > /dev/null <<EOF
CPU_SCALING_GOVERNOR_ON_AC=schedutil
CPU_SCALING_GOVERNOR_ON_BAT=schedutil

CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power

CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0

SCHED_POWERSAVE_ON_AC=0
SCHED_POWERSAVE_ON_BAT=1

STOP_CHARGE_THRESH_BAT0=85
EOF

sudo tlp start

echo "== Creating Powertop auto-tune service =="
sudo tee /etc/systemd/system/powertop.service > /dev/null <<EOF
[Unit]
Description=Powertop tunings

[Service]
Type=oneshot
ExecStart=/usr/bin/powertop --auto-tune

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable powertop.service

echo "== Done =="
echo "Reboot recommended."
