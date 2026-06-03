import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: panel
    readonly property int panelWidth: 220
    width: panelWidth
    implicitHeight: mainCol.implicitHeight + 28

    property var procs: []

    function loadProcs() {
        procReader.running = true
    }

    Process {
        id: procReader
        command: ["bash", Quickshell.env("HOME") + "/.config/quickshell/tray-procs.sh"]
        running: false
        onExited: procsFile.reload()
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
                if (parts.length === 3) {
                    result.push({ name: parts[0], icon: parts[1], exec: parts[2] })
                }
            }
            panel.procs = result
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
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 11
                color: "#928374"
                text: "En segundo plano"
                width: parent.width - refreshBtn.width
            }

            Text {
                id: refreshBtn
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 11
                color: refreshHover.containsMouse ? "#b8bb26" : "#504945"
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
            color: "#3c3836"
        }

        Repeater {
            model: panel.procs
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
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 11
                        color: itemHover.containsMouse ? "#ebdbb2" : "#a89984"
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
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 12
                    color: killHover.containsMouse ? "#fb4934" : "#504945"
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
                        command: ["pkill", "-x", modelData.exec]
                        onExited: {}
                    }

                    Timer {
                        id: killTimer
                        interval: 500
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
            font.family: "FiraCode Nerd Font"
            font.pixelSize: 10
            color: "#665c54"
            text: "Sin procesos en segundo plano"
        }
    }

    Component.onCompleted: loadProcs()
}
