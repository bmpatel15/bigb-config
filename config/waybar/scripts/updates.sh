#!/usr/bin/env bash
# Waybar module: pending Arch updates (repo via checkupdates + AUR via yay).
repo=$(checkupdates 2>/dev/null | wc -l)
aur=$(yay -Qua 2>/dev/null | wc -l)
total=$((repo + aur))

if [ "$total" -gt 0 ]; then
	printf '{"text":"󰚰 %s","tooltip":"%s repo + %s AUR updates available","class":"has-updates"}\n' \
		"$total" "$repo" "$aur"
else
	printf '{"text":"","tooltip":"System up to date","class":"up-to-date"}\n'
fi
