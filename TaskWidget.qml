import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Item {
    id: root
    width: 30
    implicitHeight: root.windows.length > 0 ? col.implicitHeight + 8 : 120

    property bool overflowOpen: false
    property var windows: []

    function refresh() {
        taskFetcher.running = true
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

    Component.onCompleted: {
        refresh()
        refreshTimer.start()
    }

    Connections {
        target: Hyprland
        function onActiveToplevelChanged() { refresh() }
        function onFocusedWorkspaceChanged() { refresh() }
    }

    Timer {
        id: refreshTimer
        interval: 2000
        repeat: true
        onTriggered: refresh()
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
        color: "#282828"
        radius: 8
    }

    Item {
        id: emptyState
        visible: root.windows.length === 0
        anchors.fill: parent

        Text {
            anchors.centerIn: parent
            text: "\uFAA8"
            font.family: "FiraCode Nerd Font"
            font.pixelSize: 16
            color: "#504945"
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
                isMinimized: modelData.workspace ? modelData.workspace.id === 99 : false
            }
        }

        Text {
            visible: root.windows.length > 5
            anchors.horizontalCenter: parent.horizontalCenter
            text: "\u25B4"
            font.family: "FiraCode Nerd Font"
            font.pixelSize: 10
            color: "#a89984"

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
            font.family: "FiraCode Nerd Font"
            font.pixelSize: 14
            color: "#b8bb26"
            opacity: 0.6
        }
    }
}
