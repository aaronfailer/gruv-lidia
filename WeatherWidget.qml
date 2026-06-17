import QtQuick
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root
    property string weatherIcon: "\uF185"
    property int weatherCode: 0
    property string temperature: "--"
    implicitWidth: 40
    implicitHeight: 20

    Process {
        id: widgetFetcher
        command: ["bash", "-c", "$HOME/.config/quickshell/scripts/fetch-weather.sh"]
        stdout: SplitParser {
            onRead: function(data) {
                var line = data.trim()
                if (!line) return
                try {
                    var json = JSON.parse(line)
                    if (json.current) {
                        root.temperature = Math.round(json.current.temperature_2m).toString()
                        root.weatherCode = json.current.weather_code
                        root.weatherIcon = root.iconForCode(root.weatherCode)
                    }
                } catch(e) {}
            }
        }
        running: true
    }

    Timer {
        interval: 300000
        running: true
        repeat: true
        onTriggered: {
            widgetFetcher.running = false
            widgetFetcher.running = true
        }
    }

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

    Row {
        anchors.centerIn: parent
        spacing: 2
        Text {
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize11
            color: colorForCode(root.weatherCode)
            text: root.weatherIcon
        }
        Text {
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize10
            color: Theme.textPrimary
            text: root.temperature + "\u00B0"
        }
    }
}
