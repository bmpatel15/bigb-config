pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Host / user / uptime for the dashboard profile card.
Singleton {
    id: root

    readonly property string user: Quickshell.env("USER") ?? ""
    property string host: ""
    property int uptimeSec: 0

    readonly property string uptimeText: {
        const s = uptimeSec;
        const days = Math.floor(s / 86400);
        const hours = Math.floor((s % 86400) / 3600);
        const mins = Math.floor((s % 3600) / 60);
        const parts = [];
        if (days > 0)
            parts.push(days + (days === 1 ? " day" : " days"));
        parts.push(hours + (hours === 1 ? " hour" : " hours"));
        parts.push(mins + (mins === 1 ? " minute" : " minutes"));
        return parts.join(", ");
    }

    FileView {
        id: hostFile
        path: "/proc/sys/kernel/hostname"
        preload: true
        printErrors: false
        onLoaded: root.host = text().trim()
    }

    Process {
        id: uptimeProc
        command: ["cat", "/proc/uptime"]
        stdout: StdioCollector {
            onStreamFinished: root.uptimeSec = parseInt(this.text.split(" ")[0])
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: uptimeProc.running = true
    }
}
