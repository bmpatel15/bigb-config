import QtQuick
import qs.config

// Minimal slider/progress bar. `value` is the displayed 0-1 fill; user
// drags emit moved() and never write `value` directly (callers bind it to
// the authoritative service state).
Item {
    id: root

    property real value: 0
    property bool interactive: true
    property color fillColor: Appearance.colors.peach
    property real trackHeight: 6
    readonly property bool pressed: mouse.pressed

    signal moved(newValue: real)

    implicitHeight: 20

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.trackHeight
        radius: height / 2
        color: Qt.rgba(1, 1, 1, 0.10)
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(height, Math.min(1, root.value) * track.width)
        height: root.trackHeight
        radius: height / 2
        color: root.fillColor

        Behavior on width {
            enabled: !root.pressed
            NumberAnimation {
                duration: Appearance.anim.fast
                easing.type: Appearance.anim.easing
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.interactive
        onPressed: event => root.moved(Math.max(0, Math.min(1, event.x / width)))
        onPositionChanged: event => {
            if (pressed)
                root.moved(Math.max(0, Math.min(1, event.x / width)));
        }
    }
}
