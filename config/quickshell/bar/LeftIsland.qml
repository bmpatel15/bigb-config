import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.components

// Arch mark + workspace circles + submap indicator.
Island {
    id: root

    required property var barScreen
    property string submap: ""

    Row {
        spacing: Appearance.spacing.sm

        // Non-visual: inside the Row so the island keeps a single layout child.
        Connections {
            target: Hyprland
            function onRawEvent(event) {
                if (event.name === "submap")
                    root.submap = event.data;
            }
        }

        // Arch logo — click opens the app launcher (like a start button).
        StyledText {
            id: archLogo
            anchors.verticalCenter: parent.verticalCenter
            text: "" // nf-linux-archlinux
            font.pixelSize: Appearance.font.title
            color: archMouse.containsMouse ? Appearance.colors.orange : Appearance.colors.peach

            Behavior on color {
                ColorAnimation {
                    duration: Appearance.anim.fast
                }
            }

            MouseArea {
                id: archMouse
                anchors.fill: parent
                anchors.margins: -Appearance.spacing.xs
                hoverEnabled: true
                onClicked: Quickshell.execDetached(["qs", "ipc", "call", "launcher", "toggle"])
            }
        }

        // Breathing room between the Arch logo and the workspace circles.
        Item {
            width: Appearance.spacing.sm
            height: 1
        }

        Workspaces {
            anchors.verticalCenter: parent.verticalCenter
            barScreen: root.barScreen
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.submap !== ""
            text: root.submap
            color: Appearance.colors.mauve
        }
    }
}
