import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.config
import qs.components

// Wallpaper filmstrip for the bottom overlay host (logic carried over
// verbatim from the old wallpapers/WallPicker.qml — same wallpaper-picker.sh
// backend, thumb cache and state file). Search pinned to the bottom, strip
// reveals above. `overlay` is the host; `active` gates focus/input and
// triggers a refresh when it becomes the current mode.
Item {
    id: root

    property var overlay
    property bool active: false

    property var images: []
    property var filtered: []
    property int selected: 0
    property string current: ""

    readonly property int desiredWidth: Appearance.overlay.wallpaperWidth
    readonly property int desiredHeight: Appearance.overlay.wallpaperStripHeight
        + 36                             // search row
        + Appearance.spacing.md          // column gap
        + 2 * Appearance.spacing.lg      // top/bottom padding

    opacity: active ? 1 : 0
    visible: opacity > 0.01
    enabled: active

    Behavior on opacity {
        NumberAnimation {
            duration: Appearance.overlay.contentRevealDur
            easing.type: Appearance.overlay.openEasing
        }
    }

    onActiveChanged: {
        if (active) {
            refresh();
            takeFocus();
        }
    }

    function takeFocus() {
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
        root.overlay.close();
    }

    function thumbFor(path) {
        return "file://" + Paths.wallpaperThumbDir + "/" + path.split("/").pop() + ".png";
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
            if (root.active)
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

    Item {
        anchors.fill: parent

        transform: Translate {
            y: (!root.active && !Appearance.reducedMotion) ? Appearance.overlay.liftDistance : 0
            Behavior on y {
                NumberAnimation {
                    duration: Appearance.overlay.contentRevealDur
                    easing.type: Appearance.overlay.openEasing
                }
            }
        }

        Column {
            id: content

            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Appearance.spacing.lg
            spacing: Appearance.spacing.md

            ListView {
                id: strip

                width: parent.width
                implicitHeight: Appearance.overlay.wallpaperStripHeight
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

                    width: Appearance.overlay.wallpaperTileWidth
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
                            scale: cell.isSelected && !Appearance.reducedMotion ? 1.05 : 1.0
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

                    Keys.onEscapePressed: root.overlay.close()
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
