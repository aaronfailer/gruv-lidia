import QtQuick

Item {
    id: sheet
    readonly property int sheetWidth: 260
    readonly property int lipHeight: 0
    readonly property int bodyHeight: 350
    readonly property int bottomRadius: 16
    readonly property int flare: 15
    width: sheetWidth
    height: bodyHeight

    SheetCanvas { sheetWidth: sheet.sheetWidth; bodyHeight: sheet.bodyHeight; bottomRadius: sheet.bottomRadius; flare: sheet.flare }

    BluetoothPanel {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
    }
}
