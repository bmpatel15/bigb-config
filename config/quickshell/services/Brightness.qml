pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// brightnessctl wrapper. Mutations are read-after-write (no polling of the
// tool). External changes (XF86 keys until Stage B routes them through IPC)
// are picked up from sysfs: inotify when it works, plus a 15 s direct file
// re-read (no process spawn) as the reliable fallback.
Singleton {
    id: root

    property int percent: 0
    property int rawMax: 0
    property string device: ""
    readonly property bool available: device !== ""
    property string pendingSpec: ""

    // brightnessctl -m: "intel_backlight,backlight,48000,50%,96000"
    function parse(text) {
        const line = text.trim().split("\n")[0];
        if (!line)
            return;
        const parts = line.split(",");
        if (parts.length < 5)
            return;
        device = parts[0];
        const p = parseInt(parts[3]);
        if (!isNaN(p))
            percent = p;
        const max = parseInt(parts[4]);
        if (!isNaN(max))
            rawMax = max;
    }

    function readSysfs() {
        if (!available || rawMax <= 0)
            return;
        sysfsFile.reload();
        sysfsFile.waitForJob();
        const v = parseInt(sysfsFile.text());
        if (!isNaN(v))
            percent = Math.round(100 * v / rawMax);
    }

    function set(spec) {
        if (setProc.running) {
            pendingSpec = spec;
            return;
        }
        setProc.command = Paths.brightnessSetCmd(spec);
        setProc.running = true;
    }
    function inc() { set("5%+"); }
    function dec() { set("5%-"); }

    Process {
        id: getProc
        command: Paths.brightnessGetCmd
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.parse(this.text)
        }
    }

    Process {
        id: setProc
        stdout: StdioCollector {
            onStreamFinished: root.parse(this.text)
        }
        onExited: {
            if (root.pendingSpec !== "") {
                const spec = root.pendingSpec;
                root.pendingSpec = "";
                root.set(spec);
            }
        }
    }

    FileView {
        id: sysfsFile
        path: root.available ? "/sys/class/backlight/" + root.device + "/actual_brightness" : ""
        watchChanges: true
        preload: false
        printErrors: false
        onFileChanged: root.readSysfs()
    }

    Timer {
        interval: 15000
        repeat: true
        running: root.available
        onTriggered: root.readSysfs()
    }
}
