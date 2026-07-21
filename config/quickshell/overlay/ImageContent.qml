import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.config
import qs.components

// Image picker filmstrip for the bottom overlay host (SUPER+I -> `qs ipc call
// imagepicker toggle`). Same shape as WallpaperContent, but spans several
// folders instead of one: Pictures, Downloads, Desktop, Documents, newest
// first, via bin/image-list. Selecting an image opens it in swayimg.
//
// Two deliberate differences from the wallpaper strip:
//   - No thumbnail cache. ListView only builds visible delegates, so loading
//     the originals with a sourceSize cap is cheap enough and leaves nothing
//     to invalidate when files change. (Qt decodes AVIF/HEIF/JXL here only
//     because qt6-imageformats + kimageformats are installed — the same
//     packages that fixed Dolphin's thumbnails.)
//   - Search matches the folder name too, so typing "downloads" narrows to
//     that folder without needing a separate folder-picking step.
//
// `overlay` is the host; `active` gates focus/input and triggers a refresh
// when it becomes the current mode.
Item {
    id: root

    property var overlay
    property bool active: false

    property var images: []
    property var filtered: []
    property int selected: 0

    readonly property int desiredWidth: Appearance.overlay.imagesWidth
    readonly property int desiredHeight: Appearance.overlay.imagesStripHeight
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
        listProc.running = true;
    }

    function baseName(path) {
        return path.split("/").pop().replace(/\.[^.]+$/, "");
    }

    // Folder shown under each tile: the containing directory, with $HOME
    // collapsed to "~" so "~/Pictures/wallpaper" stays readable at 11px.
    function folderOf(path) {
        const dir = path.substring(0, path.lastIndexOf("/"));
        return Paths.home !== "" && dir.startsWith(Paths.home)
            ? "~" + dir.substring(Paths.home.length)
            : dir;
    }

    function recompute() {
        const q = queryField.text.trim().toLowerCase();
        filtered = q === ""
            ? images
            : images.filter(p => baseName(p).toLowerCase().includes(q)
                || folderOf(p).toLowerCase().includes(q));
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
        Quickshell.execDetached(Paths.imageOpenCmd(path));
        root.overlay.close();
    }

    Process {
        id: listProc
        command: Paths.imageListCmd
        stdout: StdioCollector {
            onStreamFinished: {
                // Already newest-first from the script — do NOT sort here.
                root.images = this.text.trim().split("\n").filter(l => l !== "");
                root.recompute();
            }
        }
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
                implicitHeight: Appearance.overlay.imagesStripHeight
                orientation: ListView.Horizontal
                spacing: Appearance.spacing.sm
                clip: true
                model: root.filtered

                delegate: Item {
                    id: cell

                    required property var modelData
                    required property int index

                    readonly property bool isSelected: cell.index === root.selected

                    width: Appearance.overlay.imagesTileWidth
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
                            border.width: cell.isSelected ? 2 : 1
                            border.color: cell.isSelected ? Appearance.colors.peach
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
                                    id: thumb
                                    anchors.fill: parent
                                    source: "file://" + cell.modelData
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    // Cap decode size — some of these are 4K
                                    // wallpapers or raw camera files.
                                    sourceSize.width: 256
                                    sourceSize.height: 256
                                }

                                // A format Qt can't decode would otherwise be a
                                // blank tile with no hint as to why.
                                StyledText {
                                    anchors.centerIn: parent
                                    visible: thumb.status === Image.Error
                                    text: "󰋫"
                                    font.pixelSize: Appearance.font.title
                                    color: Appearance.colors.muted
                                }
                            }
                        }

                        StyledText {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: root.baseName(cell.modelData)
                            font.pixelSize: Appearance.font.small
                            color: cell.isSelected ? Appearance.colors.peach
                                : Appearance.colors.muted
                            elide: Text.ElideMiddle
                        }

                        StyledText {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: root.folderOf(cell.modelData)
                            font.pixelSize: Appearance.font.small
                            color: cell.isSelected ? Appearance.colors.accent
                                : Appearance.colors.surfaceBlue
                            elide: Text.ElideLeft
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
                    text: "󰋩"
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
                        text: "search images — or a folder name"
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
