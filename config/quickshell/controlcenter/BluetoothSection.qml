import QtQuick
import Quickshell
import Quickshell.Bluetooth as QsBt
import qs.config
import qs.components
import qs.services

// Bluetooth header + expandable paired-device list. Pairing NEW devices
// stays in bluetui (button at the bottom of the list).
Column {
    id: root

    property bool expanded: false

    spacing: Appearance.spacing.xs
    width: parent.width

    Rectangle {
        width: parent.width
        implicitHeight: 40
        radius: Appearance.radius.module
        color: headMouse.containsMouse ? Appearance.colors.hover : "transparent"

        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Appearance.spacing.md
            spacing: Appearance.spacing.sm

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Bluetooth.powered ? (Bluetooth.connectedCount > 0 ? "󰂱" : "󰂯") : "󰂲"
                color: Bluetooth.powered ? Appearance.colors.accent : Appearance.colors.muted
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: !Bluetooth.powered ? "Bluetooth off"
                    : Bluetooth.connectedCount > 0 ? Bluetooth.firstDeviceName
                    : "Bluetooth on"
                color: Appearance.colors.text
            }
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: Appearance.spacing.md
            text: root.expanded ? "󰅃" : "󰅀"
            color: Appearance.colors.muted
        }

        MouseArea {
            id: headMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.expanded = !root.expanded
        }
    }

    Column {
        visible: root.expanded
        width: parent.width
        spacing: 2

        Repeater {
            model: {
                if (!root.expanded)
                    return [];
                const devs = QsBt.Bluetooth.devices.values.filter(d => d.paired);
                devs.sort((a, b) => (b.connected - a.connected)
                    || a.name.localeCompare(b.name));
                return devs;
            }

            delegate: Rectangle {
                id: devEntry

                required property var modelData

                width: parent.width
                implicitHeight: 36
                radius: Appearance.radius.small
                color: devMouse.containsMouse ? Appearance.colors.hover
                    : devEntry.modelData.connected ? Appearance.colors.accentDim
                    : "transparent"

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: Appearance.spacing.md
                    spacing: Appearance.spacing.sm

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰂯"
                        color: devEntry.modelData.connected
                            ? Appearance.colors.accent
                            : Appearance.colors.muted
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: devEntry.modelData.name !== ""
                            ? devEntry.modelData.name
                            : devEntry.modelData.deviceName
                        color: Appearance.colors.text
                        width: 200
                        elide: Text.ElideRight
                    }
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: Appearance.spacing.md
                    spacing: Appearance.spacing.sm

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: devEntry.modelData.batteryAvailable
                            && devEntry.modelData.connected
                        text: Math.round(devEntry.modelData.battery * 100) + "%"
                        font.pixelSize: Appearance.font.small
                        color: Appearance.colors.muted
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: devEntry.modelData.state
                            === QsBt.BluetoothDeviceState.Connecting
                            || devEntry.modelData.state
                            === QsBt.BluetoothDeviceState.Disconnecting
                        text: "…"
                        color: Appearance.colors.muted
                    }
                }

                MouseArea {
                    id: devMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        const dev = devEntry.modelData;
                        if (dev.connected)
                            dev.disconnect();
                        else
                            dev.connect();
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            implicitHeight: 32
            radius: Appearance.radius.small
            color: pairMouse.containsMouse ? Appearance.colors.hover : "transparent"

            StyledText {
                anchors.centerIn: parent
                text: "pair new device (bluetui)"
                font.pixelSize: Appearance.font.small
                color: Appearance.colors.muted
            }

            MouseArea {
                id: pairMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Quickshell.execDetached(Paths.bluetoothTuiCmd)
            }
        }
    }
}
