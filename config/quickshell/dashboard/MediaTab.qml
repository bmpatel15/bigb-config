import QtQuick
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.config
import qs.components

Item {
    id: root

    readonly property var player: {
        const ps = Mpris.players.values;
        return ps.find(p => p.isPlaying) ?? ps.find(p => p.canTogglePlaying) ?? null;
    }

    StyledText {
        anchors.centerIn: parent
        visible: root.player === null
        text: "Nothing playing"
        color: Appearance.colors.muted
    }

    Row {
        anchors.centerIn: parent
        visible: root.player !== null
        spacing: Appearance.spacing.xl

        ClippingRectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 180
            height: 180
            radius: Appearance.radius.module
            color: Appearance.colors.surface

            Image {
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: source != ""
            }
            StyledText {
                anchors.centerIn: parent
                visible: (root.player?.trackArtUrl ?? "") === ""
                text: "󰎈"
                font.pixelSize: 64
                color: Appearance.colors.muted
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: 300
            spacing: Appearance.spacing.sm

            StyledText {
                width: parent.width
                text: root.player?.trackTitle ?? ""
                font.pixelSize: Appearance.font.title
                font.weight: 700
                color: Appearance.colors.peach
                elide: Text.ElideRight
            }
            StyledText {
                width: parent.width
                text: root.player?.trackArtist ?? ""
                font.pixelSize: Appearance.font.large
                color: Appearance.colors.text
                elide: Text.ElideRight
            }
            StyledText {
                width: parent.width
                visible: text !== ""
                text: root.player?.trackAlbum ?? ""
                font.pixelSize: Appearance.font.base
                color: Appearance.colors.muted
                elide: Text.ElideRight
            }

            Item {
                width: 1
                height: Appearance.spacing.md
            }

            Row {
                spacing: Appearance.spacing.lg

                Repeater {
                    model: [
                        { glyph: "󰒮", act: () => root.player?.previous(), on: root.player?.canGoPrevious ?? false },
                        { glyph: root.player?.isPlaying ? "󰏤" : "󰐊", act: () => root.player?.togglePlaying(), on: root.player?.canTogglePlaying ?? false },
                        { glyph: "󰒭", act: () => root.player?.next(), on: root.player?.canGoNext ?? false }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        width: 42
                        height: 42
                        radius: 21
                        color: mMouse.containsMouse ? Appearance.colors.hover : Qt.rgba(1, 1, 1, 0.05)
                        opacity: modelData.on ? 1 : 0.4

                        StyledText {
                            anchors.centerIn: parent
                            text: parent.modelData.glyph
                            font.pixelSize: Appearance.font.title
                            color: Appearance.colors.peach
                        }
                        MouseArea {
                            id: mMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: parent.modelData.on
                            onClicked: parent.modelData.act()
                        }
                    }
                }
            }
        }
    }
}
