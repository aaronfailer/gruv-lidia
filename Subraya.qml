import QtQuick

Rectangle {
    id: root

    // Elemento al que se le va a adaptar el subrayado
    property Item target

    // Ajustes opcionales
    property color lineColor: "#b8bb26"
    property int thickness: 2
    property int offset: 2
    property real opacityLevel: 0.9

    height: thickness
    radius: thickness / 2
    color: lineColor
    opacity: opacityLevel

    // Se engancha automáticamente al target
    x: target ? target.x : 0
    width: target ? target.width : 0
    y: target ? target.y + target.height + offset : 0
}
