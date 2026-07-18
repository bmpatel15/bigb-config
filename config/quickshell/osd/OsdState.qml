pragma Singleton
import QtQuick
import Quickshell

// Which OSD is showing and for how long. Driven by the IPC handlers in
// shell.qml (hardware keys); bar interactions deliberately do not OSD.
Singleton {
    id: root

    property string kind: "volume" // volume | mic | brightness
    property bool shown: false

    function show(k) {
        kind = k;
        shown = true;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.shown = false
    }
}
