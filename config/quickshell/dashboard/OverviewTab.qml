import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.config
import qs.components
import qs.services

Item {
    id: root

    readonly property var player: {
        const ps = Mpris.players.values;
        return ps.find(p => p.isPlaying) ?? ps.find(p => p.canTogglePlaying) ?? null;
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    RowLayout {
        anchors.fill: parent
        spacing: Appearance.spacing.md

        // ── Left column: big clock + visualizer ──────────────────────────
        ColumnLayout {
            Layout.preferredWidth: 150
            Layout.fillHeight: true
            spacing: Appearance.spacing.md

            Card {
                Layout.fillWidth: true
                Layout.preferredHeight: 140

                Column {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: -4

                    StyledText {
                        text: Qt.formatDateTime(clock.date, "HH")
                        font.pixelSize: 44
                        font.weight: 700
                        color: Appearance.colors.peach
                    }
                    StyledText {
                        text: Qt.formatDateTime(clock.date, "mm")
                        font.pixelSize: 44
                        font.weight: 700
                        color: Appearance.colors.mauve
                    }
                    StyledText {
                        topPadding: 8
                        text: Qt.formatDateTime(clock.date, "MMM dd")
                        font.pixelSize: Appearance.font.small
                        color: Appearance.colors.muted
                    }
                }
            }

            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Visualizer {
                    anchors.fill: parent
                }
            }
        }

        // ── Right column ─────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Appearance.spacing.md

            // Top row: weather + profile
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 84
                spacing: Appearance.spacing.md

                Card {
                    Layout.preferredWidth: 150
                    Layout.fillHeight: true

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Appearance.spacing.sm

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Weather.icon
                            font.pixelSize: 34
                            color: Appearance.colors.accentLight
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 0
                            StyledText {
                                text: Weather.ready ? Weather.tempF + "°F" : "—"
                                font.pixelSize: Appearance.font.title
                                font.weight: 600
                                color: Appearance.colors.text
                            }
                            StyledText {
                                text: Weather.ready ? Weather.desc : "loading"
                                font.pixelSize: Appearance.font.small
                                color: Appearance.colors.muted
                                width: 96
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                Card {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Appearance.spacing.md

                        ClippingRectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 48
                            height: 48
                            radius: 24
                            color: Appearance.colors.surface

                            Image {
                                anchors.fill: parent
                                source: "file://" + Quickshell.env("HOME") + "/.config/hypr/assets/avatar.png"
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            StyledText {
                                text: SysInfo.user
                                font.pixelSize: Appearance.font.large
                                font.weight: 600
                                color: Appearance.colors.peach
                            }
                            StyledText {
                                text: "@" + SysInfo.host
                                font.pixelSize: Appearance.font.small
                                color: Appearance.colors.muted
                            }
                            StyledText {
                                text: "󰅐  up " + SysInfo.uptimeText
                                font.pixelSize: Appearance.font.small
                                color: Appearance.colors.muted
                            }
                        }
                    }
                }
            }

            // Bottom row: calendar + media
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Appearance.spacing.md

                Card {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    CalendarView {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        cellHeight: 26
                    }
                }

                Card {
                    Layout.preferredWidth: 132
                    Layout.fillHeight: true

                    Item {
                        anchors.fill: parent

                        Column {
                            anchors.centerIn: parent
                            visible: root.player === null
                            spacing: Appearance.spacing.xs

                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "󰝛"
                                font.pixelSize: 30
                                color: Appearance.colors.muted
                            }
                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "No Media"
                                font.pixelSize: Appearance.font.small
                                color: Appearance.colors.muted
                            }
                        }

                        Column {
                            anchors.fill: parent
                            visible: root.player !== null
                            spacing: Appearance.spacing.xs

                            ClippingRectangle {
                                width: parent.width
                                height: width
                                radius: Appearance.radius.small
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
                                    font.pixelSize: 28
                                    color: Appearance.colors.muted
                                }
                            }

                            StyledText {
                                width: parent.width
                                text: root.player?.trackTitle ?? ""
                                font.pixelSize: Appearance.font.small
                                font.weight: 600
                                color: Appearance.colors.text
                                elide: Text.ElideRight
                            }
                            StyledText {
                                width: parent.width
                                text: root.player?.trackArtist ?? ""
                                font.pixelSize: Appearance.font.small
                                color: Appearance.colors.muted
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}
