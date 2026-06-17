import QtQuick
import "."

Rectangle {
    id: btn

    property string glyph: ""
    property string tooltip: ""

    signal clicked()

    width: 26
    height: 26
    radius: 6
    color: hover.containsMouse ? Theme.surfaceHover : "transparent"

    Text {
        anchors.centerIn: parent
        text: btn.glyph
        font.family: Theme.fontFamily
        font.pixelSize: btn.glyph === "\u2022" ? Theme.fontSize14 : Theme.fontSize16
        color: hover.containsMouse ? Theme.accent : Theme.textMuted
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
