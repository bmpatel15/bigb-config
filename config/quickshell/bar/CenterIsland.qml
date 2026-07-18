import QtQuick
import Quickshell
import qs.config
import qs.components

// Clock pill, pinned to the true screen center. Media lives in its own
// island (MediaIsland) so the clock never shifts when music starts.
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
            color: Appearance.colors.muted
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(clock.date, "h:mm AP")
            color: Appearance.colors.peach
            font.weight: 600
        }
    }
}
