import qs.config
import qs.services

import QtQuick.Layouts
import QtQuick

RowLayout {
    spacing: Cell.w(0)

    Rectangle {

        implicitWidth: Cell.w(time.text.length)
        implicitHeight: Cell.h(1)

        color: Colors.bgOverlay

        Text {
            id: time
            text: `  ${DateTime.hour12}:${DateTime.minute} ${DateTime.ampm} - ${DateTime.dayofweek_short}, ${DateTime.date} ${DateTime.month_short}  `
            font: Cell.fontB
            color: Colors.fgBase
        }

    }
}
