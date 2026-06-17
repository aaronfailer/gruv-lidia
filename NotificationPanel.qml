import QtQuick
import Quickshell
import Quickshell.Io
import "."

Item {
    id: panel
    readonly property int panelWidth: 300
    width: panelWidth
    implicitHeight: mainCol.implicitHeight + 28

    property var notifications: []
    property bool dnd: false

    signal requestClose()

    function refresh() {
        notifReader.running = true
        dndReader.running = true
    }

    Process {
        id: notifReader
        command: ["bash", "-c", "cat /tmp/qs_notifications.json 2>/dev/null || echo '{\"notifications\":[],\"count\":0}'"]
        running: false
        onExited: notifFile.reload()
    }

    Process {
        id: dndReader
        command: ["swaync-client", "-D"]
        running: false
        stdout: SplitParser {
            onRead: function(data) {
                panel.dnd = data.trim() === "true"
            }
        }
    }

    Process {
        id: closeAllProcess
        command: ["swaync-client", "-C"]
    }

    Process {
        id: closeNotifProcess
        command: ["true"]
    }

    Process {
        id: toggleDnd
        command: ["swaync-client", "-d"]
    }

    FileView {
        id: notifFile
        path: "/tmp/qs_notifications.json"
        onTextChanged: {
            const text = notifFile.text()
            if (!text || text.trim() === "") {
                panel.notifications = []
                return
            }
            try {
                const data = JSON.parse(text.trim())
                panel.notifications = data.notifications || []
            } catch(e) {
                panel.notifications = []
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: panel.refresh()
    }

    Component.onCompleted: panel.refresh()

    Column {
        id: mainCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 6

        Row {
            width: parent.width
            spacing: 6

            Text {
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize11
                color: Theme.textMuted
                text: "Notificaciones"
                width: parent.width - closeAllBtn.width - dndBtn.width - 12
                verticalAlignment: Text.AlignVCenter
                height: 20
            }

            Text {
                id: dndBtn
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize11
                color: dndHover.containsMouse ? (panel.dnd ? Theme.accentGreen : Theme.accent) : (panel.dnd ? Theme.textMuted : Theme.border)
                text: panel.dnd ? "\uF2DC" : "\uF0A2"

                MouseArea {
                    id: dndHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        toggleDnd.running = true
                        panel.refresh()
                    }
                }
            }

            Text {
                id: closeAllBtn
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize11
                color: closeAllHover.containsMouse ? Theme.accentRedBright : Theme.border
                text: "\u2715"

                MouseArea {
                    id: closeAllHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        closeAllProcess.running = true
                        Qt.callLater(panel.refresh)
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.surface
        }

        Repeater {
            model: panel.notifications

            delegate: Item {
                required property var modelData
                width: parent.width
                height: notifContent.implicitHeight + 12

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radius6
                    color: itemHover.containsMouse ? Theme.surface : "transparent"
                }

                Row {
                    id: notifContent
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    anchors.right: dismissBtn.left
                    anchors.rightMargin: 4
                    spacing: 8

                    Image {
                        width: 20
                        height: 20
                        anchors.verticalCenter: parent.verticalCenter
                        source: "image://icon/" + (modelData.app_icon || modelData.app_name || "")
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 34

                        Text {
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize10
                            font.weight: Theme.fontWeightBold
                            color: itemHover.containsMouse ? Theme.textPrimary : Theme.textSecondary
                            text: modelData.app_name || ""
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize10
                            color: itemHover.containsMouse ? Theme.textPrimary : Theme.textDim
                            text: modelData.summary || ""
                            elide: Text.ElideRight
                            width: parent.width
                            visible: modelData.summary
                        }

                        Rectangle {
                            height: 1
                            width: parent.width
                            color: "transparent"
                        }

                        Text {
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize9
                            color: Theme.textDim
                            text: modelData.body || ""
                            elide: Text.ElideRight
                            wrapMode: Text.WordWrap
                            width: parent.width
                            maximumLineCount: 2
                            visible: modelData.body
                        }
                    }
                }

                Text {
                    id: dismissBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize10
                    color: dismissHover.containsMouse ? Theme.accentRedBright : Theme.border
                    text: "\u2715"

                    MouseArea {
                        id: dismissHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const id = modelData.id
                            const swayncId = modelData.swaync_id
                            const idx = panel.notifications.findIndex(n => n.id === id)
                            if (idx >= 0) {
                                const arr = panel.notifications.slice()
                                arr.splice(idx, 1)
                                panel.notifications = arr
                            }
                            if (swayncId !== undefined) {
                                closeNotifProcess.command = [
                                    "dbus-send", "--session",
                                    "--dest=org.freedesktop.Notifications",
                                    "--type=method_call",
                                    "/org/freedesktop/Notifications",
                                    "org.freedesktop.Notifications.CloseNotification",
                                    "uint32:" + swayncId
                                ]
                                closeNotifProcess.running = true
                            }
                        }
                    }
                }

                MouseArea {
                    id: itemHover
                    anchors.left: parent.left
                    anchors.right: dismissBtn.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    hoverEnabled: true
                }
            }
        }

        Text {
            visible: panel.notifications.length === 0
            width: parent.width
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize10
            color: Theme.textDim
            text: "Sin notificaciones"
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
