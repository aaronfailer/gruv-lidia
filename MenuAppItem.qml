import QtQuick
import Quickshell.Io

Item {
    id: item
    property string appName: ""
    property string iconName: ""
    property string execCmd: ""
    signal launched()

    width: parent.width
    height: 32

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: hover.containsMouse ? "#3c3836" : "transparent"
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 6
        spacing: 8

        Image {
            width: 20
            height: 20
            anchors.verticalCenter: parent.verticalCenter
            source: "image://icon/" + item.iconName
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            font.family: "FiraCode Nerd Font"
            font.pixelSize: 11
            color: hover.containsMouse ? "#ebdbb2" : "#d5c4a1"
            text: item.appName
            elide: Text.ElideRight
            width: item.width - 34
        }
    }

    Process {
        id: launcher
        command: ["bash", "-c", "nohup " + item.execCmd + " &>/dev/null &"]
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            launcher.running = true
            item.launched()
        }
    }
}
