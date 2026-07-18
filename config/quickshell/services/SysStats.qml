pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// CPU + memory usage. /proc has no event source, so this is the shell's only
// poller (3 s). FileView.reload() re-reads without spawning processes.
Singleton {
    id: root

    property int cpuPerc: 0
    property int memPerc: 0
    property real memUsedGb: 0
    property bool active: true

    property real lastIdle: 0
    property real lastTotal: 0

    function parseCpu(text) {
        const f = text.split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
        if (f.length < 5)
            return;
        const idle = f[3] + f[4];
        const total = f.reduce((a, b) => a + b, 0);
        const dIdle = idle - lastIdle;
        const dTotal = total - lastTotal;
        if (lastTotal > 0 && dTotal > 0)
            cpuPerc = Math.round(100 * (1 - dIdle / dTotal));
        lastIdle = idle;
        lastTotal = total;
    }

    function parseMem(text) {
        const grab = name => {
            const m = text.match(new RegExp("^" + name + ":\\s+(\\d+)", "m"));
            return m ? parseInt(m[1]) : 0;
        };
        const total = grab("MemTotal");
        const avail = grab("MemAvailable");
        if (total > 0) {
            memPerc = Math.round(100 * (total - avail) / total);
            memUsedGb = Math.round((total - avail) / 1048576 * 10) / 10;
        }
    }

    FileView {
        id: statFile
        path: "/proc/stat"
        preload: false
        onLoaded: root.parseCpu(statFile.text())
    }

    FileView {
        id: memFile
        path: "/proc/meminfo"
        preload: false
        onLoaded: root.parseMem(memFile.text())
    }

    Timer {
        interval: 3000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: {
            statFile.reload();
            memFile.reload();
        }
    }
}
