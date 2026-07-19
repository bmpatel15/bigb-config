import QtQuick
import Quickshell.Hyprland
import qs.config
import qs.components

// Five fixed workspace circles for this bar's monitor:
//   active                     → filled peach
//   occupied (has windows)     → peach ring, transparent centre
//   empty                      → solid blue (accent)
// Hyprland destroys empty non-active workspaces, so a workspace that exists
// in the model and isn't active necessarily has windows on it. Event-driven.
Row {
    id: root

    required property var barScreen
    readonly property var monitor: Hyprland.monitorFor(barScreen)
    property bool specialActive: false

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activespecial")
                root.specialActive = event.data.split(",")[0] !== "";
        }
    }

    spacing: Appearance.spacing.sm

    Repeater {
        model: 5

        delegate: Item {
            id: slot

            required property int index
            readonly property int wsId: index + 1
            readonly property var ws: Hyprland.workspaces.values.find(w => w.id === slot.wsId) ?? null
            readonly property bool isActive: (root.monitor?.activeWorkspace?.id ?? -1) === slot.wsId
            readonly property bool occupied: slot.ws !== null && !slot.isActive

            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16

            Rectangle {
                id: dot

                anchors.centerIn: parent
                width: slot.isActive ? 14 : 11
                height: width
                radius: width / 2

                color: slot.isActive ? Appearance.colors.peach
                    : slot.occupied ? "transparent"
                    : Appearance.colors.accent
                border.width: slot.occupied ? 2 : 0
                border.color: Appearance.colors.peach

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
                Behavior on border.width {
                    NumberAnimation {
                        duration: Appearance.anim.fast
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                // Hyprland runs a Lua config, so IPC dispatches are evaluated
                // as Lua — the dispatcher is hl.dsp.focus, not the plain
                // "workspace N" string.
                onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + slot.wsId + " })")
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
        onWheel: event => {
            const cur = root.monitor?.activeWorkspace?.id ?? 1;
            const target = Math.max(1, Math.min(5, cur + (event.angleDelta.y > 0 ? -1 : 1)));
            Hyprland.dispatch("hl.dsp.focus({ workspace = " + target + " })");
        }
    }
}
