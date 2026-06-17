import QtQuick
import "."

Item {
    id: sheet
    readonly property int sheetWidth: 300
    readonly property int bodyHeight: notifPanel.implicitHeight
    property real deploy: 1
    signal requestClose()
    width: sheetWidth
    height: bodyHeight

    NotificationPanel {
        id: notifPanel
        anchors.fill: parent
        onRequestClose: sheet.requestClose()
    }
}
