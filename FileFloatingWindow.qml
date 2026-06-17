import Quickshell
import QtQuick
import "."

FloatingWindow {
    id: root

    property alias filePanelObj: filePanel

    signal requestClose()

    visible: false

    onVisibleChanged: { if (visible) filePanel.refreshRecent() }

    implicitWidth: 480
    implicitHeight: 480
    color: "transparent"

    Rectangle {
        anchors.fill: parent
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
                    onPressed: {
                        root.startSystemMove()
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

}
