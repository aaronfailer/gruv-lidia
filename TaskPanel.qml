import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

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

    Column {
        id: mainCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 6

        Text {
            text: "Ventanas"
            font.family: "FiraCode Nerd Font"
            font.pixelSize: 11
            color: "#928374"
        }

        Rectangle {
            width: parent.width
            height: 1
            color: "#3c3836"
        }

        Repeater {
            model: panel.windows

            delegate: Item {
                required property var modelData
                width: parent.width
                height: 28

                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: itemHover.containsMouse ? "#3c3836" : "transparent"
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
                        source: "image://icon/" + (modelData.initialClass || modelData.class || "")
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 11
                        color: itemHover.containsMouse ? "#ebdbb2" : "#a89984"
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
                        const currentWs = Hyprland.focusedWorkspace.id
                        if (isMinimized) {
                            Hyprland.dispatch("workspace 99")
                            Hyprland.dispatch("movetoworkspace " + currentWs)
                        } else {
                            Hyprland.dispatch("focuswindow address:" + modelData.address.replace(/^0x/, ""))
                        }
                        panel.itemClicked()
                    }
                }
            }
        }

        Text {
            visible: panel.windows.length === 0
            font.family: "FiraCode Nerd Font"
            font.pixelSize: 10
            color: "#665c54"
            text: "No hay ventanas abiertas"
        }
    }
}
