import QtQuick
import qs.config
import qs.components
import qs.services

// Three vertical meters — CPU, memory, CPU temperature — each filling from
// the bottom as its value rises.
Item {
    id: root

    // Static model (kind drives the reactive bindings inside the delegate so
    // the Repeater never rebuilds).
    readonly property var meters: [
        { label: "CPU", kind: "cpu", color: Appearance.colors.accent },
        { label: "MEM", kind: "mem", color: Appearance.colors.mauve },
        { label: "TMP", kind: "tmp", color: Appearance.colors.peach }
    ]

    Row {
        anchors.fill: parent
        spacing: (root.width - root.meters.length * 30) / (root.meters.length - 1)

        Repeater {
            model: root.meters

            delegate: Item {
                id: meter

                required property var modelData
                readonly property real value: {
                    if (modelData.kind === "cpu")
                        return Math.min(1, SysStats.cpuPerc / 100);
                    if (modelData.kind === "mem")
                        return Math.min(1, SysStats.memPerc / 100);
                    return Math.min(1, Math.max(0, (SysStats.cpuTemp - 20) / 80));
                }
                readonly property string valueText: {
                    if (modelData.kind === "tmp")
                        return SysStats.cpuTemp + "°";
                    return (modelData.kind === "cpu" ? SysStats.cpuPerc : SysStats.memPerc) + "%";
                }

                width: 30
                height: root.height

                StyledText {
                    id: valText
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: meter.valueText
                    font.pixelSize: Appearance.font.small
                    color: Appearance.colors.text
                }

                StyledText {
                    id: labelText
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: meter.modelData.label
                    font.pixelSize: Appearance.font.small
                    color: Appearance.colors.muted
                }

                Rectangle {
                    id: track
                    anchors.top: valText.bottom
                    anchors.bottom: labelText.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: 6
                    anchors.bottomMargin: 6
                    width: 16
                    radius: 8
                    color: Qt.rgba(1, 1, 1, 0.08)

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: parent.height * meter.value
                        radius: 8

                        gradient: Gradient {
                            GradientStop {
                                position: 0.0
                                color: meter.modelData.color
                            }
                            GradientStop {
                                position: 1.0
                                color: Appearance.colors.accent
                            }
                        }

                        Behavior on height {
                            NumberAnimation {
                                duration: 400
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }
        }
    }
}
