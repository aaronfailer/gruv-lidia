import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
    id: item
    property string clientAddress: ""
    property string clientClass: ""
    property bool isMinimized: false

    width: 26
    height: 26

    readonly property bool isFocused: {
        const fc = Hyprland.activeToplevel
        return fc ? fc.address === clientAddress : false
    }

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: hoverHandler.hovered ? "#3c3836" : "transparent"
        border.color: isFocused ? "#b8bb26" : "transparent"
        border.width: isFocused ? 1 : 0
    }

    Image {
        anchors.centerIn: parent
        width: 18
        height: 18
        source: "image://icon/" + clientClass
        fillMode: Image.PreserveAspectFit
        smooth: true
        opacity: isMinimized ? 0.4 : (isFocused ? 1.0 : 0.7)
    }

    HoverHandler {
        id: hoverHandler
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (isMinimized) {
                const currentWs = Hyprland.focusedWorkspace.id
                Hyprland.dispatch("workspace 99")
                Hyprland.dispatch("movetoworkspace " + currentWs)
            } else if (isFocused) {
                Hyprland.dispatch("movetoworkspacesilent 99")
            } else {
                Hyprland.dispatch("focuswindow address:" + clientAddress)
            }
        }
    }
}
