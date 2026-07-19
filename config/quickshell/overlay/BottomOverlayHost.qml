import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config

// One bottom-center overlay window that morphs between a collapsed shelf,
// the launcher, and the wallpaper picker. A single rounded surface grows
// upward from the shelf so there is never a seam between shelf and content.
// Retargeted to the focused monitor on open — a single window, so no
// duplicate panels across monitors.
PanelWindow {
    id: host

    // "" (closed) | "launcher" | "wallpaper"
    property string mode: ""
    readonly property bool shown: mode !== ""
    // Keeps the window mapped through the closing animation.
    property bool rendering: false

    readonly property Item activeContent: mode === "wallpaper" ? wallpaperContent : launcherContent
    readonly property int openWidth: mode === "wallpaper"
        ? Appearance.overlay.wallpaperWidth
        : Appearance.overlay.launcherWidth

    function focusedScreen() {
        const n = Hyprland.focusedMonitor?.name;
        return Quickshell.screens.find(s => s.name === n) ?? Quickshell.screens[0] ?? null;
    }

    function toggleMode(m) {
        if (mode === m) {
            close();
            return;
        }
        if (!rendering) {
            const s = focusedScreen();
            if (s)
                screen = s;
            rendering = true;
        }
        mode = m;
    }

    function close() {
        mode = "";
    }

    visible: rendering
    anchors.bottom: true
    margins.bottom: Appearance.overlay.marginBottom
    implicitWidth: Appearance.overlay.hostWidth
    implicitHeight: Appearance.overlay.hostHeight
    color: "transparent"
    // Never reserve desktop space.
    exclusionMode: ExclusionMode.Ignore
    // Only request keyboard while mapped.
    focusable: rendering

    // Input only over the visible surface — transparent margins pass clicks
    // through to the desktop (no full-width input blocker).
    mask: Region {
        item: surface
    }

    // Refocus the active content once the window is actually mapped.
    onVisibleChanged: {
        if (visible)
            Qt.callLater(() => {
                if (activeContent)
                    activeContent.takeFocus();
            });
    }

    HyprlandFocusGrab {
        windows: [host]
        active: host.rendering
        onCleared: host.close()
    }

    Rectangle {
        id: surface

        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        clip: true
        radius: Appearance.radius.island
        color: Qt.rgba(6 / 255, 11 / 255, 30 / 255, 0.96)
        border.width: 1
        border.color: Appearance.colors.border

        width: host.shown ? host.openWidth : Appearance.overlay.shelfWidth
        height: host.shown ? host.activeContent.desiredHeight : Appearance.overlay.shelfHeight
        opacity: host.shown ? 1 : 0

        Behavior on width {
            NumberAnimation {
                duration: host.shown ? Appearance.overlay.openWidthDur : Appearance.overlay.closeDur
                easing.type: host.shown ? Appearance.overlay.openEasing : Appearance.overlay.closeEasing
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: host.shown ? Appearance.overlay.openHeightDur : Appearance.overlay.closeDur
                easing.type: host.shown ? Appearance.overlay.openEasing : Appearance.overlay.closeEasing
                // Unmap only once the collapse animation has finished.
                onRunningChanged: if (!running && !host.shown) host.rendering = false
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: host.shown ? Appearance.overlay.openOpacityDur : Appearance.overlay.closeDur
                easing.type: host.shown ? Appearance.overlay.openEasing : Appearance.overlay.closeEasing
            }
        }

        LauncherContent {
            id: launcherContent
            anchors.fill: parent
            overlay: host
            active: host.mode === "launcher"
        }

        WallpaperContent {
            id: wallpaperContent
            anchors.fill: parent
            overlay: host
            active: host.mode === "wallpaper"
        }
    }
}
