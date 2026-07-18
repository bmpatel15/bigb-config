pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// The notification daemon. History = server.trackedNotifications (kept until
// dismissed); popups are a separate transient list. DND suppresses popups
// only — everything still lands in history. swaync's D-Bus activation file
// remains installed as a crash failsafe: if qs dies, the next notification
// auto-spawns swaync.
Singleton {
    id: root

    readonly property var history: server.trackedNotifications
    readonly property int count: history.values.length
    property var popups: []
    property alias dnd: persist.dnd
    property bool centerOpen: false

    function toggleDnd() {
        persist.dnd = !persist.dnd;
    }

    function toggleCenter() {
        centerOpen = !centerOpen;
    }

    function clearAll() {
        const list = history.values.slice();
        for (const n of list)
            n.dismiss();
    }

    function removePopup(n) {
        popups = popups.filter(p => p !== n);
    }

    onCountChanged: {
        // Cap history; evict oldest with expire() (reports timeout, not
        // user dismissal, to the sending app).
        if (count > 50)
            history.values[0].expire();
    }

    PersistentProperties {
        id: persist
        reloadableId: "notifs"
        property bool dnd: false
    }

    NotificationServer {
        id: server
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true
        // bodySupported defaults true; markup deliberately not advertised —
        // cards render PlainText.

        onNotification: n => {
            n.tracked = true;
            n.closed.connect(() => root.removePopup(n));
            // keepOnReload re-emits prior-generation notifications on every
            // hot reload — keep them in history but never re-popup them.
            if (n.lastGeneration || persist.dnd)
                return;
            root.popups = [n, ...root.popups].slice(0, 4);
        }
    }
}
