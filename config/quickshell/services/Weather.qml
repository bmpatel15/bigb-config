pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Current weather from wttr.in (no API key; location auto-detected from IP).
// Refreshed every 30 min.
Singleton {
    id: root

    property int tempF: 0
    property int feelsF: 0
    property int humidity: 0
    property string desc: ""
    property string area: ""
    property bool ready: false
    readonly property bool busy: proc.running

    SystemClock {
        id: clock
        precision: SystemClock.Hours
    }

    function refresh() {
        proc.running = true;
    }

    function parse(text) {
        try {
            const d = JSON.parse(text);
            const c = d.current_condition[0];
            tempF = parseInt(c.temp_F);
            feelsF = parseInt(c.FeelsLikeF);
            humidity = parseInt(c.humidity);
            desc = c.weatherDesc[0].value;
            const a = d.nearest_area && d.nearest_area[0];
            area = a ? a.areaName[0].value : "";
            ready = true;
        } catch (e) {
            // leave last-known values in place
        }
    }

    // Material-design weather glyphs (nerd font), chosen from the condition
    // text + whether it's day or night.
    readonly property string icon: {
        const h = clock.date.getHours();
        const night = h < 6 || h >= 19;
        const d = desc.toLowerCase();
        if (d.includes("thunder"))
            return "󰖓";
        if (d.includes("snow") || d.includes("blizzard") || d.includes("sleet"))
            return "󰖘";
        if (d.includes("rain") || d.includes("drizzle") || d.includes("shower"))
            return "󰖖";
        if (d.includes("fog") || d.includes("mist"))
            return "󰖑";
        if (d.includes("overcast"))
            return "󰖐";
        if (d.includes("cloud"))
            return night ? "󰼱" : "󰖕";
        if (d.includes("clear") || d.includes("sunny"))
            return night ? "󰖔" : "󰖙";
        return night ? "󰖔" : "󰖙";
    }

    Process {
        id: proc
        command: ["curl", "-s", "--max-time", "12", "wttr.in/?format=j1"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(this.text)
        }
    }

    Timer {
        interval: 1800000 // 30 min
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
