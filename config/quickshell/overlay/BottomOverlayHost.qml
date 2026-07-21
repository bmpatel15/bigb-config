import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config

// One bottom-center overlay window that morphs between a collapsed shelf,
// the launcher, and the wallpaper picker. A single rounded surface grows
// upward from the shelf so there is never a seam between shelf and content.
// Retargeted to the focused monitor on open — a single window, so no
// duplicate panels across monitors.
PanelWindow {
    id: host

    // "" (closed) | "launcher" | "wallpaper" | "images"
    property string mode: ""
    readonly property bool open: mode !== ""
    // Sticky: which mode's size/content the surface renders. Not cleared on
    // close, so the surface keeps its geometry while it animates out (the
    // reveal is a transform, not a resize).
    property string renderMode: "launcher"
    // Keeps the window mapped through the closing animation.
    property bool rendering: false

    readonly property Item activeContent: mode === "wallpaper" ? wallpaperContent
        : mode === "images" ? imageContent
        : mode === "launcher" ? launcherContent : null

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
        renderMode = m;
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
    // Distinct layer namespace so the Hyprland blur layer_rule
    // (config/hypr/hyprland.lua) scopes to this overlay only, not the bar
    // or the other quickshell panels.
    WlrLayershell.namespace: "shell-overlay"
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
        // Translucent enough for the Hyprland background blur to read as
        // frosted glass while keeping text legible over bright wallpapers.
        color: Qt.rgba(6 / 255, 11 / 255, 30 / 255, 0.7)
        border.width: 1
        border.color: Appearance.colors.border

        // Size follows the sticky render mode; animates only on a mode
        // switch (and launcher filter resize) — NOT during open/close.
        width: host.renderMode === "wallpaper"
            ? Appearance.overlay.wallpaperWidth
            : host.renderMode === "images"
            ? Appearance.overlay.imagesWidth
            : Appearance.overlay.launcherWidth
        height: host.renderMode === "wallpaper"
            ? wallpaperContent.desiredHeight
            : host.renderMode === "images"
            ? imageContent.desiredHeight
            : launcherContent.desiredHeight

        Behavior on width {
            NumberAnimation {
                duration: Appearance.overlay.switchDur
                easing.type: Easing.Bezier
                easing.bezierCurve: Appearance.overlay.openCurve
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: Appearance.overlay.switchDur
                easing.type: Easing.Bezier
                easing.bezierCurve: Appearance.overlay.openCurve
            }
        }

        // Open/close reveal — GPU transforms only (no relayout, no mask
        // churn). A non-uniform Scale from the bottom-center shelf point
        // makes the panel UNFOLD upward: short + slightly narrow → full.
        // The content is bottom-anchored, so the search bar stays put while
        // the results stretch open above it.
        opacity: host.open ? 1 : 0

        transform: [
            Scale {
                origin.x: surface.width / 2
                origin.y: surface.height
                xScale: (host.open || Appearance.reducedMotion) ? 1 : Appearance.overlay.revealScaleX
                yScale: (host.open || Appearance.reducedMotion) ? 1 : Appearance.overlay.revealScaleY

                Behavior on xScale {
                    NumberAnimation {
                        duration: host.open ? Appearance.overlay.openDur : Appearance.overlay.closeDur
                        easing.type: Easing.Bezier
                        easing.bezierCurve: host.open ? Appearance.overlay.openCurve : Appearance.overlay.closeCurve
                    }
                }
                Behavior on yScale {
                    NumberAnimation {
                        duration: host.open ? Appearance.overlay.openDur : Appearance.overlay.closeDur
                        easing.type: Easing.Bezier
                        easing.bezierCurve: host.open ? Appearance.overlay.openCurve : Appearance.overlay.closeCurve
                    }
                }
            },
            Translate {
                y: (host.open || Appearance.reducedMotion) ? 0 : Appearance.overlay.revealLift
                Behavior on y {
                    NumberAnimation {
                        duration: host.open ? Appearance.overlay.openDur : Appearance.overlay.closeDur
                        easing.type: Easing.Bezier
                        easing.bezierCurve: host.open ? Appearance.overlay.openCurve : Appearance.overlay.closeCurve
                    }
                }
            }
        ]

        Behavior on opacity {
            NumberAnimation {
                duration: host.open ? Appearance.overlay.openDur : Appearance.overlay.closeDur
                easing.type: Easing.Bezier
                easing.bezierCurve: host.open ? Appearance.overlay.openCurve : Appearance.overlay.closeCurve
                // Unmap only once the collapse animation has finished.
                onRunningChanged: if (!running && !host.open) host.rendering = false
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

        ImageContent {
            id: imageContent
            anchors.fill: parent
            overlay: host
            active: host.mode === "images"
        }
    }
}
