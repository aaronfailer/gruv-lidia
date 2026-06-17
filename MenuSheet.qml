import QtQuick

Item {
    id: sheet
    readonly property int sheetWidth: 360
    readonly property int lipHeight: 0
    readonly property int bodyHeight: 340
    readonly property int bottomRadius: 16
    readonly property int flare: 15
    property real deploy: 1
    property alias searchActive: menuPanel.searchActive
    signal requestClose()
    signal placeRequested(string path)
    width: sheetWidth
    height: bodyHeight

    SheetCanvas { sheetWidth: sheet.sheetWidth; bodyHeight: sheet.bodyHeight; bottomRadius: sheet.bottomRadius; flare: sheet.flare }

    MenuPanel {
        id: menuPanel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        onRequestClose: sheet.requestClose()
        onPlaceRequested: sheet.placeRequested(path)
    }
}
