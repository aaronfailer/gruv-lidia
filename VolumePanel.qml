import QtQuick
import Quickshell
import Quickshell.Io
import "."

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

    Process { id: volUp;   command: ["bash", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ $(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{v=$2+0.05; if(v>1.2)v=1.2; print v}')"]; onExited: volReader.running = true }
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
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize11
            color: Theme.textMuted
            text: "Volumen"
        }

        Row {
            width: parent.width
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize14
                color: panel.muted ? Theme.textMuted : Theme.accent
                text: panel.muted ? "󰝟" : "󰕾"
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: volMute.running = true
                }
            }

            Column {
                width: parent.width - 22
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    anchors.right: parent.right
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize9
                    color: panel.volume > 1.0 ? "#e06c75" : Theme.textPrimary
                    text: Math.round(panel.volume * 100) + "%"
                }

                Rectangle {
                    id: sliderTrack
                    width: parent.width
                    height: 6
                    radius: Theme.radius3
                    color: Theme.surface

                    Rectangle {
                        width: parent.width * Math.min(panel.volume / 1.2, 1.0)
                        height: parent.height
                        radius: parent.radius
                        color: panel.muted ? Theme.textMuted : (panel.volume > 1.0 ? "#e06c75" : Theme.accent)
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            setVolProcess.vol = Math.min(1.2, (mouseX / width) * 1.2).toFixed(2)
                            setVolProcess.running = true
                        }
                    }
                }
            }
        }

        Row {
            spacing: 6
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                width: 28; height: 20; radius: Theme.radius4
                color: volDownHover.containsMouse ? Theme.surfaceHover : "transparent"
                border.color: Theme.border; border.width: 1
                Text { anchors.centerIn: parent; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize12; color: Theme.textPrimary; text: "−" }
                MouseArea { id: volDownHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: volDown.running = true }
            }

            Rectangle {
                width: 28; height: 20; radius: Theme.radius4
                color: volUpHover.containsMouse ? Theme.surfaceHover : "transparent"
                border.color: Theme.border; border.width: 1
                Text { anchors.centerIn: parent; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize12; color: Theme.textPrimary; text: "+" }
                MouseArea { id: volUpHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: volUp.running = true }
            }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.surface }

        // Salidas
        Text {
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize11
            color: Theme.textMuted
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

                    Rectangle { anchors.fill: parent; radius: Theme.radius4; color: sinkHover.containsMouse ? Theme.surfaceHover : "transparent"; border.color: modelData.isDefault ? Theme.accent : "transparent"; border.width: 1 }

                    Item {
                        id: sinkTextClip
                        clip: true
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left; anchors.leftMargin: 6
                        anchors.right: parent.right; anchors.rightMargin: 6
                        height: parent.height

                        Text {
                            id: sinkText
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize10
                            color: modelData.isDefault ? Theme.accent : Theme.textSecondary
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

        Rectangle { width: parent.width; height: 1; color: Theme.surface }

        // Entradas
        Text {
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize11
            color: Theme.textMuted
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

                    Rectangle { anchors.fill: parent; radius: Theme.radius4; color: sourceHover.containsMouse ? Theme.surfaceHover : "transparent"; border.color: modelData.isDefault ? Theme.accent : "transparent"; border.width: 1 }

                    Item {
                        id: sourceTextClip
                        clip: true
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left; anchors.leftMargin: 6
                        anchors.right: parent.right; anchors.rightMargin: 6
                        height: parent.height

                        Text {
                            id: sourceText
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize10
                            color: modelData.isDefault ? Theme.accent : Theme.textSecondary
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
