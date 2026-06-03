import QtQuick

Item {
    id: root
    property bool powerOpen: false
    width: 30
    height: 30

    Text {
        anchors.centerIn: parent
        font.family: "FiraCode Nerd Font"
        font.pixelSize: 16
        color: root.powerOpen ? "#cc241d" : "#fb4934"
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
