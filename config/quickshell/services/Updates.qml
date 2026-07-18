pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Pending-update count via the existing waybar updates.sh (checkupdates +
// yay -Qua, emits waybar JSON). First run delayed so login isn't burdened.
Singleton {
    id: root

    property int count: 0
    readonly property bool busy: proc.running

    function parse(text) {
        try {
            const m = (JSON.parse(text).text ?? "").match(/\d+/);
            count = m ? parseInt(m[0]) : 0;
        } catch (e) {
            count = 0;
        }
    }

    function refresh() {
        proc.running = true;
    }

    Process {
        id: proc
        command: ["bash", Paths.updatesScript]
        stdout: StdioCollector {
            onStreamFinished: root.parse(this.text)
        }
    }

    Timer {
        interval: 30000
        running: true
        onTriggered: root.refresh()
    }

    Timer {
        interval: 3600000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }
}
