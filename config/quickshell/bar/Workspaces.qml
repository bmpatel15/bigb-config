import QtQuick
import Quickshell.Hyprland
import qs.config
import qs.components

// Workspace pills for this bar's monitor. Event-driven via the native
// Hyprland module; special workspaces (id < 0) get an icon only when active.
Row {
    id: root

    required property var barScreen
    readonly property var monitor: Hyprland.monitorFor(barScreen)
    readonly property bool specialActive:
        Hyprland.workspaces.values.some(ws => ws.id < 0 && ws.active)

    spacing: Appearance.spacing.xs

    Repeater {
        model: Hyprland.workspaces.values.filter(ws => ws.id > 0 && ws.monitor === root.monitor)

        delegate: Rectangle {
            id: pill

            required property var modelData
            readonly property bool isActive: modelData.active

            anchors.verticalCenter: parent.verticalCenter
            width: isActive ? 30 : 22
            height: 22
            radius: 11
            color: modelData.urgent ? Appearance.colors.red
                 : isActive ? Appearance.colors.accent
                 : Appearance.colors.accentDim

            Behavior on width {
                NumberAnimation {
                    duration: Appearance.anim.fast
                    easing.type: Appearance.anim.easing
                }
            }
            Behavior on color {
                ColorAnimation {
                    duration: Appearance.anim.fast
                }
            }

            StyledText {
                anchors.centerIn: parent
                text: pill.modelData.id
                font.pixelSize: Appearance.font.small
                color: pill.isActive ? Appearance.colors.bg : Appearance.colors.text
            }

            MouseArea {
                anchors.fill: parent
                onClicked: pill.modelData.activate()
            }
        }
    }

    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.specialActive
        text: "󰐃"
        color: Appearance.colors.mauve
    }

    WheelHandler {
        onWheel: event => Hyprland.dispatch(
            "workspace " + (event.angleDelta.y > 0 ? "e-1" : "e+1"))
    }
}
