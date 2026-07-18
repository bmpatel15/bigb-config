import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.config
import qs.components

// App launcher (SUPER+SPACE). Video-style layout: sits center-low, result
// list above a bottom search field; the panel grows upward from a stable
// bottom edge as results change. Fully keyboard driven: type to filter,
// Up/Down or Ctrl+J/K, Enter to launch, Esc to close. (v2 layout)
PanelWindow {
    id: root

    visible: false
    anchors.bottom: true
    margins.bottom: 200
    implicitWidth: 560
    implicitHeight: card.implicitHeight
    color: "transparent"
    // A single-anchored PanelWindow auto-reserves an exclusive zone like a
    // bar would, shoving windows around — this is an overlay, never reserve.
    exclusionMode: ExclusionMode.Ignore
    focusable: true

    property var results: []
    property int selected: 0

    function toggle() {
        if (visible)
            close();
        else
            open();
    }

    function open() {
        queryField.text = "";
        recompute();
        visible = true;
        queryField.forceActiveFocus();
    }

    function close() {
        visible = false;
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
        close();
    }

    function moveSelection(delta) {
        if (results.length === 0)
            return;
        selected = Math.max(0, Math.min(results.length - 1, selected + delta));
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.visible
        onCleared: root.close()
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
                id: list

                width: parent.width
                implicitHeight: Math.min(contentHeight, 8 * 52)
                clip: true
                model: root.results
                currentIndex: root.selected

                delegate: Rectangle {
                    id: row

                    required property var modelData
                    required property int index

                    width: ListView.view.width
                    implicitHeight: 52
                    radius: Appearance.radius.module
                    color: index === root.selected ? Appearance.colors.accentDim
                        : rowMouse.containsMouse ? Appearance.colors.hover
                        : "transparent"

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: Appearance.spacing.md
                        spacing: Appearance.spacing.md

                        IconImage {
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: 28
                            asynchronous: true
                            source: row.modelData.icon !== ""
                                ? Quickshell.iconPath(row.modelData.icon, true)
                                : ""
                            visible: source !== ""
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 0

                            StyledText {
                                text: row.modelData.name
                                color: row.index === root.selected
                                    ? Appearance.colors.accentLight
                                    : Appearance.colors.text
                            }

                            StyledText {
                                visible: text !== ""
                                width: row.width - 28 - 3 * Appearance.spacing.md
                                text: row.modelData.comment !== ""
                                    ? row.modelData.comment
                                    : row.modelData.genericName
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
                                root.selected = row.index;
                        }
                        onClicked: root.launch(row.modelData)
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

                    Keys.onEscapePressed: root.close()
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
