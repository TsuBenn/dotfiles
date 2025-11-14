pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {

    id: root

    signal nextDay()

    property string hour24          : Qt.formatDateTime(clock.date, "hh")
    property string hour12          : Qt.formatDateTime(clock.date, "hh ap").split(" ")[0]
    property string minute          : Qt.formatDateTime(clock.date, "mm")
    property string second          : Qt.formatDateTime(clock.date, "ss")
    property string ampm            : Qt.formatDateTime(clock.date, "AP")

    property string dayofweek_short : Qt.formatDateTime(clock.date, "ddd")
    property string dayofweek_long  : Qt.formatDateTime(clock.date, "dddd")
    property string date            : Qt.formatDateTime(clock.date, "dd")
    property string month_numeral   : Qt.formatDateTime(clock.date, "MM")
    property string month_short     : Qt.formatDateTime(clock.date, "MMM")
    property string month_long      : Qt.formatDateTime(clock.date, "MMMM")
    property string year            : Qt.formatDateTime(clock.date, "yyyy")

    onDateChanged: nextDay()

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

}

