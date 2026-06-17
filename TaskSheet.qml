import QtQuick

Item {
    id: sheet
    readonly property int sheetWidth: 220
    readonly property int lipHeight: 0
    readonly property int bodyHeight: panel.implicitHeight
    readonly property int bottomRadius: 16
    readonly property int flare: 15
    property real deploy: 1
    signal requestClose()
    width: sheetWidth
    height: bodyHeight

    SheetCanvas { sheetWidth: sheet.sheetWidth; bodyHeight: sheet.bodyHeight; bottomRadius: sheet.bottomRadius; flare: sheet.flare }

    TaskPanel {
        id: panel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        onItemClicked: sheet.requestClose()
    }
}
