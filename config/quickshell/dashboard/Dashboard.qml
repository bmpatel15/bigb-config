import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.components
import qs.services

// Command-center dashboard (SUPER+SHIFT+D). Top-centre tabbed panel:
// Overview / Media / Weather / Settings. Toggled via IPC; Esc or
// click-outside dismisses. Retargets to the focused monitor on open.
PanelWindow {
    id: root

    property int tab: 0
    property bool shown: false

    readonly property var tabs: [
        { glyph: "󰋜", label: "Overview" },
        { glyph: "󰎈", label: "Media" },
        { glyph: "󰖙", label: "Weather" },
        { glyph: "󰒓", label: "Settings" }
    ]

    function focusedScreen() {
        const n = Hyprland.focusedMonitor?.name;
        return Quickshell.screens.find(s => s.name === n) ?? Quickshell.screens[0] ?? null;
    }

    function toggle() {
        if (shown) {
            shown = false;
            return;
        }
        const s = focusedScreen();
        if (s)
            screen = s;
        shown = true;
    }

    function close() {
        shown = false;
    }

    visible: shown
    anchors.top: true
    margins.top: Appearance.bar.marginTop + Appearance.bar.height + 6
    implicitWidth: 760
    implicitHeight: 470
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: shown

    // Run cava only while the dashboard's Overview tab is on screen.
    Binding {
        target: Cava
        property: "active"
        value: root.shown && root.tab === 0
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.shown
        onCleared: root.shown = false
    }

    Rectangle {
        id: card

        anchors.fill: parent
        radius: Appearance.radius.island
        color: Qt.rgba(6 / 255, 11 / 255, 30 / 255, 0.98)
        border.width: 1
        border.color: Appearance.colors.border

        focus: true
        Keys.onEscapePressed: root.shown = false

        // Tab bar
        Row {
            id: tabBar

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 52

            Repeater {
                model: root.tabs

                delegate: Item {
                    id: tabItem

                    required property int index
                    required property var modelData
                    readonly property bool current: root.tab === tabItem.index

                    width: tabBar.width / root.tabs.length
                    height: tabBar.height

                    Row {
                        anchors.centerIn: parent
                        spacing: Appearance.spacing.sm

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: tabItem.modelData.glyph
                            font.pixelSize: Appearance.font.large
                            color: tabItem.current ? Appearance.colors.peach : Appearance.colors.muted
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: tabItem.modelData.label
                            font.weight: tabItem.current ? 600 : 400
                            color: tabItem.current ? Appearance.colors.peach : Appearance.colors.muted
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 40
                        height: 2
                        radius: 1
                        visible: tabItem.current
                        color: Appearance.colors.peach
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.tab = tabItem.index
                    }
                }
            }
        }

        Rectangle {
            id: divider
            anchors.top: tabBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Appearance.colors.border
        }

        Item {
            id: content

            anchors.top: divider.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Appearance.spacing.lg

            OverviewTab {
                anchors.fill: parent
                visible: root.tab === 0
            }
            MediaTab {
                anchors.fill: parent
                visible: root.tab === 1
            }
            WeatherTab {
                anchors.fill: parent
                visible: root.tab === 2
            }
            SettingsTab {
                anchors.fill: parent
                visible: root.tab === 3
                dashboard: root
            }
        }
    }
}
