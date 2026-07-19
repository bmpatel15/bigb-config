pragma Singleton
import QtQuick
import Quickshell

// Design tokens for the whole shell. Every color/size/font/duration a component
// uses comes from here — palette source of truth is the Ethereal theme
// (~/bigb-config/config/ghostty/themes/ethereal).
Singleton {
    readonly property QtObject colors: QtObject {
        readonly property color bg: "#060B1E"
        readonly property color bgBar: Qt.rgba(6 / 255, 11 / 255, 30 / 255, 0.85)
        readonly property color border: Qt.rgba(1, 1, 1, 0.06)
        readonly property color hover: Qt.rgba(1, 1, 1, 0.07)
        readonly property color surface: "#0d1430"
        readonly property color surfaceBlue: "#3C486D"
        readonly property color text: "#dfeaf0"
        readonly property color peach: "#ffcead"
        readonly property color peachDim: Qt.rgba(255 / 255, 206 / 255, 173 / 255, 0.18)
        readonly property color orange: "#F99957"
        readonly property color accent: "#7d82d9"
        readonly property color accentLight: "#c2c4f0"
        readonly property color accentDim: Qt.rgba(125 / 255, 130 / 255, 217 / 255, 0.18)
        readonly property color mauve: "#c89dc1"
        readonly property color muted: "#6d7db6"
        readonly property color red: "#ED5B5A"
        readonly property color redAlt: "#ff6b81"
        readonly property color green: "#92a593"
        readonly property color yellow: "#E9BB4F"
        readonly property color cyan: "#a3bfd1"
    }

    readonly property QtObject font: QtObject {
        readonly property string family: "JetBrainsMono Nerd Font"
        readonly property int small: 11
        readonly property int base: 13
        readonly property int large: 15
        readonly property int title: 18
    }

    readonly property QtObject spacing: QtObject {
        readonly property int xs: 4
        readonly property int sm: 8
        readonly property int md: 12
        readonly property int lg: 16
        readonly property int xl: 20
    }

    readonly property QtObject radius: QtObject {
        readonly property int island: 17
        readonly property int module: 13
        readonly property int popup: 12
        readonly property int small: 8
    }

    readonly property QtObject anim: QtObject {
        readonly property int fast: 150
        readonly property int normal: 250
        readonly property int slow: 400
        readonly property int easing: Easing.OutExpo
    }

    readonly property QtObject bar: QtObject {
        readonly property int height: 34
        readonly property int marginTop: 6
        readonly property int marginSide: 12
    }

    // Honored by the bottom overlay host: shortens durations and drops
    // translation/scale so only opacity animates.
    readonly property bool reducedMotion: false

    // Morphing bottom-shelf overlay (launcher + wallpaper picker).
    readonly property QtObject overlay: QtObject {
        readonly property int marginBottom: 16

        // Closed "shelf seed" the surface grows out of / collapses back to.
        readonly property int shelfWidth: 220
        readonly property int shelfHeight: 10

        // Launcher mode geometry.
        readonly property int launcherWidth: 600 // fixed max — restrained on ultrawide
        readonly property int launcherRowHeight: 52
        readonly property int launcherMaxRows: 7

        // Wallpaper mode geometry.
        readonly property int wallpaperWidth: 1180
        readonly property int wallpaperStripHeight: 158
        readonly property int wallpaperTileWidth: 224

        // The host window is sized to the largest footprint; the surface
        // morphs inside it.
        readonly property int hostWidth: wallpaperWidth
        readonly property int hostHeight: 560

        // Durations (ms). Open is phased by giving each property its own
        // duration rather than sequencing; close is quicker.
        readonly property int openOpacityDur: 120
        readonly property int openWidthDur: 170
        readonly property int openHeightDur: 240
        readonly property int closeDur: 180
        readonly property int switchDur: 200
        readonly property int filterResizeDur: 140
        readonly property int contentRevealDelay: 60
        readonly property int contentRevealDur: 180

        readonly property int openEasing: Easing.OutCubic
        readonly property int closeEasing: Easing.InCubic

        // Content settle: how far rows/thumbs rise into place on reveal.
        readonly property int liftDistance: 12
    }
}
