import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "."

Item {
    id: sheet

    readonly property int sheetWidth: 350
    readonly property int bodyHeight: 430
    readonly property int topRadius: 16


    width: sheetWidth
    height: bodyHeight

    property string locationName: ""
    property string currentTemp: "--"
    property string tempMin: "--"
    property string tempMax: "--"
    property int currentCode: 0
    property int humidityVal: 0
    property int rainProb: 0
    property string windStr: "--"
    property var hourlyTimes: []
    property var hourlyTemps: []
    property var hourlyCodes: []
    property var hourlyPrecip: []
    property var dailyTimes: []
    property var dailyMax: []
    property var dailyMin: []
    property var dailyCodes: []
    property var dailyPrecip: []
    property real latVal: -38.95
    property real lonVal: -67.92
    property bool loading: true
    property string dateStr: ""
    property bool searchOpen: true
    property var searchResults: []

    function iconForCode(code) {
        if (code === 0) return "\uF185"
        if (code <= 2) return "\uEEF0"
        if (code === 3) return "\uF0C2"
        if (code === 45 || code === 48) return "\uE313"
        if (code >= 51 && code <= 57) return "\uEF1C"
        if (code >= 61 && code <= 67) return "\uEF1D"
        if (code >= 71 && code <= 77) return "\uF2DC"
        if (code >= 80 && code <= 82) return "\uEF1C"
        if (code >= 95) return "\uF0E7"
        return "\uF185"
    }

    function colorForCode(code) {
        if (code === 0) return Theme.accentYellow
        if (code <= 2) return "#d65d0e"
        if (code === 3) return Theme.textSecondary
        if (code === 45 || code === 48) return Theme.textMuted
        if (code >= 51 && code <= 57) return Theme.accentBlueBright
        if (code >= 61 && code <= 67) return Theme.accentBlue
        if (code >= 71 && code <= 77) return Theme.textPrimary
        if (code >= 80 && code <= 82) return Theme.accentBlue
        if (code >= 95) return "#b16286"
        return Theme.accentYellow
    }

    function parseLocalDate(timeStr) {
        if (!timeStr) return new Date()
        var p = timeStr.split("T")[0].split("-")
        if (p.length < 3) return new Date()
        return new Date(parseInt(p[0]), parseInt(p[1]) - 1, parseInt(p[2]))
    }

    function dayName(timeStr) {
        if (!timeStr) return ""
        var d = parseLocalDate(timeStr)
        var days = ["Dom", "Lun", "Mar", "Mi\u00E9", "Jue", "Vie", "S\u00E1b"]
        return days[d.getDay()]
    }

    function fullDayName(timeStr) {
        if (!timeStr) return ""
        var d = parseLocalDate(timeStr)
        var days = ["Domingo", "Lunes", "Martes", "Mi\u00E9rcoles", "Jueves", "Viernes", "S\u00E1bado"]
        var months = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]
        return days[d.getDay()] + " " + d.getDate() + ", " + months[d.getMonth()]
    }

    function formatHour(timeStr) {
        if (!timeStr) return ""
        var parts = timeStr.split("T")
        if (parts.length < 2) return ""
        var h = parseInt(parts[1].split(":")[0])
        return h.toString()
    }

    function fetchWeather() {
        var escaped = locationName.replace(/"/g, '\\"')
        fetchProcess.command = ["bash", "-c",
            "$HOME/.config/quickshell/scripts/fetch-weather.sh \"" +
            latVal + "\" \"" + lonVal + "\" \"" + escaped + "\""]
        fetchProcess.running = false
        fetchProcess.running = true
        refreshTimer.restart()
    }

    function forceSearchFocus() {
        searchInput.forceActiveFocus()
    }

    function doSearch() {
        var q = searchInput.text.trim()
        if (q.length < 2) { searchResults = []; return }
        searchProcess.command = ["bash", "-c",
            "$HOME/.config/quickshell/scripts/search-location.sh \"" + q.replace(/"/g, '\\"') + "\""]
        searchProcess.running = false
        searchProcess.running = true
    }

    function openWeatherPage() {
        var query = encodeURIComponent(locationName)
        browserProcess.command = ["bash", "-c",
            "xdg-open 'https://www.google.com/search?q=clima+" + query + "' 2>/dev/null"]
        browserProcess.running = true
    }

    function selectLocation(lat, lon, name) {
        latVal = lat
        lonVal = lon
        locationName = name
        var escaped = name.replace(/"/g, '\\"')
        saveProcess.command = ["bash", "-c",
            "printf '{\"lat\": %s, \"lon\": %s, \"name\": \"%s\"}\\n' " +
            lat + " " + lon + " \"" + escaped + "\" > " +
            "$HOME/.config/quickshell/weather_location.json"]
        saveProcess.running = true
        searchResults = []
        searchInput.text = ""
        fetchWeather()
    }

    Process {
        id: fetchProcess
        command: ["bash", "-c", "$HOME/.config/quickshell/scripts/fetch-weather.sh"]
        stdout: SplitParser {
            onRead: function(data) {
                var line = data.trim()
                if (!line) return
                try { var json = JSON.parse(line) } catch(e) { return }
                if (!json || !json.current) return

                sheet.loading = false
                sheet.currentTemp = Math.round(json.current.temperature_2m).toString()
                sheet.humidityVal = json.current.relative_humidity_2m || 0
                sheet.rainProb = json.current.precipitation_probability || 0
                sheet.windStr = Math.round(json.current.wind_speed_10m).toString()
                sheet.currentCode = json.current.weather_code || 0

                if (json.location)
                    sheet.locationName = json.location
                if (json.lat) sheet.latVal = json.lat
                if (json.lon) sheet.lonVal = json.lon

                if (json.daily && json.daily.time) {
                    sheet.dailyTimes = json.daily.time
                    sheet.dailyMax = json.daily.temperature_2m_max || []
                    sheet.dailyMin = json.daily.temperature_2m_min || []
                    sheet.dailyCodes = json.daily.weather_code || []
                    sheet.dailyPrecip = json.daily.precipitation_probability_max || []
                    if (json.daily.temperature_2m_max && json.daily.temperature_2m_max.length > 0) {
                        sheet.tempMax = Math.round(json.daily.temperature_2m_max[0]).toString()
                        sheet.tempMin = Math.round(json.daily.temperature_2m_min[0]).toString()
                    }
                }

                if (json.hourly && json.hourly.time) {
                    var n = new Date()
                    var currentHour = n.getHours()
                    var todayStr = n.getFullYear() + "-" + ("0" + (n.getMonth() + 1)).slice(-2) + "-" + ("0" + n.getDate()).slice(-2)
                    var startIdx = -1
                    for (var i = 0; i < json.hourly.time.length; i++) {
                        var ht = json.hourly.time[i]
                        if (ht >= todayStr + "T" + (currentHour < 10 ? "0" : "") + currentHour + ":00") {
                            startIdx = i; break
                        }
                    }
                    if (startIdx < 0) startIdx = 0
                    sheet.hourlyTimes = json.hourly.time.slice(startIdx)
                    sheet.hourlyTemps = json.hourly.temperature_2m.slice(startIdx)
                    sheet.hourlyCodes = json.hourly.weather_code.slice(startIdx)
                    sheet.hourlyPrecip = json.hourly.precipitation_probability.slice(startIdx)
                }

                var ld = new Date()
                var ds = ld.getFullYear() + "-" + ("0" + (ld.getMonth() + 1)).slice(-2) + "-" + ("0" + ld.getDate()).slice(-2)
                if (json.daily && json.daily.time && json.daily.time.length > 0)
                    ds = json.daily.time[0]
                sheet.dateStr = fullDayName(ds)
            }
        }
        running: false
    }

    Process {
        id: saveProcess
    }

    Process {
        id: browserProcess
    }

    Process {
        id: searchProcess
        stdout: SplitParser {
            onRead: function(data) {
                var line = data.trim()
                if (!line) return
                try { var json = JSON.parse(line) } catch(e) { return }
                if (!(json instanceof Array)) return
                searchResults = json
            }
        }
    }

    Timer {
        id: searchDebounce
        interval: 400
        onTriggered: sheet.doSearch()
    }

    Timer {
        id: refreshTimer
        interval: 1800000
        running: true
        repeat: true
        onTriggered: sheet.fetchWeather()
    }

    Component.onCompleted: fetchWeather()

    Canvas {
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: parent.height
        y: 0

        property int _tick: Theme.isDark ? 1 : 0
        on_TickChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            var w = sheet.sheetWidth
            var h = sheet.bodyHeight
            var r = sheet.topRadius

            ctx.beginPath()
            ctx.moveTo(0, r)
            ctx.arc(r, r, r, Math.PI, -Math.PI * 0.5, false)
            ctx.lineTo(w - r, 0)
            ctx.arc(w - r, r, r, -Math.PI * 0.5, 0, false)
            ctx.lineTo(w, h)
            ctx.lineTo(0, h)
            ctx.closePath()
            ctx.fillStyle = Theme.background
            ctx.fill()
        }
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        spacing: 4

        Text {
            width: parent.width
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize11
            font.weight: Theme.fontWeightMedium
            color: Theme.textSecondary
            horizontalAlignment: Text.AlignHCenter
            text: loading ? "" : dateStr
            visible: !loading
        }

        Item {
            width: parent.width
            height: 48
            visible: !loading

            Text {
                anchors.centerIn: parent
                font.family: Theme.fontFamily
                font.pixelSize: 36
                color: colorForCode(currentCode)
                text: iconForCode(currentCode)
            }
        }

        Text {
            width: parent.width
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize14
            font.weight: Theme.fontWeightDemiBold
            color: Theme.textPrimary
            horizontalAlignment: Text.AlignHCenter
            text: loading ? "Cargando..." : tempMax + "\u00B0 / " + tempMin + "\u00B0"
        }

        Item {
            width: parent.width
            height: 16

            Text {
                anchors.centerIn: parent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize10
                color: Theme.accentBlueBright
                text: locationName + "  \uF35D"
                elide: Text.ElideRight
                maximumLineCount: 1

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: sheet.openWeatherPage()
                }
            }
        }

        Item {
            width: parent.width
            height: 28

            Row {
                anchors.centerIn: parent
                spacing: 16

                Text {
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize11
                    color: Theme.textPrimary
                    text: "\uF043  " + humidityVal + "%"
                }

                Text {
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize11
                    color: Theme.textPrimary
                    text: "\uEF1D  " + rainProb + "%"
                }

                Text {
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize11
                    color: Theme.textPrimary
                    text: "\uEF16  " + windStr + " km/h"
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.border
            visible: searchOpen || (searchResults.length > 0)
        }

        Item {
            width: parent.width
            height: 40 + (searchResults.length > 0 ? Math.min(searchResults.length * 28, 140) + 4 : 0)
            clip: false

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: 55
                anchors.right: parent.right
                anchors.rightMargin: 55
                height: 40
                radius: 6
                border.color: Theme.border
                border.width: 1
                color: Theme.surface

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize11
                    color: Theme.textMuted
                    text: "\uF002"
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 26
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize11
                    color: Theme.textSecondary
                    visible: searchInput.text.length === 0
                    text: "Buscar ubicaci\u00F3n..."
                }

                TextInput {
                    id: searchInput
                    anchors.left: parent.left
                    anchors.leftMargin: 26
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize11
                    color: Theme.textPrimary
                    onTextChanged: {
                        searchDebounce.restart()
                        if (text.length === 0) searchResults = []
                    }
                }
            }

            ListView {
                anchors.top: parent.top
                anchors.topMargin: 42
                anchors.left: parent.left
                anchors.leftMargin: 55
                anchors.right: parent.right
                anchors.rightMargin: 55
                height: searchResults.length > 0 ? Math.min(searchResults.length * 28, 140) : 0
                model: searchResults.length
                interactive: true
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                visible: searchResults.length > 0

                delegate: Rectangle {
                    required property int index
                    width: parent.width
                    height: 28
                    color: ma.containsMouse ? Theme.surfaceHighlight : "transparent"
                    radius: 4

                    property var item: index < searchResults.length ? searchResults[index] : null

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize10
                        color: Theme.textPrimary
                        text: item ? (item.name || "") + ", " + (item.country || "") : ""
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (item) sheet.selectLocation(item.lat, item.lon, item.name || "Unknown")
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.border
            visible: !loading && hourlyTimes.length > 0
        }

        Item {
            width: parent.width
            height: 72
            visible: !loading && hourlyTimes.length > 0
            clip: true

            Text {
                anchors.top: parent.top
                anchors.left: parent.left
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize8
                color: Theme.textMuted
                text: "PR\u00D3XIMAS HORAS"
            }

            ListView {
                anchors.top: parent.top
                anchors.topMargin: 12
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                orientation: ListView.Horizontal
                model: hourlyTimes.length
                interactive: true
                boundsBehavior: Flickable.StopAtBounds
                spacing: 6
                clip: true

                ScrollBar.horizontal: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    active: true
                }

                delegate: Rectangle {
                    required property int index
                    width: 44
                    height: 58
                    radius: 4
                    color: "transparent"
                    border.color: Theme.border
                    border.width: 1

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize9
                            color: Theme.textMuted
                            text: index < hourlyTimes.length ? formatHour(hourlyTimes[index]) : ""
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize14
                            color: index < hourlyCodes.length ? colorForCode(hourlyCodes[index]) : Theme.accentYellow
                            text: index < hourlyCodes.length ? iconForCode(hourlyCodes[index]) : ""
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize10
                            font.weight: Theme.fontWeightMedium
                            color: Theme.textPrimary
                            text: index < hourlyTemps.length ? Math.round(hourlyTemps[index]) + "\u00B0" : ""
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.border
            visible: !loading && dailyTimes.length > 0
        }

        Item {
            width: parent.width
            height: 64
            visible: !loading && dailyTimes.length > 0
            clip: true

            Text {
                anchors.top: parent.top
                anchors.left: parent.left
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize8
                color: Theme.textMuted
                text: "PR\u00D3XIMOS D\u00CDAS"
            }

            ListView {
                anchors.top: parent.top
                anchors.topMargin: 12
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                orientation: ListView.Horizontal
                model: dailyTimes.length
                interactive: true
                boundsBehavior: Flickable.StopAtBounds
                spacing: 6
                clip: true

                ScrollBar.horizontal: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    active: true
                }

                delegate: Rectangle {
                    required property int index
                    width: 48
                    height: 52
                    radius: 4
                    color: "transparent"
                    border.color: Theme.border
                    border.width: 1

                    Column {
                        anchors.centerIn: parent
                        spacing: 1

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize9
                            font.weight: Theme.fontWeightMedium
                            color: Theme.textMuted
                            text: index < dailyTimes.length ? dayName(dailyTimes[index]) : ""
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize13
                            color: index < dailyCodes.length ? colorForCode(dailyCodes[index]) : Theme.accentYellow
                            text: index < dailyCodes.length ? iconForCode(dailyCodes[index]) : ""
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize9
                            color: Theme.textSecondary
                            text: index < dailyMax.length && index < dailyMin.length
                                ? Math.round(dailyMax[index]) + "\u00B0 / " + Math.round(dailyMin[index]) + "\u00B0"
                                : ""
                        }
                    }
                }
            }
        }
    }

    Item {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        anchors.right: parent.right
        anchors.rightMargin: 10
        width: 18
        height: 18

        Text {
            anchors.centerIn: parent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize10
            color: Theme.textMuted
            text: "\uF021"

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: sheet.fetchWeather()
            }
        }
    }
}
