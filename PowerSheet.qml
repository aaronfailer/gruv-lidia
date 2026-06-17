import QtQuick

Item {
    id: sheet
    readonly property int sheetWidth: 220
    readonly property int lipHeight: 0
    readonly property int bodyHeight: 90
    readonly property int bottomRadius: 16
    readonly property int flare: 15
    property real deploy: 1
    width: sheetWidth
    height: bodyHeight

    SheetCanvas { sheetWidth: sheet.sheetWidth; bodyHeight: sheet.bodyHeight; bottomRadius: sheet.bottomRadius; flare: sheet.flare }

    PowerPanel {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
    }
}
