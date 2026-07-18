pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking

// Connection state derived from NetworkManager devices (0.3.0 has no
// primary-connection property; QML dependency tracking keeps this reactive).
Singleton {
    readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wiredDevice: Networking.devices.values.find(d => d.type === DeviceType.Wired) ?? null

    readonly property bool ethernet: wiredDevice !== null && wiredDevice.connected
    readonly property bool wifi: wifiDevice !== null && wifiDevice.connected
    readonly property bool connected: ethernet || wifi

    readonly property var activeWifiNetwork: wifi
        ? (wifiDevice.networks.values.find(n => n.connected) ?? null)
        : null
    readonly property string ssid: activeWifiNetwork?.name ?? ""
    readonly property real strength: activeWifiNetwork?.signalStrength ?? 0 // 0.0-1.0

    readonly property string icon: {
        if (ethernet)
            return "󰈀";
        if (!wifi)
            return "󰤮";
        if (strength > 0.8)
            return "󰤨";
        if (strength > 0.6)
            return "󰤥";
        if (strength > 0.4)
            return "󰤢";
        if (strength > 0.2)
            return "󰤟";
        return "󰤯";
    }
}
