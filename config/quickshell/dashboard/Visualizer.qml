import QtQuick
import qs.config
import qs.services

// Audio spectrum bars driven by the Cava service. Shows a flat baseline when
// cava isn't running / installed.
Item {
    id: root

    readonly property int bars: Cava.bars
    readonly property real gap: 4

    Row {
        anchors.fill: parent
        spacing: root.gap

        Repeater {
            model: root.bars

            delegate: Item {
                required property int index
                width: (root.width - (root.bars - 1) * root.gap) / root.bars
                height: root.height

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    radius: width / 2
                    height: Math.max(width, (Cava.values[parent.index] ?? 0) * parent.height)

                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: Appearance.colors.mauve
                        }
                        GradientStop {
                            position: 1.0
                            color: Appearance.colors.accent
                        }
                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: 80
                            easing.type: Easing.OutQuad
                        }
                    }
                }
            }
        }
    }
}
