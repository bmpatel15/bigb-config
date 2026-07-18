import QtQuick
import Quickshell.Hyprland
import qs.config
import qs.components

// Workspaces + submap indicator + active window title.
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

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            visible: text !== ""
            text: Hyprland.activeToplevel?.title ?? ""
            color: Appearance.colors.muted
            width: Math.min(implicitWidth, 420)
            elide: Text.ElideRight
        }
    }
}
