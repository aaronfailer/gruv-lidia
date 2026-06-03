import QtQuick

Column {
    id: grid

    property int year: new Date().getFullYear()
    property int month: new Date().getMonth()
    property int cellSize: 32
    property int columns: 7
    property int rows: 6

    readonly property var weekdayLabels: ["Lu", "Ma", "Mi", "Ju", "Vi", "Sa", "Do"]

    readonly property int firstWeekday: {
        const d = new Date(year, month, 1)
        const js = d.getDay()
        return js === 0 ? 6 : js - 1
    }

    readonly property int daysInMonth: new Date(year, month + 1, 0).getDate()

    readonly property var today: {
        const n = new Date()
        return { y: n.getFullYear(), m: n.getMonth(), d: n.getDate() }
    }

    spacing: 4
    width: columns * cellSize + (columns - 1) * 2
    height: cellSize + 4 + rows * cellSize + (rows - 1) * 2

    Row {
        spacing: 2

        Repeater {
            model: grid.weekdayLabels

            delegate: Text {
                required property var modelData
                width: grid.cellSize
                height: grid.cellSize
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: modelData
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 10
                color: "#928374"
            }
        }
    }

    Grid {
        columns: grid.columns
        rowSpacing: 2
        columnSpacing: 2
        width: parent.width

        Repeater {
            model: grid.rows * grid.columns

            delegate: Item {
                required property int index

                readonly property int dayNumber: index - grid.firstWeekday + 1
                readonly property bool inMonth: dayNumber >= 1 && dayNumber <= grid.daysInMonth
                readonly property bool isToday: inMonth
                    && grid.today.y === grid.year
                    && grid.today.m === grid.month
                    && grid.today.d === dayNumber

                width: grid.cellSize
                height: grid.cellSize

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - 4
                    height: parent.height - 4
                    radius: 6
                    visible: parent.inMonth
                    color: parent.isToday ? "#3c3836" : "transparent"
                    border.width: parent.isToday ? 1 : 0
                    border.color: "#b8bb26"
                }

                Text {
                    anchors.centerIn: parent
                    visible: parent.inMonth
                    text: parent.dayNumber
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 11
                    color: parent.isToday ? "#b8bb26" : "#ebdbb2"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
