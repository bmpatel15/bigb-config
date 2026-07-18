import QtQuick
import qs.config

// One interactive bar cell: nerd-font icon + optional label, hover feedback,
// click / secondary-click / scroll hooks.
Rectangle {
    id: root

    property alias icon: iconText.text
    property alias label: labelText.text
    property color iconColor: Appearance.colors.peach
    property color labelColor: Appearance.colors.text

    signal clicked()
    signal secondaryClicked()
    signal scrolled(delta: int)

    radius: Appearance.radius.module
    color: mouse.containsMouse ? Appearance.colors.hover : "transparent"
    implicitHeight: Appearance.bar.height - 2 * Appearance.spacing.xs
    implicitWidth: row.implicitWidth + 2 * Appearance.spacing.sm

    Behavior on color {
        ColorAnimation {
            duration: Appearance.anim.fast
            easing.type: Appearance.anim.easing
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Appearance.spacing.xs

        StyledText {
            id: iconText
            anchors.verticalCenter: parent.verticalCenter
            color: root.iconColor
            font.pixelSize: Appearance.font.large
        }

        StyledText {
            id: labelText
            anchors.verticalCenter: parent.verticalCenter
            color: root.labelColor
            visible: text.length > 0
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => {
            if (event.button === Qt.RightButton)
                root.secondaryClicked();
            else
                root.clicked();
        }
        onWheel: wheel => root.scrolled(wheel.angleDelta.y > 0 ? 1 : -1)
    }
}
