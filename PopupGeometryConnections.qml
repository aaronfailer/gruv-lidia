import QtQuick

Item {
    id: root

    property Item popup: null
    property alias enabled: heightConn.enabled

    signal heightChanged()

    Connections {
        id: heightConn
        target: popup ? popup.sheetItem : null
        function onHeightChanged() { root.heightChanged() }
    }

    Connections {
        target: popup
        function onImplicitHeightChanged() { root.heightChanged() }
    }
}
