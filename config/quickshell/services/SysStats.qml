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
    property int cpuTemp: 0 // °C (coretemp package)
    property string tempPath: ""
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

    // Synchronous read each tick: onLoaded does not re-fire for reload()s,
    // and /proc reads complete in microseconds anyway.
    FileView {
        id: statFile
        path: "/proc/stat"
        preload: false
        printErrors: false
    }

    FileView {
        id: memFile
        path: "/proc/meminfo"
        preload: false
        printErrors: false
    }

    // Resolve the coretemp package sensor once (hwmon numbers aren't stable
    // across boots, so find it by name rather than hardcoding).
    Process {
        running: true
        command: ["sh", "-c", "for h in /sys/class/hwmon/hwmon*; do [ \"$(cat \"$h/name\" 2>/dev/null)\" = coretemp ] && printf %s \"$h/temp1_input\" && exit; done"]
        stdout: StdioCollector {
            onStreamFinished: root.tempPath = this.text.trim()
        }
    }

    FileView {
        id: tempFile
        path: root.tempPath
        preload: false
        printErrors: false
    }

    Timer {
        interval: 3000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: {
            statFile.reload();
            statFile.waitForJob();
            root.parseCpu(statFile.text());
            memFile.reload();
            memFile.waitForJob();
            root.parseMem(memFile.text());
            if (root.tempPath !== "") {
                tempFile.reload();
                tempFile.waitForJob();
                const t = parseInt(tempFile.text());
                if (!isNaN(t))
                    root.cpuTemp = Math.round(t / 1000);
            }
        }
    }
}
