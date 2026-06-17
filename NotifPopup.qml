import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: root

    readonly property int popupWidth: 300

    property bool open: false
    property int anchorRight: 5
    property int anchorTop: 30

    property bool _windowVisible: false
    visible: _windowVisible

    signal requestClose()

    implicitWidth: popupWidth
    implicitHeight: bg.height
    color: "transparent"
    focusable: false

    anchors { right: true; top: true }
    WlrLayershell.layer: WlrLayer.Overlay
    margins.right: anchorRight
    margins.top: anchorTop
    exclusiveZone: -1

    onOpenChanged: {
        if (open) {
            root._windowVisible = true
            // focusTimer.restart()  // DIAGNÓSTICO: desactivado para probar si requestActivate causa el bug
        }
    }

    Timer {
        id: focusTimer
        interval: 150
        onTriggered: {
            // root.requestActivate()  // DIAGNÓSTICO: desactivado para probar si requestActivate causa el bug
        }
    }

    Rectangle {
        id: bg
        anchors.left: parent.left
        anchors.top: parent.top
        width: popupWidth
        height: sheet.bodyHeight
        radius: 12
        color: Theme.background
        border.color: Theme.border
        border.width: 1

        HoverHandler {
            onHoveredChanged: {
                if (!hovered) closeTimer.start()
                else closeTimer.stop()
            }
        }

        NotificationSheet {
            id: sheet
            anchors.fill: parent
            deploy: root.open ? 1 : 0

            Behavior on deploy {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutQuad
                    onRunningChanged: {
                        if (!running && !root.open)
                            root._windowVisible = false
                    }
                }
            }
        }
    }

    Timer {
        id: closeTimer
        interval: 300
        onTriggered: root.requestClose()
    }
}
