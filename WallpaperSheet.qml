import QtQuick

Item {
    id: sheet
    readonly property int sheetWidth: 260
    readonly property int lipHeight: 0
    readonly property int bodyHeight: wallpaperPanel.implicitHeight
    readonly property int bottomRadius: 16
    readonly property int flare: 15
    property alias panel: wallpaperPanel
    width: sheetWidth
    height: bodyHeight

    SheetCanvas { sheetWidth: sheet.sheetWidth; bodyHeight: sheet.bodyHeight; bottomRadius: sheet.bottomRadius; flare: sheet.flare }

    WallpaperPanel {
        id: wallpaperPanel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
    }
}
