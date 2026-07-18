import QtQuick
import Quickshell.Services.Mpris
import qs.config
import qs.components

// Appears only while a player exists; fades without moving the clock.
// Click toggles play/pause, scroll skips tracks.
Island {
    id: root

    readonly property var player: {
        const ps = Mpris.players.values;
        return ps.find(p => p.isPlaying) ?? ps.find(p => p.canTogglePlaying) ?? null;
    }

    visible: opacity > 0
    opacity: player !== null ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: Appearance.anim.normal
            easing.type: Appearance.anim.easing
        }
    }

    // WrapperRectangle sizes exactly one child, so content + MouseArea share
    // this Item.
    Item {
        implicitWidth: row.implicitWidth
        implicitHeight: row.implicitHeight

        Row {
            id: row
            anchors.verticalCenter: parent.verticalCenter
            spacing: Appearance.spacing.xs

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.player?.isPlaying ? "󰐊" : "󰏤"
                color: Appearance.colors.accent
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    const p = root.player;
                    if (!p)
                        return "";
                    return p.trackArtist !== ""
                        ? p.trackTitle + " · " + p.trackArtist
                        : p.trackTitle;
                }
                color: Appearance.colors.text
                width: Math.min(implicitWidth, 320)
                elide: Text.ElideRight
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.player?.togglePlaying()
            onWheel: wheel => {
                const p = root.player;
                if (!p)
                    return;
                if (wheel.angleDelta.y > 0 && p.canGoPrevious)
                    p.previous();
                else if (wheel.angleDelta.y < 0 && p.canGoNext)
                    p.next();
            }
        }
    }
}
