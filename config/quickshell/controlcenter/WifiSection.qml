import QtQuick
// Namespaced: Quickshell.Networking exports a `Network` TYPE that would
// otherwise shadow the qs.services Network singleton.
import Quickshell.Networking as NM
import qs.config
import qs.components
import qs.services

// Wi-Fi header row + expandable network list. Scanning runs only while
// expanded. Secured unknown networks expand a password field inline.
Column {
    id: root

    property bool expanded: false
    property var pskTarget: null // network awaiting a password

    onExpandedChanged: {
        if (Network.wifiDevice)
            Network.wifiDevice.scannerEnabled = expanded;
        if (!expanded)
            pskTarget = null;
    }

    function strengthIcon(s) {
        if (s > 0.8)
            return "󰤨";
        if (s > 0.6)
            return "󰤥";
        if (s > 0.4)
            return "󰤢";
        if (s > 0.2)
            return "󰤟";
        return "󰤯";
    }

    spacing: Appearance.spacing.xs
    width: parent.width

    Rectangle {
        width: parent.width
        implicitHeight: 40
        radius: Appearance.radius.module
        color: headMouse.containsMouse ? Appearance.colors.hover : "transparent"

        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Appearance.spacing.md
            spacing: Appearance.spacing.sm

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Network.icon
                color: Network.connected ? Appearance.colors.accent : Appearance.colors.muted
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Network.ethernet ? "Wired"
                    : Network.wifi ? Network.ssid
                    : NM.Networking.wifiEnabled ? "Wi-Fi: not connected"
                    : "Wi-Fi off"
                color: Appearance.colors.text
            }
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: Appearance.spacing.md
            text: root.expanded ? "󰅃" : "󰅀"
            color: Appearance.colors.muted
        }

        MouseArea {
            id: headMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.expanded = !root.expanded
        }
    }

    Column {
        visible: root.expanded
        width: parent.width
        spacing: 2

        Repeater {
            model: {
                if (!root.expanded || !Network.wifiDevice)
                    return [];
                const nets = Network.wifiDevice.networks.values.slice();
                nets.sort((a, b) => (b.connected - a.connected)
                    || (b.known - a.known)
                    || (b.signalStrength - a.signalStrength));
                return nets.slice(0, 8);
            }

            delegate: Column {
                id: netEntry

                required property var modelData
                readonly property bool needsPsk: !modelData.known
                    && modelData.security !== NM.WifiSecurityType.Open

                width: parent.width

                Rectangle {
                    width: parent.width
                    implicitHeight: 36
                    radius: Appearance.radius.small
                    color: netMouse.containsMouse ? Appearance.colors.hover
                        : netEntry.modelData.connected ? Appearance.colors.accentDim
                        : "transparent"

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: Appearance.spacing.md
                        spacing: Appearance.spacing.sm

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.strengthIcon(netEntry.modelData.signalStrength)
                            color: Appearance.colors.accent
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: netEntry.modelData.name
                            color: Appearance.colors.text
                            width: 200
                            elide: Text.ElideRight
                        }
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: Appearance.spacing.md
                        spacing: Appearance.spacing.sm

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: netEntry.modelData.security !== NM.WifiSecurityType.Open
                            text: "󰌾"
                            font.pixelSize: Appearance.font.small
                            color: Appearance.colors.muted
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: netEntry.modelData.connected
                                || netEntry.modelData.stateChanging
                            text: netEntry.modelData.stateChanging ? "…" : "✓"
                            color: Appearance.colors.green
                        }
                    }

                    MouseArea {
                        id: netMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            const net = netEntry.modelData;
                            if (net.connected)
                                return;
                            if (netEntry.needsPsk)
                                root.pskTarget = root.pskTarget === net ? null : net;
                            else
                                net.connect();
                        }
                    }
                }

                Rectangle {
                    visible: root.pskTarget === netEntry.modelData
                    width: parent.width
                    implicitHeight: visible ? 36 : 0
                    radius: Appearance.radius.small
                    color: Qt.rgba(1, 1, 1, 0.05)
                    border.width: 1
                    border.color: Appearance.colors.accentDim

                    TextInput {
                        id: pskInput
                        anchors.fill: parent
                        anchors.leftMargin: Appearance.spacing.md
                        anchors.rightMargin: Appearance.spacing.md
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        font.family: Appearance.font.family
                        font.pixelSize: Appearance.font.base
                        color: Appearance.colors.text
                        focus: visible
                        onAccepted: {
                            netEntry.modelData.connectWithPsk(text);
                            text = "";
                            root.pskTarget = null;
                        }

                        StyledText {
                            visible: pskInput.text === "" && !pskInput.activeFocus
                            anchors.verticalCenter: parent.verticalCenter
                            text: "password, Enter to connect"
                            color: Appearance.colors.muted
                        }
                    }
                }
            }
        }
    }
}
