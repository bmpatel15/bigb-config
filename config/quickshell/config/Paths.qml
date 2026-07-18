pragma Singleton
import QtQuick
import Quickshell

// Every external command and filesystem path the shell touches, in one place.
// Commands are argv arrays (never shell-interpolated strings with user data).
Singleton {
    readonly property string home: Quickshell.env("HOME") ?? ""
    readonly property string configDir: Quickshell.env("XDG_CONFIG_HOME") ?? (home + "/.config")
    readonly property string cacheDir: Quickshell.env("XDG_CACHE_HOME") ?? (home + "/.cache")

    // Reused script backends (see docs/QUICKSHELL_IMPLEMENTATION_PLAN.md §5)
    readonly property string updatesScript: configDir + "/waybar/scripts/updates.sh"
    readonly property string powerMenuScript: configDir + "/waybar/scripts/power-menu.sh"
    readonly property string nightlightScript: configDir + "/hypr/scripts/nightlight.sh"
    readonly property string lockScript: configDir + "/hypr/scripts/lock.sh"
    readonly property string wallpaperScript: configDir + "/rofi/wallpaper-picker.sh"

    // Wallpaper cache (Stage D — must stay compatible with wallpaper-picker.sh)
    readonly property string wallpaperDir: Quickshell.env("WALLPAPER_DIR") ?? (home + "/Pictures/wallpaper")
    readonly property string wallpaperThumbDir: cacheDir + "/wallpaper-picker/thumbs"
    readonly property string wallpaperStateFile: cacheDir + "/wallpaper-picker/current"

    // Command argv arrays
    readonly property var brightnessGetCmd: ["brightnessctl", "-m"]
    function brightnessSetCmd(spec) {
        return ["brightnessctl", "-e4", "-n2", "-m", "set", spec];
    }
    readonly property var powerProfileGetCmd: ["powerprofilesctl", "get"]
    function powerProfileSetCmd(profile) {
        return ["powerprofilesctl", "set", profile];
    }

    // Session actions (mirror waybar/scripts/power-menu.sh, incl. its
    // lock-before-suspend wait so the desktop never flashes on resume)
    readonly property var lockCmd: [lockScript]
    readonly property var suspendCmd: ["sh", "-c",
        "\"$1\" & for _ in $(seq 1 50); do pgrep -x hyprlock >/dev/null && break; sleep 0.1; done; systemctl suspend",
        "sh", lockScript]
    readonly property var logoutCmd: ["hyprctl", "dispatch", "exit"]
    readonly property var rebootCmd: ["systemctl", "reboot"]
    readonly property var poweroffCmd: ["systemctl", "poweroff"]
    readonly property var nightlightCheckCmd: ["pidof", "hyprsunset"]

    // Click-through actions (match old Waybar on-click behavior)
    readonly property var cpuMonitorCmd: ["ghostty", "-e", "htop"]
    readonly property var memMonitorCmd: ["ghostty", "-e", "btop"]
    readonly property var networkTuiCmd: ["ghostty", "--class=com.ethereal.NetTui", "-e", "gazelle"]
    readonly property var bluetoothTuiCmd: ["ghostty", "--class=com.ethereal.BtTui", "-e", "bluetui"]
    readonly property var mixerCmd: ["pavucontrol"]
    readonly property var updateNowCmd: ["ghostty", "-e", "sh", "-c", "yay -Syu; read -p 'Done. Press enter.'"]
}
