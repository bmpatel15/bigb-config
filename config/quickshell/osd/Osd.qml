import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.components
import qs.services
import qs.osd

// Bottom-center overlay for volume / mic / brightness hardware keys.
PanelWindow {
    id: root

    visible: OsdState.shown
    anchors.bottom: true
    margins.bottom: 96
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    implicitWidth: 320
    implicitHeight: 56
    color: "transparent"

    readonly property bool isVolume: OsdState.kind === "volume"
    readonly property bool isMic: OsdState.kind === "mic"

    Rectangle {
        anchors.fill: parent
        radius: Appearance.radius.island
        color: Qt.rgba(6 / 255, 11 / 255, 30 / 255, 0.92)
        border.width: 1
        border.color: Appearance.colors.border

        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Appearance.spacing.lg
            anchors.rightMargin: Appearance.spacing.lg
            spacing: Appearance.spacing.md

            StyledText {
                id: osdIcon
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: Appearance.font.title
                text: root.isMic ? (Audio.micMuted ? "󰍭" : "󰍬")
                    : root.isVolume ? (Audio.muted ? "󰝟"
                        : Audio.volume > 0.66 ? "󰕾"
                        : Audio.volume > 0.33 ? "󰖀"
                        : "󰕿")
                    : "󰃞"
                color: root.isMic && Audio.micMuted ? Appearance.colors.red
                    : root.isVolume && Audio.muted ? Appearance.colors.muted
                    : Appearance.colors.peach
            }

            QsSlider {
                visible: !root.isMic
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - osdIcon.width - osdLabel.width - 2 * Appearance.spacing.md
                interactive: false
                value: root.isVolume ? Audio.volume : Brightness.percent / 100
                fillColor: root.isVolume && Audio.muted
                    ? Appearance.colors.muted
                    : Appearance.colors.peach
            }

            StyledText {
                id: osdLabel
                anchors.verticalCenter: parent.verticalCenter
                width: root.isMic ? implicitWidth : 42
                horizontalAlignment: Text.AlignRight
                text: root.isMic ? (Audio.micMuted ? "Microphone muted" : "Microphone on")
                    : root.isVolume ? Math.round(Audio.volume * 100) + "%"
                    : Brightness.percent + "%"
                color: Appearance.colors.text
            }
        }
    }
}
