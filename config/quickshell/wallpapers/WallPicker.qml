import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.config
import qs.components

// Wallpaper grid over the existing wallpaper-picker.sh system: same image
// dir, same thumb cache, and applying goes through the script (--set) so
// daemon management, transition, state file, and hyprlock-bg staging stay
// in one place. No anchors → compositor centers the window.
PanelWindow {
    id: root

    visible: false
    implicitWidth: 940
    implicitHeight: 660
    color: "transparent"
    focusable: true

    property var images: []
    property string current: ""

    function toggle() {
        if (visible) {
            visible = false;
            return;
        }
        refresh();
        visible = true;
    }

    function refresh() {
        currentFile.reload();
        currentFile.waitForJob();
        current = currentFile.text().trim();
        listProc.running = true;
        warmProc.running = true;
    }

    function apply(path) {
        if (!path)
            return;
        setProc.command = ["bash", Paths.wallpaperScript, "--set", path];
        setProc.running = true;
        current = path;
        visible = false;
    }

    function thumbFor(path) {
        return "file://" + Paths.wallpaperThumbDir + "/" + path.split("/").pop() + ".png";
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.visible
        onCleared: root.visible = false
    }

    Process {
        id: listProc
        command: ["find", Paths.wallpaperDir, "-maxdepth", "1", "-type", "f",
            "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png", ")"]
        stdout: StdioCollector {
            onStreamFinished: root.images = this.text.trim().split("\n").filter(l => l !== "").sort()
        }
    }

    Process {
        id: warmProc
        command: ["bash", Paths.wallpaperScript, "--warm"]
        onExited: {
            // Thumbs that were missing when the grid opened exist now.
            if (root.visible)
                listProc.running = true;
        }
    }

    Process {
        id: setProc
    }

    FileView {
        id: currentFile
        path: Paths.wallpaperStateFile
        preload: false
        printErrors: false
    }

    Rectangle {
        id: card

        anchors.fill: parent
        radius: Appearance.radius.island
        color: Qt.rgba(6 / 255, 11 / 255, 30 / 255, 0.96)
        border.width: 1
        border.color: Appearance.colors.border

        focus: true
        Keys.onEscapePressed: root.visible = false

        Column {
            anchors.fill: parent
            anchors.margins: Appearance.spacing.lg
            spacing: Appearance.spacing.md

            Item {
                width: parent.width
                implicitHeight: 24

                StyledText {
                    text: "Wallpaper"
                    font.pixelSize: Appearance.font.large
                    font.weight: 600
                    color: Appearance.colors.peach
                }

                StyledText {
                    anchors.right: parent.right
                    text: root.images.length + " images"
                    font.pixelSize: Appearance.font.small
                    color: Appearance.colors.muted
                }
            }

            GridView {
                id: grid

                width: parent.width
                height: parent.height - 24 - Appearance.spacing.md
                clip: true
                cellWidth: Math.floor(width / 5)
                cellHeight: cellWidth * 0.72
                model: root.images
                focus: true
                currentIndex: 0

                Keys.onReturnPressed: root.apply(root.images[currentIndex])
                Keys.onEnterPressed: root.apply(root.images[currentIndex])

                delegate: Item {
                    id: cell

                    required property var modelData
                    required property int index

                    width: grid.cellWidth
                    height: grid.cellHeight

                    Rectangle {
                        id: frame

                        anchors.fill: parent
                        anchors.margins: 5
                        radius: Appearance.radius.popup
                        color: "transparent"
                        border.width: cell.GridView.isCurrentItem || isActive ? 2 : 1
                        border.color: cell.GridView.isCurrentItem ? Appearance.colors.peach
                            : isActive ? Appearance.colors.accent
                            : Appearance.colors.border

                        readonly property bool isActive: cell.modelData === root.current

                        ClippingRectangle {
                            anchors.fill: parent
                            anchors.margins: 3
                            radius: Appearance.radius.small
                            color: Appearance.colors.surface

                            Image {
                                anchors.fill: parent
                                source: root.thumbFor(cell.modelData)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: 256
                                sourceSize.height: 256
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.apply(cell.modelData)
                    }
                }
            }
        }
    }
}
