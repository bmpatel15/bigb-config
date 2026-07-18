import QtQuick
import Quickshell
import qs.config
import qs.components

// Clock pill, pinned to the true screen center. Media lives in its own
// island (MediaIsland) so the clock never shifts when music starts.
// Date and time share the peach accent (user preference, 2026-07-18).
Island {
    Row {
        spacing: Appearance.spacing.sm

        // Non-visual: lives inside the Row so the island keeps a single
        // layout child.
        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

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
}
