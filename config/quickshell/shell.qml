import QtQuick
import Quickshell
import Quickshell.Io
import qs.bar
import qs.osd
import qs.services
import qs.controlcenter

ShellRoot {
    Variants {
        model: Quickshell.screens

        delegate: Component {
            Bar {}
        }
    }

    Osd {}

    LazyLoader {
        id: ccLoader
        loading: true

        ControlCenter {}
    }

    // External control surface (`qs ipc call <target> <fn>`). The hardware
    // keys in hyprland.lua route through these so state change + OSD are
    // atomic.
    IpcHandler {
        target: "shell"

        function ping(): string {
            return "pong";
        }
    }

    IpcHandler {
        target: "audio"

        function incVolume(): void {
            Audio.incVolume();
            OsdState.show("volume");
        }
        function decVolume(): void {
            Audio.decVolume();
            OsdState.show("volume");
        }
        function toggleMute(): void {
            Audio.toggleMute();
            OsdState.show("volume");
        }
        function toggleMicMute(): void {
            Audio.toggleMicMute();
            OsdState.show("mic");
        }
    }

    IpcHandler {
        target: "brightness"

        function inc(): void {
            Brightness.inc();
            OsdState.show("brightness");
        }
        function dec(): void {
            Brightness.dec();
            OsdState.show("brightness");
        }
    }

    IpcHandler {
        target: "controlcenter"

        function toggle(): void {
            if (ccLoader.item)
                ccLoader.item.toggle();
        }
    }
}
