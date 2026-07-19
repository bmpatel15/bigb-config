import QtQuick
import Quickshell
import qs.config
import qs.components

// Clock pill, pinned to the true screen center. Media lives in its own
// island (MediaIsland) so the clock never shifts when music starts.
// Date and time share the peach accent (user preference, 2026-07-18).
// Clicking the clock toggles the calendar drop-down (see CalendarPanel).
Island {
    id: root

    property var calendar

    Item {
        implicitWidth: row.implicitWidth
        implicitHeight: row.implicitHeight

        // Non-visual: kept here so the Item wraps a single visual Row.
        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

        Row {
            id: row
            anchors.verticalCenter: parent.verticalCenter
            spacing: Appearance.spacing.sm

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDateTime(clock.date, "ddd MMM d")
                color: Appearance.colors.peach
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDateTime(clock.date, "h:mm AP")
                color: Appearance.colors.peach
                font.weight: 600
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.calendar?.toggle()
        }
    }
}
