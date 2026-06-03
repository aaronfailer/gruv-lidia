import QtQuick
import Quickshell.Io

Item {
    id: btn
    property string label: ""
    property string path: ""
    property string glyph: ""
    signal clicked()

    width: parent.width
    height: 24

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: hover.containsMouse ? "#3c3836" : "transparent"
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 4
        spacing: 6

        Text {
            font.family: "FiraCode Nerd Font"
            font.pixelSize: 12
            color: hover.containsMouse ? "#b8bb26" : "#928374"
            text: btn.glyph
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            font.family: "FiraCode Nerd Font"
            font.pixelSize: 11
            color: hover.containsMouse ? "#ebdbb2" : "#a89984"
            text: btn.label
            verticalAlignment: Text.AlignVCenter
        }
    }

    Process {
        id: opener
        command: ["bash", "-c", "nohup dolphin '" + btn.path + "' &>/dev/null &"]
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            opener.running = true
            btn.clicked()
        }
    }
}
