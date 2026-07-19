import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.components

// Month calendar that drops down from the centered clock. Toggled by
// clicking the clock; Esc or click-outside dismisses. Bound to its bar's
// screen so it lands under that monitor's clock.
PanelWindow {
    id: root

    property var barScreen
    // The bar window is included in the focus grab so clicking the clock to
    // close doesn't also count as an outside-click.
    property var anchorWindow
    property bool shown: false

    property int viewYear: 2000
    property int viewMonth: 0 // 0-11

    Component.onCompleted: {
        const d = new Date();
        viewYear = d.getFullYear();
        viewMonth = d.getMonth();
    }

    readonly property int firstDow: new Date(viewYear, viewMonth, 1).getDay() // 0=Sun
    readonly property int daysInMonth: new Date(viewYear, viewMonth + 1, 0).getDate()

    function toggle() {
        if (shown) {
            shown = false;
            return;
        }
        const d = clock.date;
        viewYear = d.getFullYear();
        viewMonth = d.getMonth();
        shown = true;
    }

    function shift(delta) {
        let m = viewMonth + delta;
        let y = viewYear;
        while (m < 0) {
            m += 12;
            y -= 1;
        }
        while (m > 11) {
            m -= 12;
            y += 1;
        }
        viewMonth = m;
        viewYear = y;
    }

    function isToday(day) {
        const t = clock.date;
        return viewYear === t.getFullYear() && viewMonth === t.getMonth() && day === t.getDate();
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

    SystemClock {
        id: clock
        precision: SystemClock.Hours
    }

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
        implicitHeight: col.implicitHeight + 2 * Appearance.spacing.lg

        focus: true
        Keys.onEscapePressed: root.shown = false

        Column {
            id: col

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Appearance.spacing.lg
            spacing: Appearance.spacing.sm

            readonly property real cellWidth: width / 7

            // Header: ‹  Month Year  ›
            Item {
                width: parent.width
                implicitHeight: 28

                Rectangle {
                    id: prevBtn
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    height: 24
                    radius: Appearance.radius.small
                    color: prevMouse.containsMouse ? Appearance.colors.hover : "transparent"

                    StyledText {
                        anchors.centerIn: parent
                        text: "‹"
                        color: Appearance.colors.muted
                    }
                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.shift(-1)
                    }
                }

                StyledText {
                    anchors.centerIn: parent
                    text: Qt.formatDateTime(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy")
                    color: Appearance.colors.peach
                    font.weight: 600
                }

                Rectangle {
                    id: nextBtn
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    height: 24
                    radius: Appearance.radius.small
                    color: nextMouse.containsMouse ? Appearance.colors.hover : "transparent"

                    StyledText {
                        anchors.centerIn: parent
                        text: "›"
                        color: Appearance.colors.muted
                    }
                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.shift(1)
                    }
                }
            }

            // Weekday labels
            Row {
                width: parent.width

                Repeater {
                    model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

                    delegate: StyledText {
                        required property var modelData
                        width: col.cellWidth
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        font.pixelSize: Appearance.font.small
                        color: Appearance.colors.muted
                    }
                }
            }

            // Day grid (6 weeks)
            Grid {
                width: parent.width
                columns: 7

                Repeater {
                    model: 42

                    delegate: Item {
                        id: cell

                        required property int index
                        readonly property int dayNum: cell.index - root.firstDow + 1
                        readonly property bool inMonth: cell.dayNum >= 1 && cell.dayNum <= root.daysInMonth
                        readonly property bool today: cell.inMonth && root.isToday(cell.dayNum)

                        width: col.cellWidth
                        height: 32

                        Rectangle {
                            anchors.centerIn: parent
                            width: 26
                            height: 26
                            radius: 13
                            visible: cell.today
                            color: Appearance.colors.peach
                        }

                        StyledText {
                            anchors.centerIn: parent
                            visible: cell.inMonth
                            text: cell.dayNum
                            horizontalAlignment: Text.AlignHCenter
                            color: cell.today ? Appearance.colors.bg : Appearance.colors.text
                            font.weight: cell.today ? 600 : 400
                        }
                    }
                }
            }
        }
    }
}
