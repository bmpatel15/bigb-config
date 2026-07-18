import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import qs.config
import qs.components
import qs.services

// Status cluster: updates · cpu/mem · power profile · network · bluetooth ·
// audio · mic-when-muted · backlight · battery · tray · power button.
Island {
    id: root

    Row {
        spacing: 2

        StatusItem {
            anchors.verticalCenter: parent.verticalCenter
            visible: Updates.count > 0
            icon: "󰚰"
            iconColor: Appearance.colors.yellow
            label: Updates.count
            onClicked: Quickshell.execDetached(Paths.updateNowCmd)
        }

        StatusItem {
            anchors.verticalCenter: parent.verticalCenter
            icon: "󰍛"
            iconColor: Appearance.colors.cyan
            label: SysStats.cpuPerc + "% " + SysStats.memPerc + "%"
            onClicked: Quickshell.execDetached(Paths.cpuMonitorCmd)
            onSecondaryClicked: Quickshell.execDetached(Paths.memMonitorCmd)
        }

        StatusItem {
            anchors.verticalCenter: parent.verticalCenter
            readonly property var prof: PowerProfiles.profile
            icon: prof === PowerProfile.Performance ? "󰓅"
                : prof === PowerProfile.PowerSaver ? "󰾆"
                : "󰾅"
            iconColor: prof === PowerProfile.Performance
                ? Appearance.colors.orange
                : Appearance.colors.muted
            onClicked: {
                if (prof === PowerProfile.Balanced)
                    PowerProfiles.profile = PowerProfiles.hasPerformanceProfile
                        ? PowerProfile.Performance
                        : PowerProfile.PowerSaver;
                else if (prof === PowerProfile.Performance)
                    PowerProfiles.profile = PowerProfile.PowerSaver;
                else
                    PowerProfiles.profile = PowerProfile.Balanced;
            }
        }

        StatusItem {
            anchors.verticalCenter: parent.verticalCenter
            icon: Network.icon
            iconColor: Network.connected ? Appearance.colors.accent : Appearance.colors.muted
            onClicked: Quickshell.execDetached(Paths.networkTuiCmd)
        }

        StatusItem {
            anchors.verticalCenter: parent.verticalCenter
            icon: Bluetooth.powered
                ? (Bluetooth.connectedCount > 0 ? "󰂱" : "󰂯")
                : "󰂲"
            iconColor: Bluetooth.powered ? Appearance.colors.accent : Appearance.colors.muted
            label: Bluetooth.connectedCount > 1 ? Bluetooth.connectedCount : ""
            onClicked: Quickshell.execDetached(Paths.bluetoothTuiCmd)
        }

        StatusItem {
            anchors.verticalCenter: parent.verticalCenter
            icon: Audio.muted ? "󰝟"
                : Audio.volume > 0.66 ? "󰕾"
                : Audio.volume > 0.33 ? "󰖀"
                : "󰕿"
            iconColor: Audio.muted ? Appearance.colors.muted : Appearance.colors.peach
            label: Math.round(Audio.volume * 100) + "%"
            onClicked: Audio.toggleMute()
            onSecondaryClicked: Quickshell.execDetached(Paths.mixerCmd)
            onScrolled: delta => delta > 0 ? Audio.incVolume() : Audio.decVolume()
        }

        StatusItem {
            anchors.verticalCenter: parent.verticalCenter
            visible: Audio.micMuted
            icon: "󰍭"
            iconColor: Appearance.colors.red
            onClicked: Audio.toggleMicMute()
        }

        StatusItem {
            anchors.verticalCenter: parent.verticalCenter
            visible: Brightness.available
            icon: "󰃞"
            iconColor: Appearance.colors.yellow
            label: Brightness.percent + "%"
            onScrolled: delta => delta > 0 ? Brightness.inc() : Brightness.dec()
        }

        StatusItem {
            anchors.verticalCenter: parent.verticalCenter
            visible: Battery.ready
            icon: Battery.charging ? "󰂄"
                : Battery.percent > 90 ? "󰁹"
                : Battery.percent > 70 ? "󰂀"
                : Battery.percent > 50 ? "󰁾"
                : Battery.percent > 30 ? "󰁼"
                : Battery.percent > 15 ? "󰁻"
                : "󰁺"
            iconColor: Battery.critical ? Appearance.colors.red
                : Battery.low ? Appearance.colors.yellow
                : Battery.charging ? Appearance.colors.green
                : Appearance.colors.peach
            label: Battery.percent + "%"
        }

        Repeater {
            model: SystemTray.items.values

            delegate: Rectangle {
                id: trayCell

                required property var modelData

                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: Appearance.bar.height - 2 * Appearance.spacing.xs
                implicitHeight: Appearance.bar.height - 2 * Appearance.spacing.xs
                radius: Appearance.radius.module
                color: trayMouse.containsMouse ? Appearance.colors.hover : "transparent"

                IconImage {
                    anchors.centerIn: parent
                    source: trayCell.modelData.icon
                    implicitSize: 16
                    asynchronous: true
                }

                QsMenuAnchor {
                    id: trayMenu
                    menu: trayCell.modelData.menu
                    anchor.window: trayCell.QsWindow.window
                    anchor.item: trayCell
                    anchor.edges: Edges.Bottom | Edges.Left
                    anchor.gravity: Edges.Bottom | Edges.Right
                }

                MouseArea {
                    id: trayMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: event => {
                        const item = trayCell.modelData;
                        if (event.button === Qt.RightButton || item.onlyMenu) {
                            if (item.hasMenu)
                                trayMenu.open();
                        } else {
                            item.activate();
                        }
                    }
                }
            }
        }

        StatusItem {
            anchors.verticalCenter: parent.verticalCenter
            visible: Notifs.dnd || Notifs.count > 0
            icon: Notifs.dnd ? "󰂛" : "󰂚"
            iconColor: Notifs.dnd ? Appearance.colors.muted : Appearance.colors.peach
            label: !Notifs.dnd && Notifs.count > 0 ? Notifs.count : ""
            onClicked: Notifs.toggleCenter()
            onSecondaryClicked: Notifs.toggleDnd()
        }

        StatusItem {
            anchors.verticalCenter: parent.verticalCenter
            icon: "⏻"
            iconColor: Appearance.colors.red
            onClicked: Quickshell.execDetached([Paths.powerMenuScript])
        }
    }
}
