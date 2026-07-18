#!/usr/bin/env bash
set -e

echo "===== THINKPAD T480s FINAL BOSS THERMAL SETUP ====="

# ------------------------------------------------
# Remove TLP and conflicts
# ------------------------------------------------
echo "== Removing TLP & unmasking power-profiles-daemon =="
sudo systemctl disable tlp.service 2>/dev/null || true
sudo pacman -Rns --noconfirm tlp tlp-rdw 2>/dev/null || true

sudo systemctl unmask power-profiles-daemon.service 2>/dev/null || true
sudo rm -f /etc/systemd/system/power-profiles-daemon.service 2>/dev/null || true
sudo systemctl daemon-reload

# ------------------------------------------------
# Install required packages
# ------------------------------------------------
echo "== Installing required packages =="
sudo pacman -S --needed --noconfirm \
    power-profiles-daemon \
    thermald \
    acpid \
    intel-undervolt \
    lm_sensors

# ------------------------------------------------
# Enable services
# ------------------------------------------------
echo "== Enabling services =="
sudo systemctl enable power-profiles-daemon.service
sudo systemctl enable thermald.service
sudo systemctl enable acpid.service
sudo systemctl enable intel-undervolt.service

sudo systemctl start power-profiles-daemon.service
sudo systemctl start thermald.service
sudo systemctl start acpid.service

# ------------------------------------------------
# Default profile
# ------------------------------------------------
powerprofilesctl set balanced

# ------------------------------------------------
# Safe undervolt + smooth power limits
# ------------------------------------------------
echo "== Applying Final Boss undervolt & PL tuning =="

sudo tee /etc/intel-undervolt.conf > /dev/null <<EOF
undervolt 0 'CPU' -70
undervolt 1 'GPU' -40
undervolt 2 'CPU Cache' -70
undervolt 3 'System Agent' -20
undervolt 4 'Analog I/O' -20

power package 18000 28000
EOF

sudo systemctl restart intel-undervolt.service

# ------------------------------------------------
# Aggressive thermald trigger at 80C
# ------------------------------------------------
echo "== Configuring thermald for earlier cooling =="

sudo mkdir -p /etc/thermald
sudo tee /etc/thermald/thermal-conf.xml > /dev/null <<EOF
<ThermalConfiguration>
  <Platform>
    <Name>ThinkPad T480s</Name>
    <ProductName>*</ProductName>
  </Platform>

  <ThermalZones>
    <ThermalZone>
      <Type>cpu</Type>
      <TripPoints>
        <TripPoint>
          <Temperature>80000</Temperature>
          <Type>passive</Type>
        </TripPoint>
      </TripPoints>
    </ThermalZone>
  </ThermalZones>
</ThermalConfiguration>
EOF

sudo systemctl restart thermald.service

# ------------------------------------------------
# Auto switch profile AC/BAT
# ------------------------------------------------
echo "== Setting AC auto profile switching =="

sudo tee /etc/acpi/events/ac_adapter > /dev/null <<EOF
event=ac_adapter
action=/etc/acpi/ac_adapter.sh
EOF

sudo tee /etc/acpi/ac_adapter.sh > /dev/null <<EOF
#!/bin/bash

if grep -q 1 /sys/class/power_supply/AC/online; then
    powerprofilesctl set performance
else
    powerprofilesctl set balanced
fi
EOF

sudo chmod +x /etc/acpi/ac_adapter.sh
sudo systemctl restart acpid

# ------------------------------------------------
# Early fan ramp (ThinkPad specific)
# ------------------------------------------------
echo "== Enabling early fan ramp script =="

sudo tee /usr/local/bin/t480s-fan-control.sh > /dev/null <<EOF
#!/bin/bash

TEMP=\$(awk '{print \$1}' /sys/class/thermal/thermal_zone0/temp)
TEMP=\$((TEMP/1000))

if [ "\$TEMP" -ge 85 ]; then
    echo level 7 | tee /proc/acpi/ibm/fan
elif [ "\$TEMP" -ge 75 ]; then
    echo level 5 | tee /proc/acpi/ibm/fan
else
    echo level auto | tee /proc/acpi/ibm/fan
fi
EOF

sudo chmod +x /usr/local/bin/t480s-fan-control.sh

sudo tee /etc/systemd/system/t480s-fan.service > /dev/null <<EOF
[Unit]
Description=T480s Smart Fan Control

[Service]
ExecStart=/bin/bash -c 'while true; do /usr/local/bin/t480s-fan-control.sh; sleep 5; done'

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable t480s-fan.service
sudo systemctl start t480s-fan.service

# ------------------------------------------------
# Battery thresholds
# ------------------------------------------------
echo "== Setting battery threshold 40-85 =="

if [ -d /sys/class/power_supply/BAT0 ]; then
    echo 0 | sudo tee /sys/class/power_supply/BAT0/charge_start_threshold
    echo 95 | sudo tee /sys/class/power_supply/BAT0/charge_stop_threshold
fi

# ------------------------------------------------
# Intel iGPU power saving
# ------------------------------------------------
echo "options i915 enable_psr=1 enable_fbc=1" | \
sudo tee /etc/modprobe.d/i915-power.conf

echo
echo "================================================"
echo "FINAL BOSS MODE ENABLED"
echo "PL1: 18W sustained"
echo "PL2: 28W burst"
echo "Undervolt: -70mV core/cache"
echo "Fan ramps at 75C"
echo "Thermald active at 80C"
echo "AC: Performance"
echo "BAT: Balanced"
echo "================================================"
echo "Reboot recommended."
