import QtQuick

Rectangle {
    id: btn

    property string glyph: ""
    property string tooltip: ""

    signal clicked()

    width: 26
    height: 26
    radius: 6
    color: hover.containsMouse ? "#3c3836" : "transparent"

    Text {
        anchors.centerIn: parent
        text: btn.glyph
        font.family: "FiraCode Nerd Font"
        font.pixelSize: btn.glyph === "•" ? 14 : 16
        color: hover.containsMouse ? "#b8bb26" : "#928374"
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
