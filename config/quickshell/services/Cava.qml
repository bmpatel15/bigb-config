pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Live audio spectrum via cava's raw stdout (assets/cava.conf). Only runs
// while `active` is true (the dashboard sets this on its Overview tab), so
// there is no idle cost. Degrades to flat bars if cava isn't installed.
Singleton {
    id: root

    readonly property int bars: 14
    property var values: new Array(14).fill(0) // 0..1 per bar
    property bool active: false
    property bool available: true

    function parseLine(line) {
        if (line === "")
            return;
        const parts = line.split(";");
        const out = [];
        for (let i = 0; i < root.bars; i++) {
            const v = parseInt(parts[i]);
            out.push(isNaN(v) ? 0 : Math.min(1, v / 100));
        }
        root.values = out;
    }

    Process {
        id: proc
        running: root.active && root.available
        command: ["cava", "-p", Quickshell.shellPath("assets/cava.conf")]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => root.parseLine(line)
        }
        onExited: (code, status) => {
            // Non-zero exit right after start usually means cava is missing.
            if (code !== 0 && root.active) {
                root.available = false;
                root.values = new Array(root.bars).fill(0);
            }
        }
    }
}
