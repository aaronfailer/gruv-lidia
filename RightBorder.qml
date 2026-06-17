import Quickshell
import QtQuick
import "."

PanelWindow {
    id: rightBorder
    anchors {
        top: true
        right: true
    }
    implicitWidth: 10
    property int barHeight: 0
    property int borderTopInset: 0
    property int borderBottomInset: 0
    anchors.bottom: barHeight === 0
    color: "transparent"

    Binding on implicitHeight {
        when: barHeight > 0
        value: barHeight
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.background
    }

    Rectangle {
        anchors.top: parent.top
        anchors.topMargin: borderTopInset
        anchors.bottom: parent.bottom
        anchors.bottomMargin: borderBottomInset
        anchors.left: parent.left
        width: 2
        color: Theme.border
    }
}
