import QtQuick
import Quickshell
import qs.config
import qs.components
import qs.services

Item {
    id: root

    property var dashboard

    function run(cmd) {
        if (root.dashboard)
            root.dashboard.close();
        Quickshell.execDetached(cmd);
    }

    Column {
        anchors.centerIn: parent
        spacing: Appearance.spacing.lg

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Session"
            font.pixelSize: Appearance.font.large
            font.weight: 600
            color: Appearance.colors.peach
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Appearance.spacing.lg

            Repeater {
                model: [
                    { glyph: "󰌾", label: "Lock", cmd: Paths.lockCmd, danger: false },
                    { glyph: "󰒲", label: "Suspend", cmd: Paths.suspendCmd, danger: false },
                    { glyph: "󰍃", label: "Logout", cmd: Paths.logoutCmd, danger: false },
                    { glyph: "󰜉", label: "Reboot", cmd: Paths.rebootCmd, danger: true },
                    { glyph: "󰐥", label: "Shutdown", cmd: Paths.poweroffCmd, danger: true }
                ]

                delegate: Rectangle {
                    required property var modelData
                    width: 84
                    height: 84
                    radius: Appearance.radius.module
                    color: sMouse.containsMouse ? Appearance.colors.hover : Qt.rgba(1, 1, 1, 0.05)

                    Column {
                        anchors.centerIn: parent
                        spacing: Appearance.spacing.sm

                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: parent.parent.modelData.glyph
                            font.pixelSize: 28
                            color: parent.parent.modelData.danger ? Appearance.colors.red : Appearance.colors.peach
                        }
                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: parent.parent.modelData.label
                            font.pixelSize: Appearance.font.small
                            color: Appearance.colors.muted
                        }
                    }

                    MouseArea {
                        id: sMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.run(parent.modelData.cmd)
                    }
                }
            }
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: SysInfo.user + "@" + SysInfo.host + "   ·   up " + SysInfo.uptimeText
            font.pixelSize: Appearance.font.small
            color: Appearance.colors.muted
        }
    }
}
