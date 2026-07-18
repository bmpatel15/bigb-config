import QtQuick
import qs.config

// Quick-settings chip: icon over a short label, filled peach when active.
Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property bool active: false

    signal clicked()

    implicitHeight: 54
    radius: Appearance.radius.module
    color: active ? Appearance.colors.peach
         : mouse.containsMouse ? Appearance.colors.hover
         : Qt.rgba(1, 1, 1, 0.05)

    Behavior on color {
        ColorAnimation {
            duration: Appearance.anim.fast
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 2

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.icon
            font.pixelSize: Appearance.font.large
            color: root.active ? Appearance.colors.bg : Appearance.colors.peach
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            font.pixelSize: Appearance.font.small
            color: root.active ? Appearance.colors.bg : Appearance.colors.muted
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
