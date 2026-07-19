import QtQuick
import qs.config
import qs.components
import qs.services

Item {
    id: root

    Column {
        anchors.centerIn: parent
        spacing: Appearance.spacing.md

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Weather.icon
            font.pixelSize: 92
            color: Appearance.colors.accentLight
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Weather.ready ? Weather.tempF + "°F" : "—"
            font.pixelSize: 48
            font.weight: 700
            color: Appearance.colors.peach
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Weather.ready ? Weather.desc : "loading…"
            font.pixelSize: Appearance.font.large
            color: Appearance.colors.text
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: Weather.ready
            text: "Feels " + Weather.feelsF + "°F   ·   Humidity " + Weather.humidity + "%"
            font.pixelSize: Appearance.font.base
            color: Appearance.colors.muted
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: Weather.area !== ""
            text: "󰍎  " + Weather.area
            font.pixelSize: Appearance.font.small
            color: Appearance.colors.muted
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: refreshLabel.implicitWidth + 2 * Appearance.spacing.md
            height: 30
            radius: Appearance.radius.small
            color: refreshMouse.containsMouse ? Appearance.colors.hover : Qt.rgba(1, 1, 1, 0.05)

            StyledText {
                id: refreshLabel
                anchors.centerIn: parent
                text: Weather.busy ? "refreshing…" : "󰑐  Refresh"
                font.pixelSize: Appearance.font.small
                color: Appearance.colors.accentLight
            }
            MouseArea {
                id: refreshMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Weather.refresh()
            }
        }
    }
}
