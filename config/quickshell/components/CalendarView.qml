import QtQuick
import Quickshell
import qs.config

// Self-contained month calendar grid (header nav + weekday row + day grid,
// today highlighted). Used by the clock popup (bar/CalendarPanel) and the
// dashboard Overview tab. Fills its parent's width.
Item {
    id: root

    property int viewYear: 2000
    property int viewMonth: 0 // 0-11
    property int cellHeight: 30
    property color accent: Appearance.colors.peach

    implicitHeight: col.implicitHeight

    Component.onCompleted: resetToToday()

    function resetToToday() {
        const d = new Date();
        viewYear = d.getFullYear();
        viewMonth = d.getMonth();
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

    readonly property int firstDow: new Date(viewYear, viewMonth, 1).getDay() // 0=Sun
    readonly property int daysInMonth: new Date(viewYear, viewMonth + 1, 0).getDate()

    SystemClock {
        id: clock
        precision: SystemClock.Hours
    }

    Column {
        id: col

        width: parent.width
        spacing: Appearance.spacing.sm

        readonly property real cellWidth: width / 7

        // Header: ‹  Month Year  ›
        Item {
            width: parent.width
            implicitHeight: 28

            Rectangle {
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
                color: root.accent
                font.weight: 600
            }

            Rectangle {
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
                model: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

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
                    height: root.cellHeight

                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height) - 4
                        height: width
                        radius: width / 2
                        visible: cell.today
                        color: root.accent
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
