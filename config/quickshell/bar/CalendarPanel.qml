import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.components

// Month calendar that drops down from the centered clock. Toggled by
// clicking the clock; Esc or click-outside dismisses. Bound to its bar's
// screen so it lands under that monitor's clock. Grid = shared CalendarView.
PanelWindow {
    id: root

    property var barScreen
    // The bar window is included in the focus grab so clicking the clock to
    // close doesn't also count as an outside-click.
    property var anchorWindow
    property bool shown: false

    function toggle() {
        if (shown) {
            shown = false;
            return;
        }
        calView.resetToToday();
        shown = true;
    }

    screen: barScreen
    visible: shown
    anchors.top: true
    margins.top: Appearance.bar.marginTop + Appearance.bar.height + 6
    implicitWidth: 300
    implicitHeight: card.implicitHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: true

    HyprlandFocusGrab {
        windows: root.anchorWindow ? [root, root.anchorWindow] : [root]
        active: root.shown
        onCleared: root.shown = false
    }

    Rectangle {
        id: card

        anchors.fill: parent
        radius: Appearance.radius.island
        color: Qt.rgba(6 / 255, 11 / 255, 30 / 255, 0.94)
        border.width: 1
        border.color: Appearance.colors.border
        implicitHeight: calView.implicitHeight + 2 * Appearance.spacing.lg

        focus: true
        Keys.onEscapePressed: root.shown = false

        CalendarView {
            id: calView
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Appearance.spacing.lg
            cellHeight: 32
        }
    }
}
