import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "."

Item {
    id: panel
    width: 340
    implicitHeight: Math.min(mainCol.implicitHeight + 28, 380)

    property var colorDefs: [
        { key: "background", desc: "Fondo principal" },
        { key: "backgroundAlt", desc: "Fondo alternativo" },
        { key: "surface", desc: "Superficie interactiva" },
        { key: "surfaceHover", desc: "Superficie al hover" },
        { key: "border", desc: "Borde de elementos" },
        { key: "borderFocus", desc: "Borde al enfocar" },
        { key: "textPrimary", desc: "Texto principal" },
        { key: "textSecondary", desc: "Texto secundario" },
        { key: "textMuted", desc: "Texto atenuado" },
        { key: "textDim", desc: "Texto muy tenue" },
        { key: "textInactive", desc: "Texto inactivo" },
        { key: "textTertiary", desc: "Texto terciario" },
        { key: "textDisabled", desc: "Texto deshabilitado" },
        { key: "accent", desc: "Acento verde principal" },
        { key: "accentYellow", desc: "Acento amarillo" },
        { key: "accentRed", desc: "Acento rojo" },
        { key: "accentRedBright", desc: "Acento rojo brillante" },
        { key: "accentBlue", desc: "Acento azul" },
        { key: "accentBlueBright", desc: "Acento azul brillante" },
        { key: "iconWidget", desc: "Icono de widget" },
        { key: "iconWidgetOpen", desc: "Icono de widget abierto" },
    ]

    property string selectedKey: ""
    property real pickerH: 0
    property real pickerS: 1.0
    property real pickerV: 1.0
    property bool pickerDragging: false
    property int _colorTick: 0
    property bool _hasCopied: false
    property bool _saved: false

    function hexToRgb(hex) {
        hex = hex.replace("#", "")
        if (hex.length !== 6) return null
        return {
            r: parseInt(hex.substring(0, 2), 16) / 255,
            g: parseInt(hex.substring(2, 4), 16) / 255,
            b: parseInt(hex.substring(4, 6), 16) / 255
        }
    }

    function rgbToHex(r, g, b) {
        function c(v) { var h = Math.round(Math.min(255, Math.max(0, v * 255))).toString(16); return h.length === 1 ? "0" + h : h }
        return "#" + c(r) + c(g) + c(b)
    }

    function rgbToHsv(r, g, b) {
        var mx = Math.max(r, g, b), mn = Math.min(r, g, b)
        var d = mx - mn
        var h = 0, s = mx === 0 ? 0 : d / mx
        if (d !== 0) {
            if (mx === r) h = ((g - b) / d + (g < b ? 6 : 0)) * 60
            else if (mx === g) h = ((b - r) / d + 2) * 60
            else h = ((r - g) / d + 4) * 60
        }
        return { h: h, s: s, v: mx }
    }

    function hsvToHex(h, s, v) {
        var c = v * s
        var hp = h / 60
        var x = c * (1 - Math.abs(hp % 2 - 1))
        var r1 = 0, g1 = 0, b1 = 0
        if (hp < 1) { r1 = c; g1 = x }
        else if (hp < 2) { r1 = x; g1 = c }
        else if (hp < 3) { g1 = c; b1 = x }
        else if (hp < 4) { g1 = x; b1 = c }
        else if (hp < 5) { r1 = x; b1 = c }
        else { r1 = c; b1 = x }
        var m = v - c
        return rgbToHex(r1 + m, g1 + m, b1 + m)
    }

    function isValidHex(str) {
        return /^#[0-9a-fA-F]{6}$/.test(str)
    }

    function getDefault(key) {
        for (var i = 0; i < colorDefs.length; i++) {
            if (colorDefs[i].key === key) {
                var dk = panel["_defDark_" + key]
                var lt = panel["_defLight_" + key]
                return Theme.isDark ? dk : lt
            }
        }
        return "#000000"
    }

    function getCurrent(key) {
        return key !== "" ? String(Theme[key] || "#000000") : "#000000"
    }

    function selectColor(key) {
        selectedKey = key
        _colorTick++
        var hex = getCurrent(key)
        if (!isValidHex(hex)) return
        var rgb = hexToRgb(hex)
        if (!rgb) return
        var hsv = rgbToHsv(rgb.r, rgb.g, rgb.b)
        pickerH = hsv.h
        pickerS = hsv.s
        pickerV = hsv.v
        hueBar.requestPaint()
        svSquare.requestPaint()
    }

    function applyPickerColor() {
        if (selectedKey === "") return
        var hex = hsvToHex(pickerH, pickerS, pickerV)
        Theme.setOverride(selectedKey, hex)
        _colorTick++
        svSquare.requestPaint()
        hueBar.requestPaint()
    }

    function autoApplyHex(hex) {
        if (!isValidHex(hex) || selectedKey === "") return
        var rgb = hexToRgb(hex)
        if (!rgb) return
        var hsv = rgbToHsv(rgb.r, rgb.g, rgb.b)
        pickerH = hsv.h; pickerS = hsv.s; pickerV = hsv.v
        Theme.setOverride(selectedKey, hex)
        _colorTick++
        hueBar.requestPaint()
        svSquare.requestPaint()
    }

    Process {
        id: stateReader
        command: ["bash", "-c", "cat " + Quickshell.env("HOME") + "/.config/quickshell/color_editor_state.json 2>/dev/null || echo '{}'"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    var state = JSON.parse(data.trim())
                    Theme.loadOverrides(state.dark || {}, state.light || {})
                } catch(e) {}
            }
        }
    }

    Timer {
        id: savedTimer
        interval: 1500
        onTriggered: _saved = false
    }

    Process {
        id: stateWriter
        property string payload: ""
        command: ["bash", "-c", "echo '" + payload + "' > " + Quickshell.env("HOME") + "/.config/quickshell/color_editor_state.json"]
        running: false
    }

    clip: true

    Rectangle {
        anchors.fill: parent
        color: Theme.backgroundAlt
        radius: Theme.radius4
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: 10
        clip: true
        contentHeight: mainCol.height + 20
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            width: 4
        }

        Column {
            id: mainCol
            width: parent.width - 4
            spacing: 6

            Text {
                font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: true
                color: Theme.textPrimary
                text: "Editor de colores — " + (Theme.isDark ? "Oscuro" : "Claro")
            }

            Rectangle {
                width: parent.width; height: 1; color: Theme.border
            }

            Text {
                font.family: Theme.fontFamily; font.pixelSize: 10
                color: Theme.textSecondary
                visible: selectedKey === ""
                text: "Haz clic en un color para editarlo"
            }

            Row {
                spacing: 6
                visible: selectedKey !== ""
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.fontFamily; font.pixelSize: 12
                    color: Theme.accentBlue
                    text: "\u2190"
                    MouseArea {
                        anchors.fill: parent; anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: selectedKey = ""
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.fontFamily; font.pixelSize: 10
                    color: Theme.textSecondary
                    text: "Editando: " + selectedKey + " \u2014 " + getDesc(selectedKey)
                }
            }

            Row {
                spacing: 8
                visible: selectedKey !== ""

                Rectangle {
                    id: pickerPreview
                    width: 36; height: 36
                    radius: Theme.radius4
                    border.color: Theme.border; border.width: 1
                    color: { _colorTick; return selectedKey !== "" ? getCurrent(selectedKey) : "#000000" }
                }

                Column {
                    spacing: 4
                    TextInput {
                        id: hexInput
                        width: 100; height: 20
                        font.family: Theme.fontFamily; font.pixelSize: 11
                        color: Theme.textPrimary
                        text: { _colorTick; return selectedKey !== "" ? getCurrent(selectedKey) : "" }
                        onTextEdited: {
                            if (isValidHex(text))
                                autoApplyHex(text)
                        }
                    }

                    Text {
                        font.family: Theme.fontFamily; font.pixelSize: 8
                        color: Theme.textMuted
                        text: "Escribe un hex (#RRGGBB)"
                    }
                }
            }

            TextInput { id: clipHelper; visible: false }

            Row {
                spacing: 6
                visible: selectedKey !== ""

                Rectangle {
                    width: 70; height: 22; radius: Theme.radius4
                    color: cpMa.containsMouse ? Theme.surfaceHover : "#d65d0e"
                    border.color: Theme.border; border.width: 1
                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontFamily; font.pixelSize: 9
                        color: "#000000"; text: "Copiar"
                    }
                    MouseArea {
                        id: cpMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            clipHelper.text = getCurrent(selectedKey)
                            clipHelper.selectAll()
                            clipHelper.copy()
                            _hasCopied = true
                        }
                    }
                }

                Rectangle {
                    width: 70; height: 22; radius: Theme.radius4
                    color: psMa.containsMouse ? Theme.surfaceHover : (_hasCopied ? Theme.accentBlue : "#666666")
                    border.color: Theme.border; border.width: 1
                    opacity: _hasCopied ? 1.0 : 0.6
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontFamily; font.pixelSize: 9
                        color: "#ffffff"; text: "Pegar"
                    }
                    MouseArea {
                        id: psMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            clipHelper.paste()
                            var hex = clipHelper.text.trim()
                            if (isValidHex(hex)) {
                                autoApplyHex(hex)
                                _hasCopied = false
                            }
                        }
                    }
                }

                Rectangle {
                    width: 70; height: 22; radius: Theme.radius4
                    color: gdMa.containsMouse ? Theme.surfaceHover : "#c4d93a"
                    border.color: Theme.border; border.width: 1
                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontFamily; font.pixelSize: 9
                        color: "#000000"; text: _saved ? "\u2713 Guardado" : "Guardar"
                    }
                    MouseArea {
                        id: gdMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: doSave()
                    }
                }

                Rectangle {
                    width: 70; height: 22; radius: Theme.radius4
                    color: rsMa.containsMouse ? Theme.surfaceHover : Theme.accentRed
                    border.color: Theme.border; border.width: 1
                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontFamily; font.pixelSize: 9
                        color: "#ffffff"; text: "Restablecer"
                    }
                    MouseArea {
                        id: rsMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: doReset()
                    }
                }
            }

            Item {
                width: parent.width; height: 200
                visible: selectedKey !== ""

                Canvas {
                    id: svSquare
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d")
                        var w = width; var h = height
                        var hue = pickerH
                        for (var x = 0; x < w; x++) {
                            var sat = x / w
                            var topHex = hsvToHex(hue, sat, 1)
                            var grad = ctx.createLinearGradient(0, 0, 0, h)
                            grad.addColorStop(0, topHex)
                            grad.addColorStop(1, "#000000")
                            ctx.fillStyle = grad
                            ctx.fillRect(x, 0, 1, h)
                        }

                        var sx = pickerS * w
                        var sy = (1 - pickerV) * h
                        ctx.strokeStyle = "#ffffff"
                        ctx.lineWidth = 2
                        ctx.beginPath()
                        ctx.arc(sx, sy, 5, 0, Math.PI * 2)
                        ctx.stroke()
                        ctx.strokeStyle = "#000000"
                        ctx.lineWidth = 1
                        ctx.beginPath()
                        ctx.arc(sx, sy, 5, 0, Math.PI * 2)
                        ctx.stroke()
                    }

                    MouseArea {
                        anchors.fill: parent
                        onPressed: { updateSV(mouseX, mouseY) }
                        onPositionChanged: { if (pressed) updateSV(mouseX, mouseY) }
                        function updateSV(mx, my) {
                            pickerS = Math.max(0, Math.min(1, mx / svSquare.width))
                            pickerV = Math.max(0, Math.min(1, 1 - my / svSquare.height))
                            applyPickerColor()
                        }
                    }
                }
            }

            Item {
                width: parent.width; height: 16
                visible: selectedKey !== ""

                Canvas {
                    id: hueBar
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d")
                        var w = width; var h = height
                        for (var x = 0; x < w; x++) {
                            var hue = (x / w) * 360
                            var hex = hsvToHex(hue, 1, 1)
                            ctx.fillStyle = hex
                            ctx.fillRect(x, 0, 1, h)
                        }
                        var hx = (pickerH / 360) * w
                        ctx.strokeStyle = "#ffffff"
                        ctx.lineWidth = 2
                        ctx.beginPath()
                        ctx.moveTo(hx, 0); ctx.lineTo(hx, h)
                        ctx.stroke()
                        ctx.strokeStyle = "#000000"
                        ctx.lineWidth = 1
                        ctx.beginPath()
                        ctx.moveTo(hx, 0); ctx.lineTo(hx, h)
                        ctx.stroke()
                    }

                    MouseArea {
                        anchors.fill: parent
                        onPressed: { updateHue(mouseX) }
                        onPositionChanged: { if (pressed) updateHue(mouseX) }
                        function updateHue(mx) {
                            pickerH = Math.max(0, Math.min(360, (mx / hueBar.width) * 360))
                            applyPickerColor()
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width; height: 1; color: Theme.border
            }

            Text {
                font.family: Theme.fontFamily; font.pixelSize: 10; font.bold: true
                color: Theme.textPrimary; text: "Colores"
            }

            Repeater {
                model: colorDefs

                delegate: Item {
                    required property var modelData
                    height: 28
                    width: parent.width

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radius3
                        color: (modelData.key === selectedKey) ? Theme.surfaceHover : (ma.containsMouse ? Qt.rgba(0,0,0,0.04) : "transparent")
                    }

                    Rectangle {
                        anchors.left: parent.left; anchors.leftMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14; height: 14; radius: 2
                        border.color: Theme.border; border.width: 1
                        color: Theme[modelData.key] || "#000000"
                    }

                    Text {
                        anchors.left: parent.left; anchors.leftMargin: 22
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: -4
                        font.family: Theme.fontFamily; font.pixelSize: 10
                        color: Theme.textPrimary; text: modelData.key
                    }

                    Text {
                        anchors.left: parent.left; anchors.leftMargin: 22
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: 8
                        font.family: Theme.fontFamily; font.pixelSize: 7
                        color: Theme.textMuted; text: modelData.desc
                    }

                    Rectangle {
                        anchors.right: hexField.left; anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14; height: 14; radius: 2
                        border.color: Theme.border; border.width: 1
                        color: Theme[modelData.key] || "#000000"
                    }

                    TextInput {
                        id: hexField
                        anchors.right: parent.right; anchors.rightMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 72
                        font.family: Theme.fontFamily; font.pixelSize: 10
                        color: Theme.textPrimary
                        horizontalAlignment: TextInput.AlignRight
                        text: Theme[modelData.key] || "#000000"
                        onTextEdited: {
                            if (isValidHex(text)) {
                                Theme.setOverride(modelData.key, text)
                                _colorTick++
                                if (selectedKey === modelData.key) {
                                    var rgb = hexToRgb(text)
                                    if (rgb) {
                                        var hsv = rgbToHsv(rgb.r, rgb.g, rgb.b)
                                        pickerH = hsv.h; pickerS = hsv.s; pickerV = hsv.v
                                        hueBar.requestPaint()
                                        svSquare.requestPaint()
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: ma
                        anchors.left: parent.left
                        anchors.right: hexField.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: selectColor(modelData.key)
                    }
                }
            }

        }
    }

    function getDesc(key) {
        for (var i = 0; i < colorDefs.length; i++)
            if (colorDefs[i].key === key) return colorDefs[i].desc
        return ""
    }

    function doSave() {
        var dark = {}
        var light = {}
        for (var k in Theme.darkOverrides) dark[k] = Theme.darkOverrides[k]
        for (var lk in Theme.lightOverrides) light[lk] = Theme.lightOverrides[lk]
        stateWriter.payload = JSON.stringify({ dark: dark, light: light })
        stateWriter.running = true
        _saved = true
        savedTimer.restart()
    }

    function doReset() {
        var keys = []
        for (var i = 0; i < colorDefs.length; i++) keys.push(colorDefs[i].key)
        for (var j = 0; j < keys.length; j++) Theme.removeOverride(keys[j])
        if (selectedKey !== "") selectColor(selectedKey)
    }
}
