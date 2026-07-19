import QtQuick
import qs.config

// Subtle raised container used across the dashboard tabs.
Rectangle {
    default property alias content: inner.data
    property real padding: Appearance.spacing.md

    radius: Appearance.radius.module
    color: Qt.rgba(1, 1, 1, 0.05)

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: parent.padding
    }
}
