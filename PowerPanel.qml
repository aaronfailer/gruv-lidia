import QtQuick
import Quickshell.Io

Item {
    id: panel
    readonly property int panelWidth: 220
    readonly property int panelHeight: 90
    width: panelWidth
    implicitHeight: panelHeight

    readonly property var actions: [
        { label: "Apagar",    glyph: "⏻", cmd: ["systemctl", "poweroff"], color: "#fb4934" },
        { label: "Reiniciar", glyph: "↺", cmd: ["systemctl", "reboot"],   color: "#fabd2f" },
        { label: "Suspender", glyph: "⏾", cmd: ["systemctl", "suspend"],  color: "#83a598" },
        { label: "Salir",     glyph: "󰍃", cmd: ["hyprctl", "dispatch", "exit"], color: "#b8bb26" }
    ]

    Row {
        anchors.centerIn: parent
        spacing: 10

        Repeater {
            model: panel.actions
            delegate: Item {
                required property var modelData
                width: 42
                height: 60

                Process {
                    id: actionProcess
                    command: modelData.cmd
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 6

                    Rectangle {
                        width: 38
                        height: 38
                        radius: 19
                        color: btnHover.containsMouse ? Qt.rgba(
                            parseInt(modelData.color.slice(1,3), 16) / 255,
                                                                parseInt(modelData.color.slice(3,5), 16) / 255,
                                                                parseInt(modelData.color.slice(5,7), 16) / 255,
                                                                0.15
                        ) : "#282828"
                        border.color: btnHover.containsMouse ? modelData.color : "#504945"
                        border.width: btnHover.containsMouse ? 2 : 1
                        anchors.horizontalCenter: parent.horizontalCenter

                        Text {
                            anchors.centerIn: parent
                            font.family: "FiraCode Nerd Font"
                            font.pixelSize: 16
                            color: btnHover.containsMouse ? modelData.color : "#928374"
                            text: modelData.glyph
                        }

                        MouseArea {
                            id: btnHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: actionProcess.running = true
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 9
                        color: btnHover.containsMouse ? modelData.color : "#928374"
                        text: modelData.label
                    }
                }
            }
        }
    }
}
