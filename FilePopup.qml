import Quickshell
import Quickshell.Wayland
import QtQuick
import "."

PanelWindow {
    id: root

    property bool open: false
    property Item anchorItem: null
    property real panelWidth: 480
    property real panelHeight: 480
    property real panelLeft: 0
    property real panelTop: 0
    property alias filePanelObj: filePanel
    property bool dismissOnOutsideClick: true
    property bool fullscreenOverlay: dismissOnOutsideClick
    property real marginLeft: 0
    property real marginTop: 0

    signal requestClose()

    visible: false
    implicitWidth: fullscreenOverlay ? Screen.width : panelWidth
    implicitHeight: fullscreenOverlay ? Screen.height : panelHeight
    color: "transparent"
    focusable: fullscreenOverlay
    WlrLayershell.layer: fullscreenOverlay ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.namespace: "quickshell-file-popup"
    anchors.left: true
    anchors.top: true
    exclusiveZone: -1

    onVisibleChanged: { if (visible && filePanel) filePanel.refreshRecent() }

    function updateMargins() {
        if (!fullscreenOverlay) {
            root.WlrLayershell.margins = { left: marginLeft, top: marginTop, right: 0, bottom: 0 }
        }
    }

    onWidthChanged: if (fullscreenOverlay) panelLeft = (root.width - panelWidth) / 2
    onHeightChanged: if (fullscreenOverlay) panelTop = (root.height - panelHeight) / 2
    Component.onCompleted: {
        panelLeft = fullscreenOverlay ? (root.width - panelWidth) / 2 : 0
        panelTop = fullscreenOverlay ? (root.height - panelHeight) / 2 : 0
        root.updateMargins()
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.requestClose()
    }

    MouseArea {
        x: 0; y: 0
        width: panel.x; height: parent.height
        enabled: root.dismissOnOutsideClick && root.fullscreenOverlay
        onClicked: root.requestClose()
    }
    MouseArea {
        x: panel.x + panel.width; y: 0
        width: parent.width - panel.x - panel.width; height: parent.height
        enabled: root.dismissOnOutsideClick && root.fullscreenOverlay
        onClicked: root.requestClose()
    }
    MouseArea {
        x: panel.x; y: 0
        width: panel.width; height: panel.y
        enabled: root.dismissOnOutsideClick && root.fullscreenOverlay
        onClicked: root.requestClose()
    }
    MouseArea {
        x: panel.x; y: panel.y + panel.height
        width: panel.width; height: parent.height - panel.y - panel.height
        enabled: root.dismissOnOutsideClick && root.fullscreenOverlay
        onClicked: root.requestClose()
    }

    Rectangle {
        id: panel
        x: panelLeft
        y: panelTop
        width: panelWidth
        height: panelHeight
        radius: Theme.radius8
        color: Theme.backgroundAlt
        border.color: Theme.border
        border.width: 1
        clip: true

        Column {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                id: titleBar
                width: parent.width
                height: 22
                color: Theme.surface

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Theme.border
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.SizeAllCursor
                    property real sx: 0; property real sy: 0
                    property real sl: 0; property real st: 0
                    onPressed: {
                        var g = mapToGlobal(mouseX, mouseY)
                        sx = g.x; sy = g.y
                        sl = root.fullscreenOverlay ? root.panelLeft : root.marginLeft
                        st = root.fullscreenOverlay ? root.panelTop : root.marginTop
                    }
                    onPositionChanged: {
                        if (pressed) {
                            var g = mapToGlobal(mouseX, mouseY)
                            var dx = g.x - sx
                            var dy = g.y - sy
                            if (root.fullscreenOverlay) {
                                root.panelLeft = Math.max(0, sl + dx)
                                root.panelTop = Math.max(0, st + dy)
                            } else {
                                root.marginLeft = Math.max(0, sl + dx)
                                root.marginTop = Math.max(0, st + dy)
                                root.updateMargins()
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.right: parent.right; anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18; height: 18
                    radius: Theme.radius3
                    color: closeBtn.containsMouse ? Theme.accentRed : "transparent"
                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontFamily; font.pixelSize: 10
                        color: Theme.textPrimary; text: "\u00D7"
                    }
                    MouseArea {
                        id: closeBtn; anchors.fill: parent; hoverEnabled: true
                        onClicked: root.requestClose()
                    }
                }
            }

            Item {
                width: parent.width
                height: parent.height - titleBar.height

                FilePanel {
                    id: filePanel
                    anchors.fill: parent
                    anchors.margins: 6
                    onRequestClose: root.requestClose()
                }
            }
        }
    }

    // Right handle
    Rectangle {
        x: panelLeft + panelWidth; y: panelTop + 4
        width: 6; height: panelHeight - 8
        color: "transparent"
        visible: root.fullscreenOverlay
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.SizeHorCursor
            property real sx: 0; property real sw: 0
            onPressed: { sx = mouseX; sw = root.panelWidth }
            onPositionChanged: { if (pressed) root.panelWidth = Math.max(300, sw + (mouseX - sx)) }
        }
    }
    // Bottom handle
    Rectangle {
        x: panelLeft + 4; y: panelTop + panelHeight
        width: panelWidth - 8; height: 6
        color: "transparent"
        visible: root.fullscreenOverlay
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.SizeVerCursor
            property real sy: 0; property real sh: 0
            onPressed: { sy = mouseY; sh = root.panelHeight }
            onPositionChanged: { if (pressed) root.panelHeight = Math.max(300, sh + (mouseY - sy)) }
        }
    }
    // Left handle
    Rectangle {
        x: panelLeft - 6; y: panelTop + 4
        width: 6; height: panelHeight - 8
        color: "transparent"
        visible: root.fullscreenOverlay
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.SizeHorCursor
            property real sx: 0; property real sw: 0; property real sl: 0
            onPressed: { sx = mouseX; sw = root.panelWidth; sl = root.panelLeft }
            onPositionChanged: {
                if (pressed) {
                    var newW = Math.max(300, sw - (mouseX - sx))
                    root.panelLeft = sl + (sw - newW)
                    root.panelWidth = newW
                }
            }
        }
    }
    // Top handle
    Rectangle {
        x: panelLeft + 4; y: panelTop - 6
        width: panelWidth - 8; height: 6
        color: "transparent"
        visible: root.fullscreenOverlay
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.SizeVerCursor
            property real sy: 0; property real sh: 0; property real st: 0
            onPressed: { sy = mouseY; sh = root.panelHeight; st = root.panelTop }
            onPositionChanged: {
                if (pressed) {
                    var newH = Math.max(300, sh - (mouseY - sy))
                    root.panelTop = st + (sh - newH)
                    root.panelHeight = newH
                }
            }
        }
    }
    // Bottom-right corner
    Rectangle {
        x: panelLeft + panelWidth; y: panelTop + panelHeight
        width: 8; height: 8
        color: "transparent"
        visible: root.fullscreenOverlay
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.SizeFDiagCursor
            property real sx: 0; property real sy: 0; property real sw: 0; property real sh: 0
            onPressed: { sx = mouseX; sy = mouseY; sw = root.panelWidth; sh = root.panelHeight }
            onPositionChanged: {
                if (pressed) {
                    root.panelWidth = Math.max(300, sw + (mouseX - sx))
                    root.panelHeight = Math.max(300, sh + (mouseY - sy))
                }
            }
        }
    }
    // Bottom-left corner
    Rectangle {
        x: panelLeft - 8; y: panelTop + panelHeight
        width: 8; height: 8
        color: "transparent"
        visible: root.fullscreenOverlay
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.SizeBDiagCursor
            property real sx: 0; property real sy: 0; property real sw: 0; property real sh: 0; property real sl: 0
            onPressed: { sx = mouseX; sy = mouseY; sw = root.panelWidth; sh = root.panelHeight; sl = root.panelLeft }
            onPositionChanged: {
                if (pressed) {
                    var newW = Math.max(300, sw - (mouseX - sx))
                    var newH = Math.max(300, sh + (mouseY - sy))
                    root.panelLeft = sl + (sw - newW)
                    root.panelWidth = newW
                    root.panelHeight = newH
                }
            }
        }
    }
    // Top-right corner
    Rectangle {
        x: panelLeft + panelWidth; y: panelTop - 8
        width: 8; height: 8
        color: "transparent"
        visible: root.fullscreenOverlay
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.SizeBDiagCursor
            property real sx: 0; property real sy: 0; property real sw: 0; property real sh: 0; property real st: 0
            onPressed: { sx = mouseX; sy = mouseY; sw = root.panelWidth; sh = root.panelHeight; st = root.panelTop }
            onPositionChanged: {
                if (pressed) {
                    var newW = Math.max(300, sw + (mouseX - sx))
                    var newH = Math.max(300, sh - (mouseY - sy))
                    root.panelTop = st + (sh - newH)
                    root.panelWidth = newW
                    root.panelHeight = newH
                }
            }
        }
    }
    // Top-left corner
    Rectangle {
        x: panelLeft - 8; y: panelTop - 8
        width: 8; height: 8
        color: "transparent"
        visible: root.fullscreenOverlay
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.SizeFDiagCursor
            property real sx: 0; property real sy: 0; property real sw: 0; property real sh: 0; property real sl: 0; property real st: 0
            onPressed: { sx = mouseX; sy = mouseY; sw = root.panelWidth; sh = root.panelHeight; sl = root.panelLeft; st = root.panelTop }
            onPositionChanged: {
                if (pressed) {
                    var newW = Math.max(300, sw - (mouseX - sx))
                    var newH = Math.max(300, sh - (mouseY - sy))
                    root.panelLeft = sl + (sw - newW)
                    root.panelTop = st + (sh - newH)
                    root.panelWidth = newW
                    root.panelHeight = newH
                }
            }
        }
    }

    NumberAnimation {
        id: openAnim
        target: panel
        property: "scale"
        from: 0.85
        to: 1.0
        duration: 200
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: closeAnim
        target: panel
        property: "scale"
        from: 1.0
        to: 0.85
        duration: 150
        easing.type: Easing.InCubic
        onFinished: root.visible = false
    }

    Timer {
        id: focusTimer
        interval: 150
        onTriggered: root.requestActivate()
    }

    onOpenChanged: {
        if (open) {
            closeAnim.stop()
            if (fullscreenOverlay) {
                panelLeft = (root.width - panelWidth) / 2
                panelTop = (root.height - panelHeight) / 2
            } else {
                panelLeft = 0
                panelTop = 0
                root.updateMargins()
            }
            root.visible = true
            panel.scale = 0.85
            openAnim.start()
            focusTimer.restart()
        } else {
            openAnim.stop()
            closeAnim.start()
        }
    }

    onVisibleChanged: {
        if (visible && open) {
            panel.scale = 0.85
            openAnim.start()
            focusTimer.restart()
        }
    }
}
