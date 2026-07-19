regdom:
	iw reg set IN
	echo 'options cfg80211 ieee80211_regdom=IN' > /etc/modprobe.d/regdom.conf

wifi: regdom
	iw dev "$$(iw dev | awk '$$1=="Interface"{print $$2}')" set power_save off || true
	install -Dm644 $(RIYA)/nmconf/wifi-powersave.conf /etc/NetworkManager/conf.d/wifi-powersave.conf
	install -Dm644 $(RIYA)/nmconf/iwlmvm.conf /etc/modprobe.d/iwlmvm.conf
	@CONN=$$(nmcli -t -f NAME,TYPE connection show --active | grep wifi | cut -d: -f1); \
	if [ -n "$$CONN" ]; then \
		echo "[+] Active Wi-Fi connection: $$CONN"; \
		nmcli connection modify "$$CONN" 802-11-wireless.band a || true; \
		nmcli connection up "$$CONN" || true; \
	fi
	mkinitcpio -P
	@echo "[+] Done. Reboot recommended."
