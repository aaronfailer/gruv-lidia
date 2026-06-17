import QtQuick
import Quickshell
import Quickshell.Io
import "."

Item {
    id: panel
    readonly property int panelWidth: 260
    readonly property int panelHeight: 100
    width: panelWidth
    implicitHeight: panelHeight

    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/quickshell/scripts/"

    readonly property var actions: [
        {
            label: "Actualizar",
            glyph: "󰓦",
            script: scriptsDir + "update-system.sh",
            color: "#b8bb26"
        },
        {
            label: "Mirrors",
            glyph: "📡",
            script: scriptsDir + "update-mirrors.sh",
            color: "#83a598"
        },
        {
            label: "Limpiar",
            glyph: "🧹",
            script: scriptsDir + "clean-system.sh",
            color: "#fabd2f"
        }
    ]

    Row {
        anchors.centerIn: parent
        spacing: 10

        Repeater {
            model: panel.actions
            delegate: Item {
                required property var modelData
                width: 60
                height: 70

                Column {
                    anchors.centerIn: parent
                    spacing: 6

                    Rectangle {
                        width: 48
                        height: 48
                        radius: 24
                        color: btnHover.containsMouse ? Qt.rgba(
                            parseInt(modelData.color.slice(1,3), 16) / 255,
                            parseInt(modelData.color.slice(3,5), 16) / 255,
                            parseInt(modelData.color.slice(5,7), 16) / 255,
                            Theme.opacityFaint
                        ) : Theme.backgroundAlt
                        border.color: btnHover.containsMouse ? modelData.color : Theme.border
                        border.width: btnHover.containsMouse ? 2 : 1
                        anchors.horizontalCenter: parent.horizontalCenter

                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontFamily
                            font.pixelSize: 22
                            color: btnHover.containsMouse ? modelData.color : Theme.textMuted
                            text: modelData.glyph
                        }

                        Process {
                            id: actionProcess
                            command: ["kitty", "-e", "bash", modelData.script]
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
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize9
                        color: btnHover.containsMouse ? modelData.color : Theme.textMuted
                        text: modelData.label
                    }
                }
            }
        }
    }
}
