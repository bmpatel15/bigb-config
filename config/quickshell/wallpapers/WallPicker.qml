import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.config
import qs.components

// Bottom-center wallpaper filmstrip over the existing wallpaper-picker.sh
// system: same image dir, same thumb cache, applying goes through the
// script (--set) so daemon/transition/state/hyprlock-bg logic stays in one
// place. Type to filter; Left/Right ride the strip while the query is
// empty (else they edit the text); Enter applies; Esc closes.
PanelWindow {
    id: root

    visible: false
    anchors.bottom: true
    margins.bottom: 110
    implicitWidth: 1184
    implicitHeight: card.implicitHeight
    color: "transparent"
    // One-anchor PanelWindows auto-reserve an exclusive zone — never for
    // overlays.
    exclusionMode: ExclusionMode.Ignore
    focusable: true

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
        strip.positionViewAtBeginning();
    }

    function moveSelection(delta) {
        if (filtered.length === 0)
            return;
        selected = Math.max(0, Math.min(filtered.length - 1, selected + delta));
        strip.positionViewAtIndex(selected, ListView.Center);
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
        implicitHeight: content.implicitHeight + 2 * Appearance.spacing.lg

        Column {
            id: content

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Appearance.spacing.lg
            spacing: Appearance.spacing.md

            ListView {
                id: strip

                width: parent.width
                implicitHeight: 158
                orientation: ListView.Horizontal
                spacing: Appearance.spacing.sm
                clip: true
                model: root.filtered

                delegate: Item {
                    id: cell

                    required property var modelData
                    required property int index

                    readonly property bool isSelected: cell.index === root.selected
                    readonly property bool isActive: cell.modelData === root.current

                    width: 224
                    height: strip.implicitHeight
                    z: isSelected ? 2 : 0

                    Column {
                        anchors.fill: parent
                        spacing: 2

                        Rectangle {
                            id: frame

                            width: parent.width
                            height: 130
                            radius: Appearance.radius.popup
                            color: "transparent"
                            border.width: cell.isSelected || cell.isActive ? 2 : 1
                            border.color: cell.isSelected ? Appearance.colors.peach
                                : cell.isActive ? Appearance.colors.accent
                                : Appearance.colors.border
                            scale: cell.isSelected ? 1.05 : 1.0
                            transformOrigin: Item.Center

                            Behavior on scale {
                                NumberAnimation {
                                    duration: Appearance.anim.fast
                                    easing.type: Appearance.anim.easing
                                }
                            }

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

            Row {
                id: searchRow
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
                    Keys.onDownPressed: root.moveSelection(1)
                    Keys.onUpPressed: root.moveSelection(-1)
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
        }
    }
}
