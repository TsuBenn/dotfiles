import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

RowLayout {
    spacing: Cell.w(0)

    Cells {

        w: time.text.length
        h: 1

        color: Colors.bgOverlay

        CellText {
            id: time
            text: `[ ${DateTime.hour12}:${DateTime.minute} ${DateTime.ampm} - ${DateTime.dayofweek_short}, ${DateTime.date} ${DateTime.month_short} ]`
            font: Cell.fontB
            color: Colors.fgBase
        }

        MouseControl {

            anchors.fill: parent

            onPressed: (button) => {
                if (button == "L") {
                    PopupManager.toggle("calendar")
                }
            }

        }

    }
}
