import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services

// One notification, used by both the popup stack (popup: true, runs its
// own expiry timer) and the history center.
Rectangle {
    id: card

    property var notif: null
    property bool popup: false

    readonly property var defaultAction: notif
        ? (notif.actions.find(a => a.identifier === "default") ?? null)
        : null
    readonly property string iconSource: {
        if (!notif)
            return "";
        if (notif.image !== "")
            return notif.image;
        if (notif.appIcon !== "")
            return notif.appIcon.startsWith("/")
                ? "file://" + notif.appIcon
                : Quickshell.iconPath(notif.appIcon, true);
        return "";
    }

    implicitHeight: contentRow.implicitHeight + 2 * Appearance.spacing.md
    radius: Appearance.radius.popup
    color: Qt.rgba(6 / 255, 11 / 255, 30 / 255, 0.92)
    border.width: 1
    border.color: notif && notif.urgency === NotificationUrgency.Critical
        ? Appearance.colors.redAlt
        : Qt.rgba(125 / 255, 130 / 255, 217 / 255, 0.45)

    // Popup auto-hide: swaync-compatible timeouts (8 s normal, 4 s low,
    // never for critical), client expireTimeout wins when provided.
    Timer {
        interval: {
            if (!card.notif)
                return 0;
            if (card.notif.expireTimeout > 0)
                return card.notif.expireTimeout * 1000;
            if (card.notif.urgency === NotificationUrgency.Critical)
                return 0;
            return card.notif.urgency === NotificationUrgency.Low ? 4000 : 8000;
        }
        running: card.popup && interval > 0
        onTriggered: Notifs.removePopup(card.notif)
    }

    // Card-level click: default action, else dismiss. Sits under the
    // action buttons' own MouseAreas.
    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (card.defaultAction)
                card.defaultAction.invoke();
            else if (card.notif)
                card.notif.dismiss();
        }
    }

    Row {
        id: contentRow

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Appearance.spacing.md
        spacing: Appearance.spacing.sm

        IconImage {
            visible: card.iconSource !== ""
            source: card.iconSource
            implicitSize: 40
            asynchronous: true
        }

        Column {
            width: parent.width - (card.iconSource !== "" ? 40 + Appearance.spacing.sm : 0)
            spacing: Appearance.spacing.xs

            Item {
                width: parent.width
                implicitHeight: appLabel.implicitHeight

                StyledText {
                    id: appLabel
                    anchors.left: parent.left
                    anchors.right: closeBtn.left
                    text: card.notif?.appName ?? ""
                    font.pixelSize: Appearance.font.small
                    color: Appearance.colors.muted
                    elide: Text.ElideRight
                }

                StyledText {
                    id: closeBtn
                    anchors.right: parent.right
                    text: "󰅖"
                    font.pixelSize: Appearance.font.small
                    color: closeMouse.containsMouse
                        ? Appearance.colors.redAlt
                        : Appearance.colors.muted

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        onClicked: card.notif?.dismiss()
                    }
                }
            }

            StyledText {
                width: parent.width
                text: card.notif?.summary ?? ""
                color: Appearance.colors.peach
                font.weight: 600
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }

            StyledText {
                visible: text !== ""
                width: parent.width
                text: card.notif?.body ?? ""
                color: Appearance.colors.text
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }

            Row {
                visible: (card.notif?.actions.length ?? 0) > 0
                spacing: Appearance.spacing.xs

                Repeater {
                    model: card.notif?.actions ?? []

                    delegate: Rectangle {
                        required property var modelData

                        implicitWidth: actionLabel.implicitWidth + 2 * Appearance.spacing.sm
                        implicitHeight: 26
                        radius: Appearance.radius.small
                        color: actionMouse.containsMouse
                            ? Appearance.colors.accentDim
                            : Qt.rgba(1, 1, 1, 0.06)

                        StyledText {
                            id: actionLabel
                            anchors.centerIn: parent
                            text: parent.modelData.text
                            font.pixelSize: Appearance.font.small
                            color: Appearance.colors.accentLight
                        }

                        MouseArea {
                            id: actionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: parent.modelData.invoke()
                        }
                    }
                }
            }
        }
    }
}
