import QtQuick

Item {
    id: sheet
    readonly property int sheetWidth: 340
    readonly property int lipHeight: 0
    readonly property int bodyHeight: editorPanel.implicitHeight
    readonly property int bottomRadius: 16
    readonly property int flare: 15
    property real deploy: 1
    width: sheetWidth
    height: bodyHeight

    SheetCanvas { sheetWidth: sheet.sheetWidth; bodyHeight: sheet.bodyHeight; bottomRadius: sheet.bottomRadius; flare: sheet.flare }

    ColorEditorPanel {
        id: editorPanel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
    }
}
