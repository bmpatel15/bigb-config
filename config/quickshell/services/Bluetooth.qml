pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth as QsBt

// Namespaced import: this singleton is itself named Bluetooth, which would
// otherwise shadow the native Bluetooth singleton.
Singleton {
    readonly property var adapter: QsBt.Bluetooth.defaultAdapter ?? null
    readonly property bool available: adapter !== null
    readonly property bool powered: available && adapter.enabled

    readonly property var connectedDevices: QsBt.Bluetooth.devices.values.filter(d => d.connected)
    readonly property int connectedCount: connectedDevices.length
    readonly property string firstDeviceName: connectedCount > 0
        ? (connectedDevices[0].name !== "" ? connectedDevices[0].name : connectedDevices[0].deviceName)
        : ""

    function togglePower() {
        if (available)
            adapter.enabled = !adapter.enabled;
    }
}
