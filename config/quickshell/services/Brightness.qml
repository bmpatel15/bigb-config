pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// brightnessctl wrapper: one read at startup, then read-after-write (no
// polling). The sysfs watch is a best-effort pickup of external changes
// (XF86 keys bypass the shell until Stage B rebinds them to IPC).
Singleton {
    id: root

    property int percent: 0
    property string device: ""
    readonly property bool available: device !== ""
    property string pendingSpec: ""

    // brightnessctl -m: "intel_backlight,backlight,48000,50%,96000"
    function parse(text) {
        const line = text.trim().split("\n")[0];
        if (!line)
            return;
        const parts = line.split(",");
        if (parts.length < 4)
            return;
        device = parts[0];
        const p = parseInt(parts[3]);
        if (!isNaN(p))
            percent = p;
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
        path: root.available ? "/sys/class/backlight/" + root.device + "/actual_brightness" : ""
        watchChanges: true
        preload: false
        printErrors: false
        onFileChanged: getProc.running = true
    }
}
