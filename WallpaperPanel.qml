import QtQuick
import Quickshell
import Quickshell.Io
import "."

Item {
    id: panel

    readonly property int panelWidth: 260

    width: panelWidth
    implicitHeight: mainColumn.implicitHeight + 28

    property var wallpapers: []

    function refreshWallpapers() {
        wallpaperReader.running = true
    }

    Process {
        id: wallpaperReader

        command: [
            "bash",
            "-c",
            "find \"$1\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) > /tmp/qs_wallpapers.txt",
            "_",
            Quickshell.env("HOME") + "/Wallpapers/Wallpaper-imagen"
        ]

        running: true

        onExited: wallpaperFile.reload()
    }

    FileView {
        id: wallpaperFile

        path: "/tmp/qs_wallpapers.txt"

        onTextChanged: {
            const text = wallpaperFile.text()

            if (!text || text.trim() === "") {
                panel.wallpapers = []
                return
            }

            const lines = text.trim().split("\n")
            const result = []

            for (let i = 0; i < lines.length; i++) {
                const path = lines[i]

                result.push({
                    path: path,
                    name: path.split("/").pop()
                })
            }

            panel.wallpapers = result
        }
    }

    Process {
        id: wallpaperSetter

        property string selectedPath: ""

        command: [
            Quickshell.env("HOME") + "/.config/quickshell/scripts/set-wallpaper.sh",
            selectedPath
        ]
    }

    Column {
        id: mainColumn

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top

        anchors.margins: 14

        spacing: 4

        Text {
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize11
            color: Theme.textMuted
            text: "Wallpapers"
        }

        Repeater {
            model: panel.wallpapers

            delegate: Rectangle {
                required property var modelData

                width: parent.width
                height: 24

                radius: 4

                color: wallpaperHover.containsMouse
                ? Theme.surfaceHover
                : "transparent"

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 6

                    color: Theme.textPrimary

                    text: modelData.name
                }

                MouseArea {
                    id: wallpaperHover

                    anchors.fill: parent

                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        wallpaperSetter.selectedPath = modelData.path
                        wallpaperSetter.running = true
                    }
                }
            }
        }
    }
}
