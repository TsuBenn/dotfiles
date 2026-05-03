import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

RowLayout {

    id: root

    spacing: Cell.w(0)

    Cells {

        w: Cell.wCount(time.implicitWidth)
        h: 1

        color: Colors.bgOverlay

        RowLayout {

            id: time

            spacing: 0

            property var futureDeadlines: {
                return CalendarInfo.forseeDeadlines(DateTime.date, DateTime.month_numeral, DateTime.year, 10)
            }

            CellText {
                text: `[`
                font: Cell.fontB
                color: {
                    if (blinking.on && time.futureDeadlines.length > 0) {
                        return Colors.warning
                    }
                    return Colors.fgBase
                }
            }

            CellText {
                text: ` ${DateTime.hour12}:${DateTime.minute} ${DateTime.ampm}`
                font: Cell.fontB
                color: Colors.fgBase
            }

            CellText {

                Timer {

                    id: blinking

                    property bool on: false

                    running: root.visible

                    interval: 500
                    repeat: true

                    onTriggered: {
                        on = !on
                    }

                }

                property var reminders: CalendarInfo.getReminders(DateTime.date, DateTime.month_numeral, DateTime.year)
                property var events: CalendarInfo.getEvents(DateTime.date, DateTime.month_numeral, DateTime.year)

                property bool hasReminders: {
                    return reminders.length > 0 || events.length > 0
                }

                property bool hasEvents: {
                    return events.length > 0
                }

                property bool hasDeadline: {

                    for (const reminder of reminders) {
                        if (reminder.urgency == 2) {
                            return true
                        }
                    }
                    for (const reminder of events) {
                        if (reminder.urgency == 2) {
                            return true
                        }
                    }
                    return false
                }

                property bool hasImportant: {

                    for (const reminder of reminders) {
                        if (reminder.urgency == 1) {
                            return true
                        }
                    }
                    for (const reminder of events) {
                        if (reminder.urgency == 1) {
                            return true
                        }
                    }
                    return false
                }

                text: {

                    if (hasReminders && blinking.on) {
                        return " ▪ "
                    } else if (hasReminders && !blinking.on) {
                        return "   "
                    }

                    return " - " 
                }

                color: {
                    if (hasDeadline) {
                        return Colors.danger
                    } else if (hasImportant) {
                        return Colors.warning
                    } else if (hasEvents) {
                        return Colors.success
                    }
                    return Colors.fgBase
                }

            }

            CellText {
                text: `${DateTime.dayofweek_short}, ${DateTime.date} ${DateTime.month_short} `
                font: Cell.fontB
                color: Colors.fgBase
            }

            CellText {
                text: `]`
                font: Cell.fontB
                color: {
                    if (blinking.on && time.futureDeadlines.length > 0) {
                        return Colors.warning
                    }
                    return Colors.fgBase
                }
            }

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
