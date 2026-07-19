import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.components

// Launcher body for the bottom overlay host (logic carried over verbatim
// from the old launcher/Launcher.qml). Search field pinned to the bottom,
// results reveal upward. `overlay` is the host; `active` gates focus/input.
Item {
    id: root

    property var overlay
    property bool active: false

    property var results: []
    property int selected: 0

    readonly property int rowCount: Math.min(Math.max(results.length, 1), Appearance.overlay.launcherMaxRows)
    readonly property int desiredWidth: Appearance.overlay.launcherWidth
    // Bottom-anchored content: surface height matches this so the top
    // (results) reveals as the surface grows; err slightly large so results
    // are never clipped.
    readonly property int desiredHeight: rowCount * Appearance.overlay.launcherRowHeight
        + 1                              // divider
        + 36                             // search row
        + 2 * Appearance.spacing.md      // two column gaps
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

    onActiveChanged: if (active) takeFocus()

    function takeFocus() {
        queryField.text = "";
        recompute();
        queryField.forceActiveFocus();
    }

    // Subsequence score: gaps penalized, consecutive runs rewarded.
    function fuzzy(text, q) {
        let ti = 0;
        let score = 0;
        let streak = 0;
        for (const ch of q) {
            const idx = text.indexOf(ch, ti);
            if (idx === -1)
                return -1;
            streak = idx === ti ? streak + 1 : 1;
            score += 10 + streak * 5 - Math.min(idx - ti, 10);
            ti = idx + 1;
        }
        return score;
    }

    function recompute() {
        const q = queryField.text.trim().toLowerCase();
        const apps = DesktopEntries.applications.values;
        if (q === "") {
            results = [...apps].sort((a, b) => a.name.localeCompare(b.name));
            selected = 0;
            return;
        }
        const scored = [];
        for (const e of apps) {
            const name = e.name.toLowerCase();
            let s = -1;
            if (name.startsWith(q))
                s = 10000 - name.length;
            else if (name.includes(" " + q))
                s = 8000 - name.length;
            else {
                const f = fuzzy(name, q);
                if (f >= 0)
                    s = 1000 + f;
                else if (e.keywords.some(k => k.toLowerCase().includes(q)))
                    s = 500;
                else if (e.genericName.toLowerCase().includes(q))
                    s = 400;
                else if (e.comment.toLowerCase().includes(q))
                    s = 300;
            }
            if (s >= 0)
                scored.push([s, e]);
        }
        scored.sort((a, b) => b[0] - a[0] || a[1].name.localeCompare(b[1].name));
        results = scored.map(x => x[1]);
        selected = 0;
    }

    function launch(entry) {
        if (!entry)
            return;
        // execute() ignores runInTerminal in 0.3.0 — wrap terminal apps.
        if (entry.runInTerminal)
            Quickshell.execDetached({
                command: ["ghostty", "-e"].concat(entry.command),
                workingDirectory: entry.workingDirectory
            });
        else
            entry.execute();
        root.overlay.close();
    }

    function moveSelection(delta) {
        if (results.length === 0)
            return;
        selected = Math.max(0, Math.min(results.length - 1, selected + delta));
    }

    // Content settle: rise into place on reveal (disabled under reducedMotion).
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
                id: list

                width: parent.width
                implicitHeight: Math.min(contentHeight, Appearance.overlay.launcherMaxRows * Appearance.overlay.launcherRowHeight)
                clip: true
                model: root.results
                currentIndex: root.selected

                add: Transition {
                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: Appearance.overlay.contentRevealDur
                    }
                }
                displaced: Transition {
                    NumberAnimation {
                        property: "y"
                        duration: Appearance.overlay.filterResizeDur
                        easing.type: Appearance.overlay.openEasing
                    }
                }

                delegate: Rectangle {
                    id: rowItem

                    required property var modelData
                    required property int index
                    readonly property bool isSelected: index === root.selected

                    width: ListView.view.width
                    implicitHeight: Appearance.overlay.launcherRowHeight
                    radius: Appearance.radius.module
                    color: isSelected ? Appearance.colors.accentDim
                        : rowMouse.containsMouse ? Appearance.colors.hover
                        : "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration: Appearance.anim.fast
                        }
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: rowItem.isSelected && !Appearance.reducedMotion
                            ? Appearance.spacing.md + 4
                            : Appearance.spacing.md
                        spacing: Appearance.spacing.md

                        Behavior on anchors.leftMargin {
                            NumberAnimation {
                                duration: Appearance.anim.fast
                                easing.type: Appearance.anim.easing
                            }
                        }

                        IconImage {
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: 28
                            asynchronous: true
                            source: rowItem.modelData.icon !== ""
                                ? Quickshell.iconPath(rowItem.modelData.icon, true)
                                : ""
                            visible: source !== ""
                            scale: rowItem.isSelected && !Appearance.reducedMotion ? 1.06 : 1.0
                            Behavior on scale {
                                NumberAnimation {
                                    duration: Appearance.anim.fast
                                    easing.type: Appearance.anim.easing
                                }
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 0

                            StyledText {
                                text: rowItem.modelData.name
                                color: rowItem.isSelected
                                    ? Appearance.colors.accentLight
                                    : Appearance.colors.text
                            }

                            StyledText {
                                visible: text !== ""
                                width: rowItem.width - 28 - 3 * Appearance.spacing.md
                                text: rowItem.modelData.comment !== ""
                                    ? rowItem.modelData.comment
                                    : rowItem.modelData.genericName
                                font.pixelSize: Appearance.font.small
                                color: Appearance.colors.muted
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onContainsMouseChanged: {
                            if (containsMouse)
                                root.selected = rowItem.index;
                        }
                        onClicked: root.launch(rowItem.modelData)
                    }
                }
            }

            StyledText {
                visible: root.results.length === 0
                anchors.horizontalCenter: parent.horizontalCenter
                text: "no matches"
                color: Appearance.colors.muted
            }

            Rectangle {
                width: parent.width
                implicitHeight: 1
                color: Appearance.colors.border
            }

            Row {
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

                    width: parent.width - searchIcon.width - Appearance.spacing.sm
                    height: 32
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: Appearance.font.family
                    font.pixelSize: Appearance.font.large
                    color: Appearance.colors.text
                    clip: true

                    onTextChanged: root.recompute()
                    onAccepted: root.launch(root.results[root.selected])

                    Keys.onEscapePressed: root.overlay.close()
                    Keys.onDownPressed: root.moveSelection(1)
                    Keys.onUpPressed: root.moveSelection(-1)
                    Keys.onPressed: event => {
                        if (event.modifiers & Qt.ControlModifier) {
                            if (event.key === Qt.Key_J) {
                                root.moveSelection(1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_K) {
                                root.moveSelection(-1);
                                event.accepted = true;
                            }
                        }
                    }

                    StyledText {
                        visible: queryField.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: "search applications"
                        font.pixelSize: Appearance.font.large
                        color: Appearance.colors.muted
                    }
                }
            }
        }
    }
}
