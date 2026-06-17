import QtQuick
import Quickshell
import Quickshell.Io
import "."

Item {
    id: panel
    readonly property int panelWidth: 260
    width: panelWidth
    height: 350

    property bool btPowered: false
    property var knownDevices: []
    property var connectedDevices: []
    property bool scanning: false

    Process {
        id: showReader
        command: ["bash", "-c", "bluetoothctl --timeout 2 show > /tmp/qs_bt_show.txt"]
        running: true
        onExited: showFile.reload()
    }

    FileView {
        id: showFile
        path: "/tmp/qs_bt_show.txt"
        onTextChanged: {
            panel.btPowered = showFile.text().includes("Powered: yes")
        }
    }

    Process {
        id: devicesReader
        command: ["bash", "-c", "bluetoothctl --timeout 5 devices > /tmp/qs_bt_devices.txt"]
        running: true
        onExited: devicesFile.reload()
    }

    FileView {
        id: devicesFile
        path: "/tmp/qs_bt_devices.txt"
        onTextChanged: {
            const text = devicesFile.text()
            if (!text || text.trim() === "") { panel.knownDevices = []; return }
            const lines = text.trim().split("\n")
            const result = []
            for (let i = 0; i < lines.length; i++) {
                const m = lines[i].match(/Device\s+(\S+)\s+(.+)/)
                if (m) result.push({ address: m[1], name: m[2].trim() })
            }
            panel.knownDevices = result
        }
    }

    Process {
        id: connectedReader
        command: ["bash", "-c", "bluetoothctl --timeout 5 devices Connected > /tmp/qs_bt_connected.txt"]
        running: true
        onExited: connectedFile.reload()
    }

    FileView {
        id: connectedFile
        path: "/tmp/qs_bt_connected.txt"
        onTextChanged: {
            const text = connectedFile.text()
            if (!text || text.trim() === "") { panel.connectedDevices = []; return }
            const lines = text.trim().split("\n")
            const result = []
            for (let i = 0; i < lines.length; i++) {
                const m = lines[i].match(/Device\s+(\S+)/)
                if (m) result.push(m[1])
            }
            panel.connectedDevices = result
        }
    }

    Process {
        id: powerOnProcess
        command: ["bluetoothctl", "power", "on"]
        onExited: showReader.running = true
    }

    Process {
        id: powerOffProcess
        command: ["bluetoothctl", "power", "off"]
        onExited: showReader.running = true
    }

    Process {
        id: scanProcess
        command: ["bash", "-c", "bluetoothctl --timeout 10 scan on > /dev/null 2>&1"]
        onExited: {
            panel.scanning = false
            devicesReader.running = true
            connectedReader.running = true
        }
    }

    Process {
        id: connectProcess
        property string deviceAddress: ""
        command: ["bash", "-c", "bluetoothctl --timeout 15 connect " + deviceAddress + " > /dev/null 2>&1"]
        onExited: {
            devicesReader.running = true
            connectedReader.running = true
        }
    }

    Process {
        id: disconnectProcess
        property string deviceAddress: ""
        command: ["bash", "-c", "bluetoothctl disconnect " + deviceAddress + " > /dev/null 2>&1"]
        onExited: {
            devicesReader.running = true
            connectedReader.running = true
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            showReader.running = true
            devicesReader.running = true
            connectedReader.running = true
        }
    }

    function getMergedDevices() {
        const cmap = {}
        for (let i = 0; i < panel.connectedDevices.length; i++)
            cmap[panel.connectedDevices[i]] = true
        const result = []
        for (let i = 0; i < panel.knownDevices.length; i++) {
            const d = panel.knownDevices[i]
            result.push({
                address: d.address,
                name: d.name,
                connected: !!cmap[d.address]
            })
        }
        return result
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: 14
        contentHeight: contentColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: contentColumn
            width: parent.width
            spacing: 10

            Text {
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize11
                color: Theme.textMuted
                text: "\uF093 Bluetooth"
            }

            Row {
                width: parent.width
                spacing: 8
                Rectangle {
                    width: 44; height: 22; radius: 11
                    color: panel.btPowered ? Theme.accentBlue : Theme.surface
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (panel.btPowered) powerOffProcess.running = true
                            else powerOnProcess.running = true
                        }
                        Rectangle {
                            x: panel.btPowered ? parent.width - width : 0
                            y: (parent.height - height) / 2
                            width: 18; height: 18; radius: 9
                            color: Theme.textPrimary
                            Behavior on x { NumberAnimation { duration: 150 } }
                        }
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize12
                    color: panel.btPowered ? Theme.textPrimary : Theme.textMuted
                    text: panel.btPowered ? "Encendido" : "Apagado"
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.surface }

            Rectangle {
                width: parent.width; height: 28; radius: Theme.radius4
                color: scanBtnHover.containsMouse ? Theme.surfaceHover : "transparent"
                border.color: Theme.border; border.width: 1
                opacity: panel.btPowered ? 1.0 : Theme.opacityDisabled
                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize11
                    color: panel.scanning ? Theme.textSecondary : Theme.textPrimary
                    text: panel.scanning ? "Escaneando..." : "Escaneá dispositivos"
                }
                MouseArea {
                    id: scanBtnHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!panel.btPowered || panel.scanning) return
                        panel.scanning = true
                        scanProcess.running = true
                    }
                }
            }

            Text {
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize11
                color: Theme.textMuted
                text: "Dispositivos"
            }

            Column {
                width: parent.width
                spacing: 4

                Repeater {
                    model: panel.getMergedDevices()

                    delegate: Item {
                        required property var modelData
                        width: parent.width
                        height: 24

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.radius4
                            color: rowHover.hovered ? Theme.surfaceHover : "transparent"
                        }

                        HoverHandler { id: rowHover }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left; anchors.leftMargin: 6
                            anchors.right: connectBtn.left; anchors.rightMargin: 4
                            elide: Text.ElideRight
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize10
                            color: modelData.connected ? Theme.accent : Theme.textSecondary
                            text: (modelData.connected ? "\u25CF " : "\u25CB ") + modelData.name
                        }

                        Rectangle {
                            id: connectBtn
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right; anchors.rightMargin: 4
                            width: 50; height: 18; radius: 3
                            color: "transparent"
                            border.color: modelData.connected ? Theme.accentRed : Theme.accentBlue
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize9
                                color: modelData.connected ? Theme.accentRedBright : Theme.accentBlueBright
                                text: modelData.connected ? "Descon." : "Conectar"
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.connected) {
                                        disconnectProcess.deviceAddress = modelData.address
                                        disconnectProcess.running = true
                                    } else {
                                        connectProcess.deviceAddress = modelData.address
                                        connectProcess.running = true
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: panel.knownDevices.length === 0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize10
                    color: Theme.border
                    text: "No hay dispositivos"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}
