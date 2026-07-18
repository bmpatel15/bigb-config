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

    // Click-through actions (match old Waybar on-click behavior)
    readonly property var cpuMonitorCmd: ["ghostty", "-e", "htop"]
    readonly property var memMonitorCmd: ["ghostty", "-e", "btop"]
    readonly property var networkTuiCmd: ["ghostty", "--class=com.ethereal.NetTui", "-e", "gazelle"]
    readonly property var bluetoothTuiCmd: ["ghostty", "--class=com.ethereal.BtTui", "-e", "bluetui"]
    readonly property var mixerCmd: ["pavucontrol"]
    readonly property var updateNowCmd: ["ghostty", "-e", "sh", "-c", "yay -Syu; read -p 'Done. Press enter.'"]
}
