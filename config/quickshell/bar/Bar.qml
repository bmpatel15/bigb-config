import QtQuick
import Quickshell
import qs.config

// One bar per screen (instantiated by the Variants block in shell.qml).
// Three anchors (top/left/right) + Auto exclusion mode reserve
// height + top margin, matching the old Waybar geometry.
PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        top: Appearance.bar.marginTop
        left: Appearance.bar.marginSide
        right: Appearance.bar.marginSide
    }
    implicitHeight: Appearance.bar.height
    color: "transparent"

    LeftIsland {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        barScreen: root.screen
    }

    CenterIsland {
        id: centerIsland
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
    }

    MediaIsland {
        anchors.right: centerIsland.left
        anchors.rightMargin: Appearance.spacing.sm
        anchors.verticalCenter: parent.verticalCenter
    }

    RightIsland {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
    }
}
