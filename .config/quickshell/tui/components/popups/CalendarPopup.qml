pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

CellPopup {
    id: root

    property bool optimizeMemory: SettingsInfo.optimizeMemory

    property bool minimal: SettingsInfo.minimal

    w: 80 - root.minimal * 15 + 2
    h: Cell.hCount(layout.implicitHeight) + 2

    property bool edit: false

    property var clipboard: ({})

    onVisibleChanged: {
        calendar.selected = Qt.binding(() => calendar.today);
        calendar.year = calendar.today.year;
        calendar.month = calendar.today.month;
        root.edit = false;
    }

    escapeToClose: false

    shortcuts: [
        {
            binds: "Escape",
            action: () => {
                if (root.edit) {
                    root.edit = false;
                } else {
                    root.close();
                }
            }
        },
        {
            binds: "Return",
            action: () => {
                if (!root.edit) {
                    root.edit = true;
                }
                if (title_textfield.text.length > 0) {
                    edit.apply();
                }
            }
        },
        {
            binds: "Tab",
            action: () => {
                if (title_textfield.focus) {
                    body_textfield.grabFocus();
                } else if (body_textfield.focus) {
                    title_textfield.grabFocus();
                }
                if (hour.focus) {
                    minute.grabFocus();
                } else if (minute.focus) {
                    hour.grabFocus();
                }
            }
        },
        {
            binds: "Left",
            active: !TextFieldManager.active,
            action: () => {
                if (calendar.selected.year != calendar.year) {
                    calendar.year = calendar.selected.year;
                }

                if (calendar.selected.month != calendar.month) {
                    calendar.month = calendar.selected.month;
                }

                const today = new Date(calendar.selected.year, calendar.selected.month - 1, calendar.selected.day);
                today.setDate(today.getDate() - 1);

                if (today.getFullYear() < calendar.year) {
                    calendar.year -= 1;
                    calendar.month = 12;
                } else if (today.getFullYear() > calendar.year) {
                    calendar.year += 1;
                    calendar.month = 1;
                }

                if (today.getMonth() + 1 < calendar.month) {
                    calendar.month -= 1;
                } else if (today.getMonth() + 1 > calendar.month) {
                    calendar.month += 1;
                }

                calendar.selected = {
                    day: today.getDate(),
                    month: today.getMonth() + 1,
                    year: today.getFullYear()
                };
            }
        },
        {
            binds: "Right",
            active: !TextFieldManager.active,
            action: () => {
                if (calendar.selected.year != calendar.year) {
                    calendar.year = calendar.selected.year;
                }

                if (calendar.selected.month != calendar.month) {
                    calendar.month = calendar.selected.month;
                }

                const today = new Date(calendar.selected.year, calendar.selected.month - 1, calendar.selected.day);
                today.setDate(today.getDate() + 1);

                if (today.getFullYear() < calendar.year) {
                    calendar.year -= 1;
                    calendar.month = 12;
                } else if (today.getFullYear() > calendar.year) {
                    calendar.year += 1;
                    calendar.month = 1;
                }

                if (today.getMonth() + 1 < calendar.month) {
                    calendar.month -= 1;
                } else if (today.getMonth() + 1 > calendar.month) {
                    calendar.month += 1;
                }

                calendar.selected = {
                    day: today.getDate(),
                    month: today.getMonth() + 1,
                    year: today.getFullYear()
                };
            }
        },
        {
            binds: "Up",
            action: () => {
                if (calendar.selected.year != calendar.year) {
                    calendar.year = calendar.selected.year;
                }

                if (calendar.selected.month != calendar.month) {
                    calendar.month = calendar.selected.month;
                }

                const today = new Date(calendar.selected.year, calendar.selected.month - 1, calendar.selected.day);
                today.setDate(today.getDate() - 7);

                if (today.getFullYear() < calendar.year) {
                    calendar.year -= 1;
                    calendar.month = 12;
                } else if (today.getFullYear() > calendar.year) {
                    calendar.year += 1;
                    calendar.month = 1;
                }

                if (today.getMonth() + 1 < calendar.month) {
                    calendar.month -= 1;
                } else if (today.getMonth() + 1 > calendar.month) {
                    calendar.month += 1;
                }

                calendar.selected = {
                    day: today.getDate(),
                    month: today.getMonth() + 1,
                    year: today.getFullYear()
                };
            }
        },
        {
            binds: "Down",
            action: () => {
                if (calendar.selected.year != calendar.year) {
                    calendar.year = calendar.selected.year;
                }

                if (calendar.selected.month != calendar.month) {
                    calendar.month = calendar.selected.month;
                }

                const today = new Date(calendar.selected.year, calendar.selected.month - 1, calendar.selected.day);
                today.setDate(today.getDate() + 7);

                if (today.getFullYear() < calendar.year) {
                    calendar.year -= 1;
                    calendar.month = 12;
                } else if (today.getFullYear() > calendar.year) {
                    calendar.year += 1;
                    calendar.month = 1;
                }

                if (today.getMonth() + 1 < calendar.month) {
                    calendar.month -= 1;
                } else if (today.getMonth() + 1 > calendar.month) {
                    calendar.month += 1;
                }

                calendar.selected = {
                    day: today.getDate(),
                    month: today.getMonth() + 1,
                    year: today.getFullYear()
                };
            }
        },
    ]

    CellBox {
        id: box

        w: root.w
        h: root.h

        ColumnLayout {
            id: layout

            spacing: 0

            RowLayout {
                id: row1

                spacing: 0

                Cells {
                    id: col1

                    visible: !root.minimal

                    w: 14
                    h: 12
                    color: "transparent"

                    ColumnLayout {

                        Layout.alignment: Qt.AlignTop
                        Layout.topMargin: Cell.centerHCell(implicitHeight, row1.implicitHeight)

                        spacing: 0

                        CellText {
                            text: ""
                        }

                        CellText {

                            Layout.leftMargin: Cell.centerWCell(implicitWidth, col1.implicitWidth)
                            text: ANSI.render(DateTime.hour12)
                            font: Cell.fontB
                            color: Colors.fgBase
                        }

                        CellText {

                            Layout.leftMargin: Cell.centerWCell(implicitWidth, col1.implicitWidth)
                            text: ANSI.render(DateTime.minute)
                            font: Cell.fontB
                            color: Colors.fgBase
                        }

                        CellText {
                            text: ""
                        }

                        CellSeparator {

                            w: Cell.wCount(col1.implicitWidth)
                            type: 2
                            color: Colors.accentDim
                        }

                        CellText {

                            Layout.leftMargin: Cell.centerWCell(implicitWidth, col1.implicitWidth)

                            text: `${DateTime.dayofweek_long.toUpperCase()}`
                            font: Cell.fontB
                            color: Colors.secondary
                        }
                    }
                }

                CellSeparator {

                    visible: !root.minimal

                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: Cell.centerHCell(implicitHeight, row1.implicitHeight)

                    vertical: true

                    h: Cell.hCount(row1.implicitHeight)
                    color: Colors.accentStrong
                }

                Item {
                    id: calendar

                    property int year: parseInt(DateTime.year)
                    property int month: parseInt(DateTime.month_numeral)
                    property var today: {
                        "day": parseInt(DateTime.date),
                        "month": parseInt(DateTime.month_numeral),
                        "year": parseInt(DateTime.year)
                    }

                    property var selected: today

                    onSelectedChanged: {
                        reminders.reload();
                        reminders_scroll_view.reset();
                    }
                }

                ColumnLayout {

                    Layout.alignment: Qt.AlignTop

                    spacing: Cell.h(0)

                    RowLayout {

                        spacing: 0

                        CellButton {
                            text: "<"
                            font: Cell.fontBB
                            color: ["transparent", Colors.bgOverlay, Colors.fgBase]
                            fg: [Colors.fgBase, Colors.bgSurface]
                            onPressed: button => {
                                if (button == "L") {
                                    calendar.year -= 1;
                                }
                            }
                        }

                        CellText {
                            text: calendar.year
                            preferedW: Cell.wCount(grid.implicitWidth) - 6
                            centered: true
                            font: Cell.fontB
                        }

                        CellButton {
                            text: ">"
                            font: Cell.fontBB
                            color: ["transparent", Colors.bgOverlay, Colors.fgBase]
                            fg: [Colors.fgBase, Colors.bgSurface]
                            onPressed: button => {
                                if (button == "L") {
                                    calendar.year += 1;
                                }
                            }
                        }
                    }

                    RowLayout {

                        spacing: 0

                        CellButton {
                            text: "<"
                            font: Cell.fontBB
                            color: ["transparent", Colors.bgOverlay, Colors.fgBase]
                            fg: [Colors.fgBase, Colors.bgSurface]
                            onPressed: button => {
                                if (button == "L") {
                                    if (calendar.month == 1) {
                                        calendar.month = 12;
                                        calendar.year -= 1;
                                        return;
                                    }
                                    calendar.month -= 1;
                                }
                            }
                        }

                        CellText {
                            text: {
                                switch (calendar.month) {
                                case 1:
                                    return "January";
                                case 2:
                                    return "February";
                                case 3:
                                    return "March";
                                case 4:
                                    return "April";
                                case 5:
                                    return "May";
                                case 6:
                                    return "June";
                                case 7:
                                    return "July";
                                case 8:
                                    return "August";
                                case 9:
                                    return "September";
                                case 10:
                                    return "October";
                                case 11:
                                    return "November";
                                case 12:
                                    return "December";
                                }
                            }
                            preferedW: Cell.wCount(grid.implicitWidth) - 6
                            centered: true
                            font: Cell.fontB
                        }

                        CellButton {
                            text: ">"
                            font: Cell.fontBB
                            color: ["transparent", Colors.bgOverlay, Colors.fgBase]
                            fg: [Colors.fgBase, Colors.bgSurface]
                            onPressed: button => {
                                if (button == "L") {
                                    if (calendar.month == 12) {
                                        calendar.month = 1;
                                        calendar.year += 1;
                                        return;
                                    }
                                    calendar.month += 1;
                                }
                            }
                        }
                    }

                    CellSeparator {
                        w: Cell.wCount(grid.implicitWidth)
                        type: 2
                        color: Colors.accentDim
                    }

                    RowLayout {
                        spacing: 0

                        Repeater {

                            model: ["MO", "TU", "WE", "TH", "FR", "SA", "SU",]

                            delegate: CellText {

                                required property string modelData

                                text: " " + modelData + " "
                                font: Cell.fontB
                                color: Colors.secondary
                            }
                        }
                    }

                    CellSeparator {
                        w: Cell.wCount(grid.implicitWidth)
                        type: 0
                        color: Colors.bgOverlay
                    }

                    GridLayout {
                        id: grid

                        rowSpacing: Cell.h(0)
                        columnSpacing: Cell.w(0)
                        columns: 7

                        Timer {
                            id: blinking_deadline

                            property bool on: false

                            running: root.visible
                            interval: 500

                            repeat: true

                            onTriggered: {
                                on = !on;
                            }
                        }

                        Repeater {

                            model: CalendarInfo.generateCalendar(calendar.year, calendar.month, calendar.today)

                            delegate: Loader {
                                id: days_loader

                                required property var modelData

                                active: root.visible || !root.optimizeMemory

                                sourceComponent: Cells {
                                    id: day

                                    property var modelData: days_loader.modelData

                                    property string date: modelData.day
                                    property bool isToday: modelData.isToday
                                    property bool inMonth: modelData.inMonth
                                    property bool isCurrentMonth: modelData.isCurrentMonth
                                    property bool nextMonth: modelData.nextMonth ?? false

                                    property var reminders: modelData.reminders ?? []
                                    property var events: modelData.events ?? []

                                    property bool hasSpan: false
                                    property bool beginSpan: false
                                    property bool midSpan: false
                                    property bool endSpan: false
                                    property bool hasDeadline: false
                                    property bool hasImportant: false

                                    property bool hasImportantSpan: false
                                    property bool hasDeadlineSpan: false

                                    property bool isSelected: (calendar.selected.month == calendar.month && calendar.selected.day == date && inMonth && calendar.selected.year == calendar.year)

                                    Component.onCompleted: {
                                        for (const event of events) {
                                            event.isEvent = true;
                                        }

                                        const weekday = CalendarInfo.getDay(day.date, calendar.month + (day.inMonth ? 0 : (day.nextMonth ? 1 : -1)), calendar.year);

                                        for (const reminder of day.reminders) {
                                            if (/^\d{2}\/\d{2}\/\d{4}$/.test(reminder.date)) {
                                                day.hasSpan = true;
                                                if (weekday == "MO") {
                                                    day.beginSpan = true;
                                                }
                                                if (weekday == "SU") {
                                                    day.endSpan = true;
                                                }
                                                if (weekday != "MO" && weekday != "SU") {
                                                    day.midSpan = true;
                                                }
                                                if (reminder.urgency == 2) {
                                                    day.hasDeadlineSpan = true;
                                                } else if (reminder.urgency == 1) {
                                                    day.hasImportantSpan = true;
                                                }
                                            }
                                            if (reminder.urgency == 2) {
                                                day.hasDeadline = true;
                                            }
                                            if (reminder.urgency == 1) {
                                                day.hasImportant = true;
                                            }
                                            if (reminder.span_idx == reminder.span) {
                                                day.endSpan = true;
                                            }
                                            if (reminder.span_idx > 1 && reminder.span_idx < reminder.span) {
                                                day.midSpan = true;
                                            }
                                            if (reminder.span_idx == 1) {
                                                day.beginSpan = true;
                                            }
                                            if (reminder.span > 1) {
                                                day.hasSpan = true;
                                                if (reminder.urgency == 2) {
                                                    day.hasDeadlineSpan = true;
                                                } else if (reminder.urgency == 1) {
                                                    day.hasImportantSpan = true;
                                                }
                                            }
                                        }
                                        for (const reminder of day.events) {
                                            if (/^\d{2}\/\d{2}\/\d{4}$/.test(reminder.date)) {
                                                day.hasSpan = true;
                                                if (weekday == "MO") {
                                                    day.beginSpan = true;
                                                }
                                                if (weekday == "SU") {
                                                    day.endSpan = true;
                                                }
                                                if (weekday != "MO" && weekday != "SU") {
                                                    day.midSpan = true;
                                                }
                                                if (reminder.urgency == 2) {
                                                    day.hasDeadlineSpan = true;
                                                } else if (reminder.urgency == 1) {
                                                    day.hasImportantSpan = true;
                                                }
                                            }
                                            if (reminder.urgency == 2) {
                                                day.hasDeadline = true;
                                            }
                                            if (reminder.urgency == 1) {
                                                day.hasImportant = true;
                                            }
                                            if (reminder.span_idx == reminder.span) {
                                                day.endSpan = true;
                                            }
                                            if (reminder.span_idx > 1 && reminder.span_idx < reminder.span) {
                                                day.midSpan = true;
                                            }
                                            if (reminder.span_idx == 1) {
                                                day.beginSpan = true;
                                            }
                                            if (reminder.span > 1) {
                                                day.hasSpan = true;
                                                if (reminder.urgency == 2) {
                                                    day.hasDeadlineSpan = true;
                                                } else if (reminder.urgency == 1) {
                                                    day.hasImportantSpan = true;
                                                }
                                            }
                                        }
                                    }

                                    w: 4
                                    h: 1

                                    color: {
                                        if (day.isToday) {
                                            return Colors.accentStrong;
                                        } else if (day.isSelected) {
                                            return Colors.secondary;
                                        } else {
                                            return "transparent";
                                        }
                                    }

                                    CellText {

                                        x: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                                        text: day.date
                                        color: {
                                            if (!day.inMonth) {
                                                if (day.hasDeadline && blinking_deadline.on) {
                                                    return Colors.blend(Colors.danger, Colors.fgSubtle, 0.7);
                                                } else if (day.hasDeadline && !blinking_deadline.on) {
                                                    return Colors.blend(Colors.warning, Colors.fgSubtle, 0.7);
                                                } else if (day.hasImportant) {
                                                    return Colors.blend(Colors.warning, Colors.fgSubtle, 0.9);
                                                } else if (day.events.length > 0) {
                                                    return Colors.blend(Colors.success, Colors.fgSubtle, 0.9);
                                                } else if (day.reminders.length > 0) {
                                                    return Colors.blend(Colors.info, Colors.fgSubtle, 0.9);
                                                }
                                                return Colors.fgSubtle;
                                            }
                                            if (day.isToday) {
                                                return Colors.onAccent;
                                            } else if (day.isSelected) {
                                                return Colors.bgSurface;
                                            } else if (day.hasDeadline && blinking_deadline.on) {
                                                return Colors.danger;
                                            } else if (day.hasDeadline && !blinking_deadline.on) {
                                                return Colors.warning;
                                            } else if (day.hasImportant) {
                                                return Colors.warning;
                                            } else if (day.events.length > 0) {
                                                return Colors.success;
                                            } else if (day.reminders.length > 0) {
                                                return Colors.info;
                                            } else if (day.inMonth) {
                                                return Colors.fgBase;
                                            } else {
                                                return Colors.fgSubtle;
                                            }
                                        }
                                        font: {
                                            if (day.hasDeadline) {
                                                if (!day.inMonth) {
                                                    return Cell.fontB;
                                                }
                                                return Cell.fontBB;
                                            }
                                            if (day.isToday || day.isSelected || day.reminders.length > 0 || day.events.length > 0) {
                                                return Cell.fontB;
                                            }
                                            return Cell.font;
                                        }
                                    }

                                    CellText {

                                        visible: (!day.isSelected || !day.hasDeadline) && day.hasSpan

                                        x: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                                        text: {
                                            if (!day.inMonth) {
                                                if (day.midSpan) {
                                                    return day.date < 10 ? "╴ ╶─" : "╴  ╶";
                                                } else if (day.beginSpan && !day.endSpan) {
                                                    return day.date < 10 ? "  ╶─" : "   ╶";
                                                } else if (day.endSpan && !day.beginSpan) {
                                                    return day.date < 10 ? "╴   " : "╴   ";
                                                } else if (day.endSpan && day.beginSpan) {
                                                    return day.date < 10 ? "╴ ╶─" : "╴  ╶";
                                                }
                                            }
                                            if (day.midSpan) {
                                                return day.date < 10 ? "╸ ╺━" : "╸  ╺";
                                            } else if (day.beginSpan && !day.endSpan) {
                                                return day.date < 10 ? "  ╺━" : "   ╺";
                                            } else if (day.endSpan && !day.beginSpan) {
                                                return day.date < 10 ? "╸   " : "╸   ";
                                            } else if (day.endSpan && day.beginSpan) {
                                                return day.date < 10 ? "╸ ╺━" : "╸  ╺";
                                            }
                                            return "";
                                        }
                                        color: {
                                            if (!day.inMonth) {
                                                if (day.hasDeadlineSpan) {
                                                    return Colors.blend(Colors.danger, Colors.fgSubtle, 0.9);
                                                } else if (day.hasImportantSpan) {
                                                    return Colors.blend(Colors.warning, Colors.fgSubtle, 0.9);
                                                } else if (day.hasDeadline) {
                                                    return Colors.blend(Colors.danger, Colors.fgSubtle, 0.9);
                                                } else if (day.hasImportant) {
                                                    return Colors.blend(Colors.warning, Colors.fgSubtle, 0.9);
                                                } else if (day.events.length > 0) {
                                                    return Colors.blend(Colors.success, Colors.fgSubtle, 0.9);
                                                } else if (day.reminders.length > 0) {
                                                    return Colors.blend(Colors.info, Colors.fgSubtle, 0.9);
                                                }
                                                return Colors.fgSubtle;
                                            }
                                            if (day.isToday) {
                                                return Colors.onAccent;
                                            } else if (day.isSelected) {
                                                return Colors.bgSurface;
                                            } else if (day.hasDeadlineSpan) {
                                                return Colors.danger;
                                            } else if (day.hasImportantSpan) {
                                                return Colors.warning;
                                            } else if (day.hasDeadline) {
                                                return Colors.danger;
                                            } else if (day.hasImportant) {
                                                return Colors.warning;
                                            } else if (day.events.length > 0) {
                                                return Colors.success;
                                            } else if (day.reminders.length > 0) {
                                                return Colors.info;
                                            } else {
                                                return Colors.fgBase;
                                            }
                                        }

                                        font: {
                                            if (day.hasDeadline) {
                                                return Cell.fontBB;
                                            }
                                            if (day.isToday || day.isSelected || day.reminders.length > 0 || day.events.length > 0) {
                                                return Cell.fontB;
                                            }
                                            return Cell.font;
                                        }
                                    }

                                    CellText {

                                        x: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                                        text: {
                                            if (day.hasDeadline && (day.isSelected || day.isToday) && blinking_deadline.on) {
                                                return "!  !";
                                            }
                                            return "";
                                        }

                                        color: {
                                            if (day.isToday) {
                                                return Colors.onAccent;
                                            } else if (day.isSelected) {
                                                return Colors.bgSurface;
                                            }
                                            return Colors.fgBase;
                                        }
                                        font: Cell.fontBB
                                    }

                                    MouseControl {

                                        anchors.fill: parent

                                        onPressed: button => {
                                            const global = mapToGlobal(mouseX, mouseY);
                                            if (button == "L" && day.inMonth) {
                                                if (!day.isSelected) {
                                                    calendar.selected = {
                                                        "day": day.date,
                                                        "month": calendar.month,
                                                        "year": calendar.year
                                                    };
                                                } else {
                                                    calendar.selected = calendar.today;
                                                }
                                            }
                                            if (button == "R" && day.inMonth) {
                                                ContextMenuManager.show([
                                                    {
                                                        label: (day.date == calendar.selected.day && calendar.month == calendar.selected.month && calendar.year == calendar.selected.year) ? "Deselect" : "Select",
                                                        action: () => {
                                                            if (!day.isSelected) {
                                                                calendar.selected = {
                                                                    "day": day.date,
                                                                    "month": calendar.month,
                                                                    "year": calendar.year
                                                                };
                                                            } else {
                                                                calendar.selected = calendar.today;
                                                            }
                                                        },
                                                        disabled: day.isToday && calendar.selected.day == calendar.today.day && calendar.selected.month == calendar.today.month && calendar.selected.year == calendar.today.year
                                                    },
                                                    {
                                                        label: "Paste",
                                                        disabled: !root.clipboard.mode,
                                                        action: () => {
                                                            if (root.clipboard.mode) {
                                                                console.log(JSON.stringify(root.clipboard));
                                                                let mode = root.clipboard.mode;
                                                                let title = root.clipboard.title;
                                                                let body = root.clipboard.body;
                                                                let date = CalendarInfo.moveDate(root.clipboard.date, day.date, calendar.month, calendar.year);
                                                                let urgency = root.clipboard.urgency;
                                                                let time = root.clipboard.time;
                                                                let span = root.clipboard.span;
                                                                CalendarInfo.add(mode, title, body, date, urgency, time, span);
                                                                root.clipboard = {};
                                                            }
                                                        }
                                                    },
                                                    {
                                                        label: "Add reminder",
                                                        action: () => {
                                                            if (!day.isSelected) {
                                                                calendar.selected = {
                                                                    "day": day.date,
                                                                    "month": calendar.month,
                                                                    "year": calendar.year
                                                                };
                                                            } else {
                                                                calendar.selected = calendar.today;
                                                            }
                                                            root.edit = !root.edit;
                                                        }
                                                    },
                                                ], global.x, global.y, undefined, "");
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    CellSeparator {
                        w: Cell.wCount(grid.implicitWidth)
                        type: 2
                        color: Colors.accentDim
                    }
                }

                CellSeparator {

                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: Cell.centerHCell(implicitHeight, row1.implicitHeight)

                    vertical: true

                    h: Cell.hCount(row1.implicitHeight)
                    color: Colors.accentStrong
                }

                ColumnLayout {
                    id: col3

                    Layout.alignment: Qt.AlignTop

                    spacing: 0

                    CellText {

                        text: "         REMINDERS & EVENTS         "
                        font: Cell.fontBB
                    }

                    CellText {

                        Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                        text: `${calendar.selected.day.toString().padStart(2, "0")}/${calendar.selected.month.toString().padStart(2, "0")}/${calendar.selected.year}`
                        color: Colors.secondary
                        font: Cell.fontB
                    }

                    CellSeparator {

                        w: Cell.wCount(col3.implicitWidth)
                        type: 0
                        color: Colors.accentStrong
                    }

                    Cells {
                        id: reminders

                        property var selectedReminders: []

                        Component.onCompleted: {
                            CalendarInfo.reloaded.connect(() => {
                                reload();
                            });
                        }

                        onVisibleChanged: {
                            reload();
                        }

                        function reload() {
                            const reminders = CalendarInfo.getReminders(calendar.selected.day, calendar.selected.month, calendar.selected.year).sort((a, b) => b.urgency - a.urgency);
                            const events = CalendarInfo.getEvents(calendar.selected.day, calendar.selected.month, calendar.selected.year).sort((a, b) => b.urgency - a.urgency);
                            const deadlines = CalendarInfo.forseeDeadlines(calendar.selected.day, calendar.selected.month, calendar.selected.year, 10).sort((a, b) => b.urgency - a.urgency);

                            for (const event of events) {
                                event.isEvent = true;
                            }

                            selectedReminders = [];
                            selectedReminders = [...events, ...reminders, ...deadlines].filter((item, index, self) => index === self.findIndex(t => {
                                    return t.title === item.title;
                                }));
                            reminders_scroll_view.reset();
                        }

                        w: Cell.wCount(col3.implicitWidth)
                        h: 7

                        color: "transparent"

                        CellScrollView {
                            id: reminders_scroll_view

                            w: reminders.w
                            h: reminders.h

                            source: ColumnLayout {
                                id: reminders_layout

                                spacing: 0

                                Repeater {

                                    model: reminders.selectedReminders

                                    delegate: Loader {
                                        id: reminders_loader

                                        required property int index
                                        required property var modelData

                                        active: root.visible || !root.optimizeMemory

                                        sourceComponent: Cells {
                                            id: reminder

                                            property int index: reminders_loader.index
                                            property var modelData: reminders_loader.modelData

                                            property string title: modelData.title
                                            property string body: modelData.body ?? ""
                                            property int idx: modelData.idx ?? 0
                                            property int urgency: modelData.urgency ?? 0
                                            property string time: modelData.time ?? ""
                                            property string date: modelData.date ?? ""
                                            property bool event: modelData.isEvent ?? false
                                            property int range: modelData.range ?? 0
                                            property int span: modelData.span ?? 1

                                            property bool expanded: false

                                            w: reminders_scroll_view.contentW
                                            h: Cell.hCount(reminder_layout.implicitHeight) + 1

                                            color: "transparent"

                                            ColumnLayout {
                                                id: reminder_layout

                                                spacing: 0

                                                RowLayout {

                                                    spacing: 0

                                                    CellText {

                                                        Layout.alignment: Qt.AlignTop
                                                        text: {
                                                            if (reminder.urgency == 1) {
                                                                return " ! ";
                                                            } else if (reminder.urgency == 2) {
                                                                return " !! ";
                                                            }
                                                            return " ▪ ";
                                                        }
                                                        font: Cell.fontBB
                                                        color: {
                                                            if (reminder.urgency == 1) {
                                                                return Colors.warning;
                                                            } else if (reminder.urgency == 2) {
                                                                return Colors.danger;
                                                            } else if (reminder.event) {
                                                                return Colors.success;
                                                            }
                                                            return Colors.fgBase;
                                                        }
                                                    }

                                                    CellText {
                                                        id: reminder_title

                                                        Layout.alignment: Qt.AlignTop

                                                        text: reminder.title + (reminder.body != "" ? " [+]" : "") + (reminder.range > 0 ? (" in " + reminder.range + (reminder.range > 1 ? " days" : " day")) : "")
                                                        preferedW: 31 - (reminder.urgency == 2) * 1 - (reminder_time.text != "") * 6
                                                        wrap: true

                                                        color: {
                                                            if (reminder.range > 0) {
                                                                return Colors.fgDim;
                                                            }
                                                            if (reminder.event) {
                                                                return Colors.blend(Colors.fgBase, Colors.warning, 0.5);
                                                            }
                                                            return Colors.fgBase;
                                                        }

                                                        font: {
                                                            if (reminder.event) {
                                                                return Cell.fontB;
                                                            }
                                                            return Cell.font;
                                                        }
                                                    }

                                                    CellText {
                                                        text: " "
                                                    }

                                                    CellText {
                                                        id: reminder_time

                                                        Layout.alignment: Qt.AlignTop

                                                        text: {
                                                            if (reminder.time) {
                                                                let time = reminder.time.split(":");
                                                                for (const i in time) {
                                                                    time[i] = time[i].toString().padStart(2, "0");
                                                                }
                                                                return time.join(":");
                                                            }
                                                            return "";
                                                        }

                                                        color: {
                                                            const time = reminder.time.split(":");
                                                            if (parseInt(DateTime.date) >= parseInt(calendar.selected.day) && parseInt(DateTime.month_numeral) >= parseInt(calendar.selected.month) && parseInt(DateTime.year) >= parseInt(calendar.selected.year) && reminder.range == 0) {
                                                                if (parseInt(DateTime.hour24) * 60 + parseInt(DateTime.minute) >= parseInt(time[0]) * 60 + parseInt(time[1])) {
                                                                    return Colors.danger;
                                                                } else if ((parseInt(time[0]) * 60 + parseInt(time[1])) - (parseInt(DateTime.hour24) * 60 + parseInt(DateTime.minute)) < 10) {
                                                                    return Colors.warning;
                                                                }
                                                            }
                                                            return Colors.fgSubtle;
                                                        }
                                                    }
                                                }

                                                CellSeparator {

                                                    visible: reminder.expanded

                                                    Layout.leftMargin: Cell.w(3 + (reminder.urgency == 2) * 1)

                                                    w: 31 - (reminder.urgency == 2) * 1 - (reminder_time.text != "") * 6
                                                    color: Colors.bgOverlay
                                                    bg: "transparent"
                                                }

                                                RowLayout {

                                                    visible: reminder.expanded

                                                    spacing: 0

                                                    CellText {
                                                        text: "   "
                                                    }

                                                    CellText {
                                                        text: reminder.body
                                                        preferedW: 31 - (reminder.urgency == 2) * 1 - (reminder_time.text != "") * 6
                                                        wrap: true
                                                        color: {
                                                            if (reminder.range > 0) {
                                                                return Colors.fgSubtle;
                                                            }
                                                            return Colors.fgDim;
                                                        }
                                                    }
                                                }
                                            }

                                            MouseControl {
                                                implicitWidth: Cell.w(reminders_scroll_view.contentW)
                                                implicitHeight: Cell.h(Cell.hCount(reminder_layout.implicitHeight))

                                                onPressed: button => {
                                                    const global = mapToGlobal(mouseX, mouseY);
                                                    if (button == "L") {
                                                        if (reminder.body != "")
                                                            reminder.expanded = !reminder.expanded;
                                                    } else if (button == "R" && !reminder.range) {
                                                        ContextMenuManager.show([
                                                            {
                                                                label: "Edit",
                                                                action: () => {
                                                                    root.edit = true;
                                                                    edit.add = false;
                                                                    title_textfield.set(reminder.title);
                                                                    body_textfield.set(reminder.body);
                                                                    span_textfield.set(reminder.span);

                                                                    urgency.selected = reminder.urgency;
                                                                    mode.selected = reminder.event ? 1 : 0;

                                                                    const index = reminder.idx;
                                                                    const date = reminder.date;
                                                                    const span = reminder.span;
                                                                    let freq = 0;

                                                                    if (CalendarInfo.weekdays.includes(date)) {
                                                                        freq = 2;
                                                                    } else if (/^\d{2}-d{2}-d{4}$/.test(date)) {
                                                                        freq = 0;
                                                                    } else if (/^\d{2}\/\d{2}\/\d{4}$/.test(date)) {
                                                                        freq = 1;
                                                                    } else if (/^\d{2}$/.test(date)) {
                                                                        freq = 3;
                                                                    } else if (/^\d{2}-d{2}$/.test(date)) {
                                                                        freq = 4;
                                                                    }

                                                                    frequency.selected = freq;

                                                                    if (reminder.time) {
                                                                        const time = reminder.time.split(":");
                                                                        hour.set(time[0]);
                                                                        minute.set(time[1]);
                                                                        hour.set(time[0]);
                                                                        minute.set(time[1]);
                                                                    }

                                                                    edit.origin = {
                                                                        "index": index,
                                                                        "date": date,
                                                                        "span": span,
                                                                        "event": reminder.event,
                                                                        "freq": freq
                                                                    };
                                                                }
                                                            },
                                                            {
                                                                label: "Copy",
                                                                action: () => {
                                                                    root.clipboard = {
                                                                        "mode": reminder.event ? "e" : "r",
                                                                        "title": reminder.title,
                                                                        "body": reminder.body,
                                                                        "date": reminder.date,
                                                                        "urgency": reminder.urgency,
                                                                        "time": reminder.time,
                                                                        "span": reminder.span
                                                                    };
                                                                }
                                                            },
                                                            {
                                                                label: "Remove",
                                                                action: () => {
                                                                    CalendarInfo.remove(reminder.event ? "e" : "r", reminder.date, reminder.idx);
                                                                }
                                                            },
                                                        ], global.x, global.y, undefined, "");
                                                    }
                                                }
                                            }

                                            CellSeparator {
                                                padding: 1
                                                y: reminder_layout.implicitHeight
                                                w: reminders_scroll_view.contentW
                                                type: 2
                                                color: Colors.bgOverlay
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    CellSeparator {

                        w: Cell.wCount(col3.implicitWidth)
                        type: 0
                        color: Colors.accentStrong
                    }

                    RowLayout {

                        spacing: 0

                        CellText {

                            text: " Reminders: " + reminders.selectedReminders.length + " "
                            preferedW: 28
                        }

                        CellButton {

                            text: "Add +"
                            color: [Colors.bgOverlay, Colors.fgBase]
                            fg: [Colors.fgBase, Colors.bgSurface]

                            onPressed: button => {
                                if (button == "L") {
                                    root.edit = !root.edit;
                                }
                            }
                        }
                    }
                }
            }

            CellSeparator {

                visible: root.edit

                w: box.contentW
                color: Colors.accentStrong
            }

            ColumnLayout {
                id: edit

                visible: root.edit

                onVisibleChanged: {
                    if (!visible) {
                        reset();
                    }
                }

                function apply() {
                    let mde;
                    let date;
                    let time;
                    let span;
                    let ur = urgency.selected;

                    if (span_textfield.text == "" || frequency.selected != 0) {
                        span = 1;
                    } else {
                        span = span_textfield.text;
                    }

                    if (mode.selected == 0) {
                        mde = "r";
                    } else if (mode.selected == 1) {
                        mde = "e";
                    }
                    if (frequency.selected == 0) {
                        date = `${calendar.selected.day.toString().padStart(2, "0")}-${calendar.selected.month.toString().padStart(2, "0")}-${calendar.selected.year}`;
                    } else if (frequency.selected == 1) {
                        date = `${calendar.selected.day.toString().padStart(2, "0")}/${calendar.selected.month.toString().padStart(2, "0")}/${calendar.selected.year}`;
                    } else if (frequency.selected == 2) {
                        date = CalendarInfo.getDay(calendar.selected.day, calendar.selected.month, calendar.selected.year);
                    } else if (frequency.selected == 3) {
                        date = `${calendar.selected.day.toString().padStart(2, "0")}`;
                    } else if (frequency.selected == 4) {
                        date = `${calendar.selected.day.toString().padStart(2, "0")}-${calendar.selected.month.toString().padStart(2, "0")}`;
                    }

                    if (hour.text == "" || minute.text == "") {
                        time = "";
                    } else {
                        time = hour.text.trim().toString().padStart(2, "0") + ":" + minute.text.trim().toString().padStart(2, "0");
                    }

                    if (edit.add) {
                        CalendarInfo.add(mde, title_textfield.text, body_textfield.text, date, ur, time, span);
                        root.edit = false;
                    } else {
                        if (edit.origin.date != date) {
                            CalendarInfo.remove(edit.origin.event ? "e" : "r", edit.origin.date, edit.origin.index);
                            CalendarInfo.add(mde, title_textfield.text, body_textfield.text, date, ur, time, span);
                        } else {
                            CalendarInfo.edit(mde, title_textfield.text, body_textfield.text, date, edit.origin.index, ur, time, span);
                        }
                        root.edit = false;
                    }
                }

                function reset() {
                    title_textfield.clear();
                    body_textfield.clear();
                    hour.set("");
                    minute.set("");
                    mode.selected = 0;
                    frequency.selected = 0;
                    urgency.selected = 0;
                    add = true;
                    date = "";
                    origin = ({});
                }

                property string date: ""

                property bool add: true

                property var origin: ({})

                spacing: 0

                RowLayout {

                    Layout.leftMargin: Cell.centerWCell(implicitWidth, Cell.w(box.contentW))

                    spacing: 0

                    CellText {
                        text: root.minimal ? (edit.add ? `ADD on ` : `EDIT on `) : (edit.add ? `ADD REMINDER on ` : `EDIT REMINDER on `)
                        font: Cell.fontB
                    }

                    CellText {

                        function selected_date() {
                            if (frequency.selected == 0) {
                                return `${calendar.selected.day}/${calendar.selected.month}/${calendar.selected.year}`;
                            } else if (frequency.selected == 1) {
                                return `${calendar.selected.day}/${calendar.selected.month}/${calendar.selected.year} and its week`;
                            } else if (frequency.selected == 2) {
                                const weekday = CalendarInfo.getDay(calendar.selected.day, calendar.selected.month, calendar.selected.year);
                                if (weekday == "MO") {
                                    return "Every Monday";
                                } else if (weekday == "TU") {
                                    return "Every Tuesday";
                                } else if (weekday == "WE") {
                                    return "Every Wednesday";
                                } else if (weekday == "TH") {
                                    return "Every Thursday";
                                } else if (weekday == "FR") {
                                    return "Every Friday";
                                } else if (weekday == "SA") {
                                    return "Every Saturday";
                                } else if (weekday == "SU") {
                                    return "Every Sunday";
                                }
                            } else if (frequency.selected == 3) {
                                return `${calendar.selected.day} every month`;
                            } else if (frequency.selected == 4) {
                                return `${calendar.selected.day}/${calendar.selected.month} every year`;
                            }
                        }

                        function origin_date() {
                            const date = edit.origin.date;

                            if (CalendarInfo.weekdays.includes(date)) {
                                if (date == "MO") {
                                    return "Every Monday";
                                } else if (date == "TU") {
                                    return "Every Tuesday";
                                } else if (date == "WE") {
                                    return "Every Wednesday";
                                } else if (date == "TH") {
                                    return "Every Thursday";
                                } else if (date == "FR") {
                                    return "Every Friday";
                                } else if (date == "SA") {
                                    return "Every Saturday";
                                } else if (date == "SU") {
                                    return "Every Sunday";
                                }
                            } else if (/^\d{2}-\d{2}-\d{4}$/.test(date)) {
                                const new_date = date.split("-");
                                for (let each of new_date) {
                                    each = parseInt(each);
                                }
                                return new_date.join("/");
                            } else if (/^\d{2}\/\d{2}\/\d{4}$/.test(date)) {
                                const new_date = date.split("/");
                                for (let each of new_date) {
                                    each = parseInt(each);
                                }
                                return new_date.join("/") + " and its week";
                            } else if (/^\d{2}$/.test(date)) {
                                return parseInt(date) + " every month";
                            } else if (/^\d{2}-\d{2}$/.test(date)) {
                                const new_date = date.split("/");
                                for (let each of new_date) {
                                    each = parseInt(each);
                                }
                                return new_date.join("/") + " every year";
                            }
                            return date;
                        }

                        text: {
                            if (edit.add) {
                                return selected_date();
                            } else {
                                if (edit.origin.date == `${calendar.selected.day.toString().padStart(2, "0")}-${calendar.selected.month.toString().padStart(2, "0")}-${calendar.selected.year}` || edit.origin.date == `${calendar.selected.day.toString().padStart(2, "0")}` || edit.origin.date == `${calendar.selected.day.toString().padStart(2, "0")}-${calendar.selected.month.toString().padStart(2, "0")}` || edit.origin.date == CalendarInfo.getDay(calendar.selected.day, calendar.selected.month, calendar.selected.year)) {
                                    return selected_date();
                                } else {
                                    return `${origin_date()} => ${selected_date()}`;
                                }
                            }
                        }
                        color: Colors.secondary
                        font: Cell.fontB
                    }
                }

                CellSeparator {
                    w: box.contentW
                    type: 2
                    padding: 1
                    color: Colors.bgOverlay
                }

                ColumnLayout {

                    spacing: 0

                    RowLayout {

                        spacing: 0

                        CellText {
                            text: " Title "
                        }

                        Cells {

                            w: box.contentW - 8
                            h: 1

                            color: Colors.bgOverlay

                            CellTextField {
                                id: title_textfield

                                x: Cell.w(1)
                                w: parent.w - 1
                                h: 1

                                autoApply: true
                                placeholder: "Title (obligated)"
                            }
                        }
                    }

                    CellSeparator {
                        w: box.contentW
                        type: 0
                        padding: 1
                        color: Colors.bgOverlay
                    }

                    RowLayout {

                        spacing: 0

                        CellText {
                            text: " Body  "
                        }

                        Cells {

                            w: box.contentW - 8
                            h: 1

                            color: Colors.bgOverlay

                            CellTextField {
                                id: body_textfield

                                x: Cell.w(1)
                                w: parent.w - 1
                                h: 1

                                autoApply: true

                                placeholder: "Body (optional)"
                                focusOnVisible: false
                            }
                        }
                    }

                    CellSeparator {
                        w: box.contentW
                        type: 0
                        padding: 1
                        color: Colors.bgOverlay
                    }

                    RowLayout {

                        Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                        spacing: 0

                        CellText {
                            visible: !root.minimal
                            text: " Mode "
                        }

                        CellDropdown {
                            id: mode

                            w: 12
                            text: ""
                            items: [
                                {
                                    label: "Reminder",
                                    action: () => selected = 0
                                },
                                {
                                    label: "Event",
                                    action: () => selected = 1
                                },
                            ]
                            onActivated: index => {
                                items[index].action();
                            }
                        }

                        CellText {
                            text: " "
                        }

                        CellDropdown {
                            id: frequency

                            w: 12
                            text: ""
                            items: [
                                {
                                    label: "One-time",
                                    action: () => selected = 0
                                },
                                {
                                    label: "Daily",
                                    action: () => selected = 1
                                },
                                {
                                    label: "Weekly",
                                    action: () => selected = 2
                                },
                                {
                                    label: "Monthly",
                                    action: () => selected = 3
                                },
                                {
                                    label: "Yearly",
                                    action: () => selected = 4
                                },
                            ]
                        }

                        CellText {

                            visible: frequency.selected == 0
                            text: " "
                        }

                        CellText {

                            visible: frequency.selected == 0 && !root.minimal
                            text: "Span "
                        }

                        Cells {

                            visible: frequency.selected == 0

                            h: 1
                            w: 3

                            color: Colors.bgOverlay

                            CellTextField {
                                id: span_textfield

                                w: 3
                                h: 1

                                autoApply: true

                                placeholder: "1"
                                autoClear: false

                                focusOnVisible: false

                                onTextInput: input => {
                                    if (parseInt(input) < 1) {
                                        clear();
                                        set("1");
                                    }

                                    if (input.length > 2) {
                                        clear();
                                        set(input.slice(0, -1));
                                    }
                                }
                            }
                        }

                        CellText {
                            text: " "
                        }

                        CellText {
                            visible: !root.minimal
                            text: "Time "
                        }

                        Cells {

                            h: 1
                            w: 9

                            color: Colors.bgOverlay

                            RowLayout {

                                spacing: 0

                                CellText {

                                    text: " "
                                }

                                CellTextField {
                                    id: hour

                                    h: 1
                                    w: 3
                                    placeholder: "hh"
                                    focusOnVisible: false

                                    autoApply: true
                                    unfocusOnEntered: true

                                    onTextInput: input => {
                                        if (input == "")
                                            return;
                                        if (!/^\d+$/.test(input)) {
                                            clear();
                                            set("00");
                                        }

                                        if (input.length > 2) {
                                            clear();
                                            set(input.slice(1));
                                        }

                                        if (input.length > 0 && minute.text.length == 0) {
                                            minute.set("00");
                                        }
                                        const num = parseInt(input);

                                        if (num < 0 || num > 23 || !num) {
                                            clear();
                                            set("00");
                                        } else if (num < 10) {
                                            clear();
                                            set(num.toString().padStart(2, "0"));
                                        }
                                    }

                                    onTextRemoved: input => {
                                        if (input == "0") {
                                            set("");
                                        }
                                    }

                                    onFocusChanged: {
                                        if (text == "") {
                                            minute.set("");
                                        }
                                    }
                                }

                                CellText {

                                    text: ": "
                                }

                                CellTextField {
                                    id: minute

                                    h: 1
                                    w: 3
                                    placeholder: "mm"
                                    focusOnVisible: false

                                    autoApply: true
                                    unfocusOnEntered: true

                                    onTextInput: input => {
                                        if (input == "")
                                            return;
                                        if (!/^\d+$/.test(input)) {
                                            clear();
                                            set("00");
                                        }

                                        if (input.length > 2) {
                                            clear();
                                            set(input.slice(1));
                                        }

                                        if (input.length > 0 && hour.text.length == 0) {
                                            hour.set("00");
                                        }
                                        const num = parseInt(input);

                                        if (num < 0 || num > 59 || !num) {
                                            clear();
                                            set("00");
                                        } else if (num < 10) {
                                            clear();
                                            set(num.toString().padStart(2, "0"));
                                        }
                                    }

                                    onTextRemoved: input => {
                                        if (input == "0") {
                                            set("");
                                        }
                                    }

                                    onFocusChanged: {
                                        if (text == "") {
                                            hour.set("");
                                        }
                                    }
                                }
                            }
                        }

                        CellText {
                            text: " "
                        }

                        CellText {
                            visible: !root.minimal
                            text: "Urgency "
                        }

                        CellDropdown {
                            id: urgency

                            w: 13
                            text: ""
                            items: [
                                {
                                    label: "Normal",
                                    action: () => selected = 0
                                },
                                {
                                    label: "Important",
                                    action: () => selected = 1
                                },
                                {
                                    label: "Deadline",
                                    action: () => selected = 2
                                },
                            ]
                        }
                    }

                    CellText {
                        text: ""
                    }

                    RowLayout {

                        Layout.alignment: Qt.AlignRight
                        Layout.rightMargin: Cell.w(2)

                        spacing: Cell.w(2)

                        CellButton {

                            text: edit.add ? "Add" : "Apply"

                            clickable: title_textfield.text.length > 0

                            color: clickable ? [Colors.accentStrong, Colors.bgOverlay] : Colors.bgOverlay
                            fg: clickable ? [Colors.onAccent, Colors.fgBase] : Colors.fgSubtle

                            onReleased: button => {
                                if (button == "L") {
                                    edit.apply();
                                }
                            }
                        }

                        CellButton {

                            text: "Cancel"

                            color: clickable ? [Colors.bgOverlay, Colors.fgBase] : Colors.bgOverlay
                            fg: clickable ? [Colors.fgBase, Colors.bgSurface] : Colors.fgSubtle

                            onReleased: button => {
                                if (button == "L") {
                                    root.edit = !root.edit;
                                }
                            }
                        }
                    }
                }
            }

            CellSeparator {

                visible: SettingsInfo.hints

                w: box.contentW
                type: 0
                color: Colors.accentStrong
            }

            RowLayout {

                visible: SettingsInfo.hints

                Layout.leftMargin: Cell.centerWCell(implicitWidth, Cell.w(box.contentW))

                spacing: Cell.w(2)

                CellKeyHint {

                    key: "← ↑ ↓ →"
                    hint: root.minimal ? "Nav" : "Navigate"
                }

                CellKeyHint {

                    key: "Enter"
                    hint: root.minimal ? (edit.add ? "Add" : "Edit") : (edit.add ? "Add reminder" : "Edit reminder")
                }

                CellKeyHint {

                    visible: root.edit

                    key: "Tab"
                    hint: "Switch field"
                }

                CellKeyHint {

                    visible: root.edit

                    key: "Esc"
                    hint: "Cancel"
                }
            }
        }
    }
}
