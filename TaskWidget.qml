import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "."

Item {
    id: root
    width: 30
    implicitHeight: root.windows.length > 0 ? col.implicitHeight + 8 : 120

    property bool overflowOpen: false
    property var windows: []

    function refresh() {
        taskFetcher.running = true
    }

    function resolveIcon(cls) {
        if (!cls) return ""
        var entry = DesktopEntries.heuristicLookup(cls)
        if (entry && entry.icon) return entry.icon
        var stripped = cls.replace(/\.exe$/i, "")
        if (stripped !== cls) {
            entry = DesktopEntries.heuristicLookup(stripped)
            if (entry && entry.icon) return entry.icon
            var winename = "wine-" + stripped.toLowerCase()
            entry = DesktopEntries.heuristicLookup(winename)
            if (entry && entry.icon) return entry.icon
        }
        return cls
    }

    function parseTasks(text) {
        if (!text || text.trim() === "") {
            root.windows = []
            return
        }

        let parsed
        try {
            parsed = JSON.parse(text.trim())
        } catch(e) {
            root.windows = []
            return
        }
        if (!Array.isArray(parsed)) {
            root.windows = []
            return
        }

        const ws = Hyprland.focusedWorkspace
        const wid = ws ? ws.id : null
        const result = []
        for (let i = 0; i < parsed.length; i++) {
            const c = parsed[i]
            if (!c || !c.mapped) continue
            const cWid = c.workspace ? c.workspace.id : null
            if (cWid !== null && (wid === null || cWid === wid || cWid === 99)) {
                result.push(c)
            }
        }
        root.windows = result
    }

    Component.onCompleted: refresh()

    Connections {
        target: Hyprland
        function onActiveToplevelChanged() { refresh() }
        function onFocusedWorkspaceChanged() { refresh() }
    }

    Timer {
        id: refreshTimer
        interval: 2000
        running: true
        repeat: true
        onTriggered: refresh()
    }

    Process {
        id: eventMonitor
        command: ["bash", "-c", "FP=$(find /run -path '*/hypr/*/.socket2.sock' -type s 2>/dev/null | head -1) && [ -n \"$FP\" ] && socat -U UNIX-CONNECT:\"$FP\" - 2>/dev/null | while read line; do case $line in window*|focusedmon*) echo \"$line\" > /tmp/qs_hypr_events.tmp;; esac; done"]
        running: true
        onExited: monitorRestart.running = true
    }

    Timer {
        id: monitorRestart
        interval: 1000
        onTriggered: eventMonitor.running = true
    }

    FileView {
        path: "/tmp/qs_hypr_events.tmp"
        onTextChanged: refresh()
    }

    Process {
        id: taskFetcher
        command: ["sh", "-c", "hyprctl clients -j"]
        stdout: StdioCollector {
            id: collector
            waitForEnd: true
        }
        onExited: {
            const text = collector.data.toString()
            if (text) parseTasks(text)
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.backgroundAlt
        radius: Theme.radius8
    }

    Item {
        id: emptyState
        visible: root.windows.length === 0
        anchors.fill: parent

        Text {
            anchors.centerIn: parent
            text: "\uFAA8"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize16
            color: Theme.border
        }
    }

    Column {
        id: col
        visible: root.windows.length > 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6
        width: parent.width
        spacing: 4

        Repeater {
            model: {
                const list = root.windows
                const sliced = list.slice(0, 5)
                return sliced.reverse()
            }

            delegate: TaskItem {
                required property var modelData
                clientAddress: modelData.address.replace(/^0x/, "")
                clientClass: modelData.initialClass || modelData.class || ""
                clientIcon: root.resolveIcon(modelData.initialClass || modelData.class || "")
                isMinimized: modelData.workspace ? modelData.workspace.id === 99 : false
                onTaskChanged: root.refresh()
            }
        }

        Text {
            visible: root.windows.length > 5
            anchors.horizontalCenter: parent.horizontalCenter
            text: "\u25B4"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize10
            color: Theme.textSecondary

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: root.overflowOpen = !root.overflowOpen
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "\uEE80"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize14
            color: Theme.iconWidget
            opacity: Theme.opacityMedium
        }
    }
}
