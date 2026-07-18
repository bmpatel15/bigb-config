import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.components
import qs.services

// Notification history panel (SUPER+N). Esc / click-outside closes.
PanelWindow {
    id: root

    visible: Notifs.centerOpen
    anchors {
        top: true
        right: true
    }
    margins {
        top: Appearance.spacing.sm
        right: Appearance.spacing.sm
    }
    implicitWidth: 420
    implicitHeight: card.implicitHeight
    color: "transparent"
    focusable: true

    HyprlandFocusGrab {
        windows: [root]
        active: root.visible
        onCleared: Notifs.centerOpen = false
    }

    Rectangle {
        id: card

        anchors.fill: parent
        radius: Appearance.radius.island
        color: Qt.rgba(6 / 255, 11 / 255, 30 / 255, 0.94)
        border.width: 1
        border.color: Appearance.colors.border
        implicitHeight: content.implicitHeight + 2 * Appearance.spacing.lg

        focus: true
        Keys.onEscapePressed: Notifs.centerOpen = false

        Column {
            id: content

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Appearance.spacing.lg
            spacing: Appearance.spacing.md

            Item {
                width: parent.width
                implicitHeight: 30

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Notifications"
                    font.pixelSize: Appearance.font.large
                    font.weight: 600
                    color: Appearance.colors.peach
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Appearance.spacing.sm

                    Rectangle {
                        implicitWidth: 30
                        implicitHeight: 30
                        radius: Appearance.radius.small
                        color: Notifs.dnd ? Appearance.colors.accentDim
                            : dndMouse.containsMouse ? Appearance.colors.hover
                            : "transparent"

                        StyledText {
                            anchors.centerIn: parent
                            text: Notifs.dnd ? "󰂛" : "󰂚"
                            color: Notifs.dnd ? Appearance.colors.accentLight : Appearance.colors.muted
                        }

                        MouseArea {
                            id: dndMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Notifs.toggleDnd()
                        }
                    }

                    Rectangle {
                        visible: Notifs.count > 0
                        implicitWidth: clearLabel.implicitWidth + 2 * Appearance.spacing.sm
                        implicitHeight: 30
                        radius: Appearance.radius.small
                        color: clearMouse.containsMouse ? Appearance.colors.hover : "transparent"

                        StyledText {
                            id: clearLabel
                            anchors.centerIn: parent
                            text: "Clear all"
                            font.pixelSize: Appearance.font.small
                            color: Appearance.colors.mauve
                        }

                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Notifs.clearAll()
                        }
                    }
                }
            }

            StyledText {
                visible: Notifs.count === 0
                anchors.horizontalCenter: parent.horizontalCenter
                text: "No notifications"
                color: Appearance.colors.muted
            }

            ListView {
                visible: Notifs.count > 0
                width: parent.width
                implicitHeight: Math.min(contentHeight, 560)
                clip: true
                spacing: Appearance.spacing.sm
                model: [...Notifs.history.values].reverse()

                delegate: NotificationCard {
                    required property var modelData

                    width: ListView.view.width
                    notif: modelData
                }
            }
        }
    }
}
