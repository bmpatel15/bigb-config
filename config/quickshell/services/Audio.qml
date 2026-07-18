pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Default sink/source state + mutations. Nodes must stay bound through the
// PwObjectTracker or their .audio properties are inert.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool ready: Pipewire.ready && sink !== null

    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property bool micMuted: source?.audio?.muted ?? false

    function setVolume(v) {
        if (sink?.audio)
            sink.audio.volume = Math.max(0, Math.min(1, v));
    }
    function incVolume() { setVolume(volume + 0.05); }
    function decVolume() { setVolume(volume - 0.05); }
    function toggleMute() {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }
    function toggleMicMute() {
        if (source?.audio)
            source.audio.muted = !source.audio.muted;
    }

    PwObjectTracker {
        objects: [root.sink, root.source]
    }
}
