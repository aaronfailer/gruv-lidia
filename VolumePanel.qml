import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: panel
    readonly property int panelWidth: 260
    width: panelWidth
    implicitHeight: mainColumn.implicitHeight + 28

    property real volume: 0.0
    property bool muted: false
    property var sinks: []
    property var sources: []

    Process {
        id: volReader
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ > /tmp/qs_vol.txt"]
        running: true
        onExited: volFile.reload()
    }

    FileView {
        id: volFile
        path: "/tmp/qs_vol.txt"
        onTextChanged: {
            const text = volFile.text()
            if (!text || text.trim() === "") return
                panel.muted = text.includes("MUTED")
                const match = text.match(/[\d.]+/)
                if (match) panel.volume = parseFloat(match[0])
        }
    }

    Process {
        id: sinksReader
        command: ["bash", "-c", "wpctl status | awk '/Sinks:/{found=1; next} /Sources:/{found=0} found && /\\./' > /tmp/qs_sinks.txt"]
        running: true
        onExited: sinksFile.reload()
    }

    FileView {
        id: sinksFile
        path: "/tmp/qs_sinks.txt"
        onTextChanged: {
            const text = sinksFile.text()
            if (!text || text.trim() === "") return
                const lines = text.trim().split("\n")
                const result = []
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i]
                    const isDefault = line.includes("*")
                    const idMatch = line.match(/(\d+)\./)
                    const name = line.replace(/^[^\d]*\d+\.\s*/, "").replace(/\[.*\]/, "").trim()
                    if (idMatch && name) result.push({ id: idMatch[1], name: name, isDefault: isDefault })
                }
                panel.sinks = result
        }
    }

    Process {
        id: sourcesReader
        command: ["bash", "-c", "wpctl status | awk '/Filters:/{f=1; next} f && /\\[Audio\\/Source\\]/' > /tmp/qs_sources.txt"]
        running: true
        onExited: sourcesFile.reload()
    }

    FileView {
        id: sourcesFile
        path: "/tmp/qs_sources.txt"
        onTextChanged: {
            const text = sourcesFile.text()
            if (!text || text.trim() === "") return
                const lines = text.trim().split("\n")
                const result = []
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i]
                    const isDefault = line.includes("*")
                    const idMatch = line.match(/(\d+)\./)
                    const name = line.replace(/^[^\d]*\d+\.\s*/, "").replace(/\[.*\]/, "").trim()
                    if (idMatch && name) result.push({ id: idMatch[1], name: name, isDefault: isDefault })
                }
                panel.sources = result
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            volReader.running = true
            sinksReader.running = true
            sourcesReader.running = true
        }
    }

    Process { id: volUp;   command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%+"]; onExited: volReader.running = true }
    Process { id: volDown; command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"]; onExited: volReader.running = true }
    Process { id: volMute; command: ["wpctl", "set-mute",   "@DEFAULT_AUDIO_SINK@", "toggle"]; onExited: volReader.running = true }
    Process { id: setVolProcess; property string vol: "0.5"; command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", vol]; onExited: volReader.running = true }

    Process {
        id: setDefaultSinkProcess
        property string sinkId: ""
        command: ["wpctl", "set-default", sinkId]
        onExited: sinksReader.running = true
    }

    Process {
        id: setDefaultSourceProcess
        property string sourceId: ""
        command: ["wpctl", "set-default", sourceId]
        onExited: sourcesReader.running = true
    }

    Column {
        id: mainColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 10

        Text {
            font.family: "FiraCode Nerd Font"
            font.pixelSize: 11
            color: "#928374"
            text: "Volumen"
        }

        Row {
            width: parent.width
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 14
                color: panel.muted ? "#928374" : "#b8bb26"
                text: panel.muted ? "󰝟" : "󰕾"
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: volMute.running = true
                }
            }

            Rectangle {
                id: sliderTrack
                width: parent.width - 60
                height: 6
                radius: 3
                color: "#3c3836"
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    width: parent.width * Math.min(panel.volume, 1.0)
                    height: parent.height
                    radius: parent.radius
                    color: panel.muted ? "#928374" : "#b8bb26"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        setVolProcess.vol = (mouseX / width).toFixed(2)
                        setVolProcess.running = true
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 10
                color: "#ebdbb2"
                text: Math.round(panel.volume * 100) + "%"
                width: 32
            }
        }

        Row {
            spacing: 6
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                width: 28; height: 20; radius: 4
                color: volDownHover.containsMouse ? "#3c3836" : "transparent"
                border.color: "#504945"; border.width: 1
                Text { anchors.centerIn: parent; font.family: "FiraCode Nerd Font"; font.pixelSize: 12; color: "#ebdbb2"; text: "−" }
                MouseArea { id: volDownHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: volDown.running = true }
            }

            Rectangle {
                width: 28; height: 20; radius: 4
                color: volUpHover.containsMouse ? "#3c3836" : "transparent"
                border.color: "#504945"; border.width: 1
                Text { anchors.centerIn: parent; font.family: "FiraCode Nerd Font"; font.pixelSize: 12; color: "#ebdbb2"; text: "+" }
                MouseArea { id: volUpHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: volUp.running = true }
            }
        }

        Rectangle { width: parent.width; height: 1; color: "#3c3836" }

        // Salidas
        Text {
            font.family: "FiraCode Nerd Font"
            font.pixelSize: 11
            color: "#928374"
            text: "Salidas"
        }

        Column {
            width: parent.width
            spacing: 4

            Repeater {
                model: panel.sinks
                delegate: Item {
                    required property var modelData
                    width: parent.width
                    height: 22

                    Rectangle { anchors.fill: parent; radius: 4; color: sinkHover.containsMouse ? "#3c3836" : "transparent"; border.color: modelData.isDefault ? "#b8bb26" : "transparent"; border.width: 1 }

                    Item {
                        id: sinkTextClip
                        clip: true
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left; anchors.leftMargin: 6
                        anchors.right: parent.right; anchors.rightMargin: 6
                        height: parent.height

                        Text {
                            id: sinkText
                            font.family: "FiraCode Nerd Font"
                            font.pixelSize: 10
                            color: modelData.isDefault ? "#b8bb26" : "#a89984"
                            text: (modelData.isDefault ? "● " : "○ ") + modelData.name
                        }
                    }

                    MouseArea {
                        id: sinkHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        property real dragStartX: 0
                        onPressed: dragStartX = mouse.x
                        onPositionChanged: {
                            if (pressed) {
                                var dx = mouse.x - dragStartX
                                sinkText.x += dx
                                sinkText.x = Math.min(0, Math.max(sinkTextClip.width - sinkText.implicitWidth, sinkText.x))
                                dragStartX = mouse.x
                            }
                        }
                        onClicked: {
                            setDefaultSinkProcess.sinkId = modelData.id
                            setDefaultSinkProcess.running = true
                        }
                    }
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: "#3c3836" }

        // Entradas
        Text {
            font.family: "FiraCode Nerd Font"
            font.pixelSize: 11
            color: "#928374"
            text: "Entradas"
        }

        Column {
            width: parent.width
            spacing: 4

            Repeater {
                model: panel.sources
                delegate: Item {
                    required property var modelData
                    width: parent.width
                    height: 22

                    Rectangle { anchors.fill: parent; radius: 4; color: sourceHover.containsMouse ? "#3c3836" : "transparent"; border.color: modelData.isDefault ? "#b8bb26" : "transparent"; border.width: 1 }

                    Item {
                        id: sourceTextClip
                        clip: true
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left; anchors.leftMargin: 6
                        anchors.right: parent.right; anchors.rightMargin: 6
                        height: parent.height

                        Text {
                            id: sourceText
                            font.family: "FiraCode Nerd Font"
                            font.pixelSize: 10
                            color: modelData.isDefault ? "#b8bb26" : "#a89984"
                            text: (modelData.isDefault ? "● " : "○ ") + modelData.name
                        }
                    }

                    MouseArea {
                        id: sourceHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        property real dragStartX: 0
                        onPressed: dragStartX = mouse.x
                        onPositionChanged: {
                            if (pressed) {
                                var dx = mouse.x - dragStartX
                                sourceText.x += dx
                                sourceText.x = Math.min(0, Math.max(sourceTextClip.width - sourceText.implicitWidth, sourceText.x))
                                dragStartX = mouse.x
                            }
                        }
                        onClicked: {
                            setDefaultSourceProcess.sourceId = modelData.id
                            setDefaultSourceProcess.running = true
                        }
                    }
                }
            }
        }
    }
}
