import QtQuick
import Quickshell
import Quickshell.Io
import qs.bar

ShellRoot {
    Variants {
        model: Quickshell.screens

        delegate: Component {
            Bar {}
        }
    }

    // External control surface (`qs ipc call <target> <fn>`). Stage B adds
    // audio/brightness/controlcenter targets here.
    IpcHandler {
        target: "shell"

        function ping(): string {
            return "pong";
        }
    }
}
