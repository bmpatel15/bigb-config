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
// in one place. Type to filter; arrows navigate the grid (Left/Right edit
// the query only while it has text); Enter applies. No anchors →
// compositor centers the window.
PanelWindow {
    id: root

    visible: false
    implicitWidth: 940
    implicitHeight: 680
    color: "transparent"
    focusable: true

    readonly property int columns: 5

    property var images: []
    property var filtered: []
    property int selected: 0
    property string current: ""

    function toggle() {
        if (visible) {
            visible = false;
            return;
        }
        refresh();
        visible = true;
        queryField.forceActiveFocus();
    }

    function refresh() {
        queryField.text = "";
        currentFile.reload();
        currentFile.waitForJob();
        current = currentFile.text().trim();
        listProc.running = true;
        warmProc.running = true;
    }

    function baseName(path) {
        return path.split("/").pop().replace(/\.[^.]+$/, "");
    }

    function recompute() {
        const q = queryField.text.trim().toLowerCase();
        filtered = q === ""
            ? images
            : images.filter(p => baseName(p).toLowerCase().includes(q));
        selected = 0;
    }

    function moveSelection(delta) {
        if (filtered.length === 0)
            return;
        selected = Math.max(0, Math.min(filtered.length - 1, selected + delta));
        grid.positionViewAtIndex(selected, GridView.Contain);
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
            onStreamFinished: {
                root.images = this.text.trim().split("\n").filter(l => l !== "").sort();
                root.recompute();
            }
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

        Column {
            anchors.fill: parent
            anchors.margins: Appearance.spacing.lg
            spacing: Appearance.spacing.md

            Row {
                id: headerRow
                width: parent.width
                spacing: Appearance.spacing.sm

                StyledText {
                    id: searchIcon
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰍉"
                    font.pixelSize: Appearance.font.large
                    color: Appearance.colors.accent
                }

                TextInput {
                    id: queryField

                    width: parent.width - searchIcon.width - countLabel.width - 2 * Appearance.spacing.sm
                    height: 30
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: Appearance.font.family
                    font.pixelSize: Appearance.font.large
                    color: Appearance.colors.text
                    clip: true

                    onTextChanged: root.recompute()
                    onAccepted: root.apply(root.filtered[root.selected])

                    Keys.onEscapePressed: root.visible = false
                    Keys.onDownPressed: root.moveSelection(root.columns)
                    Keys.onUpPressed: root.moveSelection(-root.columns)
                    Keys.onLeftPressed: event => {
                        if (text === "")
                            root.moveSelection(-1);
                        else
                            event.accepted = false;
                    }
                    Keys.onRightPressed: event => {
                        if (text === "")
                            root.moveSelection(1);
                        else
                            event.accepted = false;
                    }

                    StyledText {
                        visible: queryField.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: "search wallpapers"
                        font.pixelSize: Appearance.font.large
                        color: Appearance.colors.muted
                    }
                }

                StyledText {
                    id: countLabel
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.filtered.length + " / " + root.images.length
                    font.pixelSize: Appearance.font.small
                    color: Appearance.colors.muted
                }
            }

            GridView {
                id: grid

                width: parent.width
                height: parent.height - headerRow.height - Appearance.spacing.md
                clip: true
                cellWidth: Math.floor(width / root.columns)
                cellHeight: Math.floor(cellWidth * 0.62) + 24
                model: root.filtered

                delegate: Item {
                    id: cell

                    required property var modelData
                    required property int index

                    readonly property bool isSelected: cell.index === root.selected
                    readonly property bool isActive: cell.modelData === root.current

                    width: grid.cellWidth
                    height: grid.cellHeight

                    Column {
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 2

                        Rectangle {
                            id: frame

                            width: parent.width
                            height: parent.height - nameLabel.height - 2
                            radius: Appearance.radius.popup
                            color: "transparent"
                            border.width: cell.isSelected || cell.isActive ? 2 : 1
                            border.color: cell.isSelected ? Appearance.colors.peach
                                : cell.isActive ? Appearance.colors.accent
                                : Appearance.colors.border

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

                        StyledText {
                            id: nameLabel
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: root.baseName(cell.modelData)
                            font.pixelSize: Appearance.font.small
                            color: cell.isSelected ? Appearance.colors.peach
                                : cell.isActive ? Appearance.colors.accent
                                : Appearance.colors.muted
                            elide: Text.ElideMiddle
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onContainsMouseChanged: {
                            if (containsMouse)
                                root.selected = cell.index;
                        }
                        onClicked: root.apply(cell.modelData)
                    }
                }
            }
        }
    }
}
