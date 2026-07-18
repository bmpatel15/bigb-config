import QtQuick
import Quickshell.Services.Mpris
import qs.config
import qs.components

// Compact now-playing card, hidden when nothing can play.
Rectangle {
    id: root

    readonly property var player: {
        const ps = Mpris.players.values;
        return ps.find(p => p.isPlaying) ?? ps.find(p => p.canTogglePlaying) ?? null;
    }

    visible: player !== null
    implicitHeight: visible ? 56 : 0
    radius: Appearance.radius.module
    color: Qt.rgba(1, 1, 1, 0.05)

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Appearance.spacing.md
        spacing: Appearance.spacing.xs
        width: parent.width - controls.width - 2 * Appearance.spacing.md

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            spacing: 0

            StyledText {
                text: root.player?.trackTitle ?? ""
                color: Appearance.colors.peach
                width: parent.width
                elide: Text.ElideRight
            }

            StyledText {
                visible: text !== ""
                text: root.player?.trackArtist ?? ""
                font.pixelSize: Appearance.font.small
                color: Appearance.colors.muted
                width: parent.width
                elide: Text.ElideRight
            }
        }
    }

    Row {
        id: controls
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: Appearance.spacing.sm
        spacing: Appearance.spacing.xs

        Repeater {
            model: [
                { glyph: "󰒮", act: () => root.player?.previous(), on: root.player?.canGoPrevious ?? false },
                { glyph: root.player?.isPlaying ? "󰏤" : "󰐊", act: () => root.player?.togglePlaying(), on: root.player?.canTogglePlaying ?? false },
                { glyph: "󰒭", act: () => root.player?.next(), on: root.player?.canGoNext ?? false }
            ]

            delegate: Rectangle {
                required property var modelData

                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 30
                implicitHeight: 30
                radius: Appearance.radius.small
                color: btnMouse.containsMouse ? Appearance.colors.hover : "transparent"
                opacity: modelData.on ? 1 : 0.35

                StyledText {
                    anchors.centerIn: parent
                    text: parent.modelData.glyph
                    font.pixelSize: Appearance.font.large
                    color: Appearance.colors.peach
                }

                MouseArea {
                    id: btnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: parent.modelData.on
                    onClicked: parent.modelData.act()
                }
            }
        }
    }
}
