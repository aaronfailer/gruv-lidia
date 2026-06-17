import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "."

Item {
    id: panel
    readonly property int panelWidth: 220
    width: panelWidth
    implicitHeight: mainCol.implicitHeight + 28

    signal itemClicked()

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
            panel.windows = []
            return
        }

        let parsed
        try {
            parsed = JSON.parse(text.trim())
        } catch(e) {
            panel.windows = []
            return
        }
        if (!Array.isArray(parsed)) {
            panel.windows = []
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
        panel.windows = result
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

    Column {
        id: mainCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 6

        Text {
            text: "Ventanas"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize11
            color: Theme.textMuted
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.surface
        }

        Repeater {
            model: panel.windows

            delegate: Item {
                required property var modelData
                width: parent.width
                height: 28

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radius6
                    color: itemHover.containsMouse ? Theme.surfaceHover : "transparent"
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    spacing: 8

                    Image {
                        width: 18
                        height: 18
                        anchors.verticalCenter: parent.verticalCenter
                        source: "image://icon/" + panel.resolveIcon(modelData.initialClass || modelData.class || "")
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize11
                        color: itemHover.containsMouse ? Theme.textPrimary : Theme.textSecondary
                        text: modelData.title || ""
                        elide: Text.ElideRight
                        width: panelWidth - 60
                    }
                }

                MouseArea {
                    id: itemHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const isMinimized = modelData.workspace ? modelData.workspace.id === 99 : false
                        const addr = modelData.address
                        if (isMinimized) {
                            const ws = Hyprland.focusedWorkspace.id
                            Hyprland.dispatch("movetoworkspacesilent " + ws + ",address:" + addr)
                        } else {
                            Hyprland.dispatch("movetoworkspacesilent 99,address:" + addr)
                        }
                        panel.itemClicked()
                        panel.refresh()
                    }
                }
            }
        }

        Text {
            visible: panel.windows.length === 0
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize10
            color: Theme.textDim
            text: "No hay ventanas abiertas"
        }
    }
}
