import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// Toast stack, top-right, matching the old SwayNC geometry (width 420).
PanelWindow {
    visible: Notifs.popups.length > 0
    anchors {
        top: true
        right: true
    }
    margins {
        top: Appearance.spacing.sm
        right: Appearance.spacing.sm
    }
    implicitWidth: 420
    // Floor of 1: a zero-height layer surface is a protocol error and the
    // compositor drops it (first frame races the Repeater's delegates).
    implicitHeight: Math.max(1, stack.implicitHeight)
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay

    Column {
        id: stack
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Appearance.spacing.sm

        Repeater {
            model: Notifs.popups

            delegate: NotificationCard {
                required property var modelData

                width: parent.width
                notif: modelData
                popup: true
            }
        }
    }
}
