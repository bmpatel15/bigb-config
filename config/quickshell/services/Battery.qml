pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    readonly property var device: UPower.displayDevice
    readonly property bool ready: device !== null && device.ready && device.isLaptopBattery

    // Docs describe percentage as energy/energyCapacity (a 0-1 fraction);
    // normalize defensively in case the daemon reports 0-100.
    readonly property int percent: {
        if (!ready)
            return 0;
        const p = device.percentage;
        return Math.round(p <= 1.0 ? p * 100 : p);
    }

    readonly property bool charging: ready
        && (device.state === UPowerDeviceState.Charging
            || device.state === UPowerDeviceState.FullyCharged
            || device.state === UPowerDeviceState.PendingCharge)
    readonly property bool low: ready && !charging && percent <= 15
    readonly property bool critical: ready && !charging && percent <= 5
}
