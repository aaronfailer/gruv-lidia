import QtQuick
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root
    property bool colorEditorOpen: false
    width: 30
    height: 30

    Process {
        id: colorStateReader
        command: ["bash", "-c", "cat " + Quickshell.env("HOME") + "/.config/quickshell/color_editor_state.json 2>/dev/null || echo '{}'"]
        running: false
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    var state = JSON.parse(data.trim())
                    Theme.loadOverrides(state.dark || {}, state.light || {})
                } catch(e) {}
            }
        }
    }

    Component.onCompleted: colorStateReader.running = true

    Text {
        anchors.centerIn: parent
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize14
        color: root.colorEditorOpen ? Theme.iconWidgetOpen : Theme.iconWidget
        text: "\uF1FC"
    }

    property var onToggle: null

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.onToggle) root.onToggle()
            else root.colorEditorOpen = !root.colorEditorOpen
        }
    }
}
