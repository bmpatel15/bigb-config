import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.config
import qs.components
import qs.services

// Six equal cards in a 3×2 grid:
//   time    | weather  | avatar
//   meters  | calendar | media
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

    GridLayout {
        anchors.fill: parent
        columns: 3
        rowSpacing: Appearance.spacing.md
        columnSpacing: Appearance.spacing.md

        // ── Top-left: time ───────────────────────────────────────────────
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Column {
                anchors.centerIn: parent
                spacing: -6

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "HH")
                    font.pixelSize: 52
                    font.weight: 700
                    color: Appearance.colors.peach
                }
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "mm")
                    font.pixelSize: 52
                    font.weight: 700
                    color: Appearance.colors.mauve
                }
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    topPadding: 10
                    text: Qt.formatDateTime(clock.date, "ddd, MMM dd")
                    font.pixelSize: Appearance.font.small
                    color: Appearance.colors.muted
                }
            }
        }

        // ── Top-middle: weather ──────────────────────────────────────────
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Column {
                anchors.centerIn: parent
                spacing: Appearance.spacing.xs

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Weather.icon
                    font.pixelSize: 46
                    color: Appearance.colors.accentLight
                }
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Weather.ready ? Weather.tempF + "°F" : "—"
                    font.pixelSize: 28
                    font.weight: 700
                    color: Appearance.colors.text
                }
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Weather.ready ? Weather.desc : "loading"
                    font.pixelSize: Appearance.font.small
                    color: Appearance.colors.muted
                }
            }
        }

        // ── Top-right: avatar / profile ──────────────────────────────────
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Row {
                anchors.centerIn: parent
                spacing: Appearance.spacing.md

                ClippingRectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 54
                    height: 54
                    radius: 27
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
                    spacing: 2

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
                        text: "󰅐  up " + SysInfo.uptimeShort
                        font.pixelSize: Appearance.font.small
                        color: Appearance.colors.muted
                    }
                }
            }
        }

        // ── Bottom-left: usage meters ────────────────────────────────────
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true

            StatBars {
                anchors.fill: parent
            }
        }

        // ── Bottom-middle: calendar ──────────────────────────────────────
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Fit the month grid to the card: header (28) + weekday row (18)
            // + two 8px gaps = 62 of fixed chrome; the rest splits across the
            // six week rows.
            CalendarView {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                cellHeight: Math.max(16, (parent.height - 62) / 6)
            }
        }

        // ── Bottom-right: media ──────────────────────────────────────────
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Column {
                anchors.centerIn: parent
                visible: root.player === null
                spacing: Appearance.spacing.xs

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "󰝛"
                    font.pixelSize: 34
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
                spacing: Appearance.spacing.sm

                ClippingRectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(parent.width, parent.height - 44)
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
                        font.pixelSize: 32
                        color: Appearance.colors.muted
                    }
                }

                StyledText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: root.player?.trackTitle ?? ""
                    font.pixelSize: Appearance.font.small
                    font.weight: 600
                    color: Appearance.colors.text
                    elide: Text.ElideRight
                }
                StyledText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: root.player?.trackArtist ?? ""
                    font.pixelSize: Appearance.font.small
                    color: Appearance.colors.muted
                    elide: Text.ElideRight
                }
            }
        }
    }
}
