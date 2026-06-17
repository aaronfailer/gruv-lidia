import QtQuick
import Quickshell
import Quickshell.Hyprland
import "."

Item {
    id: item
    property string clientAddress: ""
    property string clientClass: ""
    property string clientIcon: ""
    property bool isMinimized: false

    signal taskChanged()

    width: 26
    height: 26

    readonly property bool isFocused: {
        const fc = Hyprland.activeToplevel
        return fc ? fc.address === clientAddress : false
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius6
        color: hoverHandler.hovered ? Theme.surfaceHover : "transparent"
        border.color: isFocused ? Theme.iconWidget : "transparent"
        border.width: isFocused ? 1 : 0
    }

    Image {
        anchors.centerIn: parent
        width: 18
        height: 18
        source: clientIcon ? "image://icon/" + clientIcon : "image://icon/" + clientClass
        fillMode: Image.PreserveAspectFit
        smooth: true
        opacity: isMinimized ? Theme.opacityDisabled : (isFocused ? 1.0 : Theme.opacityDim)
    }

    HoverHandler {
        id: hoverHandler
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (isMinimized) {
                const ws = Hyprland.focusedWorkspace.id
                Hyprland.dispatch("movetoworkspacesilent " + ws + ",address:0x" + clientAddress)
            } else {
                Hyprland.dispatch("movetoworkspacesilent 99,address:0x" + clientAddress)
            }
            taskChanged()
        }
    }
}
