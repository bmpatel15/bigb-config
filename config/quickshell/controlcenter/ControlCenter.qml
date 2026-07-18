import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Networking
import qs.config
import qs.components
import qs.services

// Compact quick-settings panel anchored below the bar's right edge.
// SUPER+D or `qs ipc call controlcenter toggle`. Esc / click-outside closes.
PanelWindow {
    id: root

    visible: false
    anchors {
        top: true
        right: true
    }
    margins {
        top: Appearance.spacing.sm
        right: Appearance.spacing.sm
    }
    implicitWidth: 380
    implicitHeight: card.implicitHeight
    color: "transparent"
    focusable: true

    property bool nightlightOn: false

    function toggle() {
        visible = !visible;
        if (visible)
            nightCheck.running = true;
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.visible
        onCleared: root.visible = false
    }

    Process {
        id: nightCheck
        command: Paths.nightlightCheckCmd
        onExited: exitCode => root.nightlightOn = exitCode === 0
    }

    Timer {
        id: nightRecheck
        interval: 400
        onTriggered: nightCheck.running = true
    }

    Rectangle {
        id: card

        anchors.fill: parent
        radius: Appearance.radius.island
        color: Qt.rgba(6 / 255, 11 / 255, 30 / 255, 0.94)
        border.width: 1
        border.color: Appearance.colors.border
        implicitHeight: col.implicitHeight + 2 * Appearance.spacing.lg

        focus: true
        Keys.onEscapePressed: root.visible = false

        Column {
            id: col

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Appearance.spacing.lg
            spacing: Appearance.spacing.md

            Row {
                id: chipRow
                width: parent.width
                spacing: Appearance.spacing.sm
                readonly property real chipW: (width - 3 * spacing) / 4

                ToggleChip {
                    width: chipRow.chipW
                    icon: "󰖩"
                    label: "Wi-Fi"
                    active: Networking.wifiEnabled
                    onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                }

                ToggleChip {
                    width: chipRow.chipW
                    icon: Bluetooth.powered ? "󰂯" : "󰂲"
                    label: "Bluetooth"
                    active: Bluetooth.powered
                    onClicked: Bluetooth.togglePower()
                }

                ToggleChip {
                    width: chipRow.chipW
                    icon: "󱩌"
                    label: "Night"
                    active: root.nightlightOn
                    onClicked: {
                        Quickshell.execDetached([Paths.nightlightScript]);
                        nightRecheck.restart();
                    }
                }

                ToggleChip {
                    width: chipRow.chipW
                    icon: PowerProfiles.profile === PowerProfile.Performance ? "󰓅"
                        : PowerProfiles.profile === PowerProfile.PowerSaver ? "󰾆"
                        : "󰾅"
                    label: PowerProfiles.profile === PowerProfile.Performance ? "Perf"
                        : PowerProfiles.profile === PowerProfile.PowerSaver ? "Saver"
                        : "Balanced"
                    active: PowerProfiles.profile === PowerProfile.Performance
                    onClicked: {
                        if (PowerProfiles.profile === PowerProfile.Balanced)
                            PowerProfiles.profile = PowerProfiles.hasPerformanceProfile
                                ? PowerProfile.Performance
                                : PowerProfile.PowerSaver;
                        else if (PowerProfiles.profile === PowerProfile.Performance)
                            PowerProfiles.profile = PowerProfile.PowerSaver;
                        else
                            PowerProfiles.profile = PowerProfile.Balanced;
                    }
                }
            }

            Row {
                width: parent.width
                spacing: Appearance.spacing.sm

                StyledText {
                    id: volIcon
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    text: Audio.muted ? "󰝟"
                        : Audio.volume > 0.66 ? "󰕾"
                        : Audio.volume > 0.33 ? "󰖀"
                        : "󰕿"
                    color: Audio.muted ? Appearance.colors.muted : Appearance.colors.peach

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Audio.toggleMute()
                    }
                }

                QsSlider {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - volIcon.width - micBtn.width - 2 * Appearance.spacing.sm
                    value: Audio.volume
                    fillColor: Audio.muted ? Appearance.colors.muted : Appearance.colors.peach
                    onMoved: newValue => Audio.setVolume(newValue)
                }

                Rectangle {
                    id: micBtn
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 30
                    implicitHeight: 30
                    radius: Appearance.radius.small
                    color: micMouse.containsMouse ? Appearance.colors.hover : "transparent"

                    StyledText {
                        anchors.centerIn: parent
                        text: Audio.micMuted ? "󰍭" : "󰍬"
                        color: Audio.micMuted ? Appearance.colors.red : Appearance.colors.peach
                    }

                    MouseArea {
                        id: micMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Audio.toggleMicMute()
                    }
                }
            }

            Row {
                width: parent.width
                spacing: Appearance.spacing.sm
                visible: Brightness.available

                StyledText {
                    id: briIcon
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    text: "󰃞"
                    color: Appearance.colors.yellow
                }

                QsSlider {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - briIcon.width - Appearance.spacing.sm
                    value: Brightness.percent / 100
                    fillColor: Appearance.colors.yellow
                    onMoved: newValue => Brightness.set(Math.round(newValue * 100) + "%")
                }
            }

            MediaCard {
                width: parent.width
            }

            Rectangle {
                width: parent.width
                implicitHeight: 1
                color: Appearance.colors.border
            }

            WifiSection {
                width: parent.width
            }

            BluetoothSection {
                width: parent.width
            }

            Rectangle {
                width: parent.width
                implicitHeight: 1
                color: Appearance.colors.border
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Appearance.spacing.md

                Repeater {
                    model: [
                        { glyph: "󰌾", cmd: Paths.lockCmd, danger: false },
                        { glyph: "󰒲", cmd: Paths.suspendCmd, danger: false },
                        { glyph: "󰍃", cmd: Paths.logoutCmd, danger: false },
                        { glyph: "󰜉", cmd: Paths.rebootCmd, danger: true },
                        { glyph: "󰐥", cmd: Paths.poweroffCmd, danger: true }
                    ]

                    delegate: Rectangle {
                        required property var modelData

                        implicitWidth: 44
                        implicitHeight: 36
                        radius: Appearance.radius.small
                        color: sessMouse.containsMouse ? Appearance.colors.hover : "transparent"

                        StyledText {
                            anchors.centerIn: parent
                            text: parent.modelData.glyph
                            font.pixelSize: Appearance.font.large
                            color: parent.modelData.danger
                                ? Appearance.colors.red
                                : Appearance.colors.peach
                        }

                        MouseArea {
                            id: sessMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.visible = false;
                                Quickshell.execDetached(parent.modelData.cmd);
                            }
                        }
                    }
                }
            }
        }
    }
}
