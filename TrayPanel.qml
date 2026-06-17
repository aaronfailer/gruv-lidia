import QtQuick
import Quickshell
import Quickshell.Io
import "."

Item {
    id: panel
    readonly property int panelWidth: 220
    width: panelWidth
    implicitHeight: mainCol.implicitHeight + 28

    property var procs: []
    property var foreProcs: []

    function loadProcs() {
        procReader.running = true
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: panel.loadProcs()
    }

    Process {
        id: procReader
        command: ["bash", Quickshell.env("HOME") + "/.config/quickshell/tray-procs.sh"]
        running: false
        onExited: {
            procsFile.reload()
            foreProcsFile.reload()
        }
    }

    FileView {
        id: procsFile
        path: "/tmp/qs_tray_procs.txt"
        onTextChanged: {
            const text = procsFile.text()
            if (!text || text.trim() === "") {
                panel.procs = []
                return
            }
            const lines = text.trim().split("\n")
            const result = []
            for (let i = 0; i < lines.length; i++) {
                const parts = lines[i].split("|")
                if (parts.length >= 3) {
                    result.push({ name: parts[0], icon: parts[1], exec: parts[2], flatpakId: parts[3] || "" })
                }
            }
            panel.procs = result
        }
    }

    FileView {
        id: foreProcsFile
        path: "/tmp/qs_tray_foreground.txt"
        onTextChanged: {
            const text = foreProcsFile.text()
            if (!text || text.trim() === "") {
                panel.foreProcs = []
                return
            }
            const lines = text.trim().split("\n")
            const result = []
            for (let i = 0; i < lines.length; i++) {
                const parts = lines[i].split("|")
                if (parts.length >= 3) {
                    result.push({ name: parts[0], icon: parts[1], exec: parts[2], flatpakId: parts[3] || "" })
                }
            }
            panel.foreProcs = result
        }
    }

    Column {
        id: mainCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 6

        Row {
            width: parent.width

            Text {
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize11
                color: Theme.textMuted
                text: "En segundo plano"
                width: parent.width - refreshBtn.width
            }

            Text {
                id: refreshBtn
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize11
                color: refreshHover.containsMouse ? Theme.accent : Theme.border
                text: "󰑓"

                MouseArea {
                    id: refreshHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: panel.loadProcs()
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.surface
        }

        Repeater {
            model: panel.procs
            delegate: Item {
                required property var modelData
                width: parent.width
                height: 28

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radius6
                    color: itemHover.containsMouse ? Theme.surface : "transparent"
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    anchors.right: killBtn.left
                    anchors.rightMargin: 4
                    spacing: 8

                    Image {
                        width: 18
                        height: 18
                        anchors.verticalCenter: parent.verticalCenter
                        source: "image://icon/" + modelData.icon
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize11
                        color: itemHover.containsMouse ? Theme.textPrimary : Theme.textSecondary
                        text: modelData.name
                        elide: Text.ElideRight
                        width: 120
                    }
                }

                Text {
                    id: killBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize12
                    color: killHover.containsMouse ? Theme.accentRedBright : Theme.border
                    text: "✕"

                    MouseArea {
                        id: killHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            killProcess.running = true
                            killTimer.start()
                        }
                    }

                    Process {
                        id: killProcess
                        command: modelData.flatpakId
                            ? ["flatpak", "kill", modelData.flatpakId]
                            : ["bash", "-c", "pkill -ix '" + modelData.exec + "' 2>/dev/null || pkill -f '^" + modelData.exec + "[ /]' 2>/dev/null"]
                        onExited: {}
                    }

                    Timer {
                        id: killTimer
                        interval: 200
                        repeat: false
                        onTriggered: panel.loadProcs()
                    }
                }

                MouseArea {
                    id: itemHover
                    anchors.left: parent.left
                    anchors.right: killBtn.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: launchProcess.running = true
                }

                Process {
                    id: launchProcess
                    command: ["bash", "-c", "nohup gtk-launch " + modelData.exec + " &>/dev/null &"]
                }
            }
        }

        Text {
            visible: panel.procs.length === 0
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize10
            color: Theme.textDim
            text: "Sin procesos en segundo plano"
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.surface
            visible: panel.foreProcs.length > 0
        }

        Text {
            visible: panel.foreProcs.length > 0
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize11
            color: Theme.textMuted
            text: "En primer plano"
        }

        Repeater {
            model: panel.foreProcs
            delegate: Item {
                required property var modelData
                width: parent.width
                height: 28

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radius6
                    color: itemHover.containsMouse ? Theme.surface : "transparent"
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    anchors.right: killBtn.left
                    anchors.rightMargin: 4
                    spacing: 8

                    Image {
                        width: 18
                        height: 18
                        anchors.verticalCenter: parent.verticalCenter
                        source: "image://icon/" + modelData.icon
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize11
                        color: itemHover.containsMouse ? Theme.textPrimary : Theme.textSecondary
                        text: modelData.name
                        elide: Text.ElideRight
                        width: 120
                    }
                }

                Text {
                    id: killBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize12
                    color: killHover.containsMouse ? Theme.accentRedBright : Theme.border
                    text: "\u2715"

                    MouseArea {
                        id: killHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            killProcess.running = true
                            killTimer.start()
                        }
                    }

                    Process {
                        id: killProcess
                        command: modelData.flatpakId
                            ? ["flatpak", "kill", modelData.flatpakId]
                            : ["bash", "-c", "pkill -ix '" + modelData.exec + "' 2>/dev/null || pkill -f '^" + modelData.exec + "[ /]' 2>/dev/null"]
                        onExited: {}
                    }

                    Timer {
                        id: killTimer
                        interval: 200
                        repeat: false
                        onTriggered: panel.loadProcs()
                    }
                }

                MouseArea {
                    id: itemHover
                    anchors.left: parent.left
                    anchors.right: killBtn.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }

        Text {
            visible: panel.foreProcs.length === 0
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize10
            color: Theme.textDim
            text: "Sin programas en primer plano"
        }
    }

    Component.onCompleted: loadProcs()
}
