import QtQuick
import "."

Item {
    id: root
    property bool powerOpen: false
    width: 30
    height: 30

    Text {
        anchors.centerIn: parent
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize16
        color: root.powerOpen ? Theme.accentRed : Theme.accentRedBright
        text: "⏻"
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.powerOpen = !root.powerOpen
    }
}
