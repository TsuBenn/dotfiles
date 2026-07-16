pragma Singleton

import qs.config
import qs.services

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    /*
     * REMINDERS AND EVENTS FORMAT
     *
     * DD-MM-YYYY: One-time
     *
     * DD/MM/YYYY: Daily, for that week
     *
     * DDD (e.g. MO, TU): Weekly
     *
     * DD: Monthly (doesn't always work with 29 -> 31 since not every month has these days)
     *
     * DD-MM: Yearly
     *
     * DATES AND MONTHS SHOULD BE PADDING WITH 0
     */

    readonly property var weekdays: ["MO", "TU", "WE", "TH", "FR", "SA", "SU",]

    readonly property string backend: SystemInfo.configdir + "/scripts/calendar_manager.py"

    property var reminders: ({})
    property var events: ({})

    signal reloaded

    FileView {
        id: load_reminders

        path: SystemInfo.configdir + "/scripts/reminders.json"

        onLoaded: {
            let datas = JSON.parse(text());
            let spans = {};

            for (const data in datas) {
                for (const i in datas[data]) {
                    datas[data][i].date = data;
                    datas[data][i].idx = i;
                    if (datas[data][i].span > 1 && (/^\d{2}-\d{2}-\d{4}$/.test(data))) {
                        datas[data][i].span_idx = 1;

                        const split_date = data.split("-");

                        const rawDate = new Date(parseInt(split_date[2]), parseInt(split_date[1] - 1), parseInt(split_date[0]));

                        const span = datas[data][i].span;

                        for (let j = 1; j < span; j++) {
                            rawDate.setDate(rawDate.getDate() + 1);
                            const new_date = `${rawDate.getDate().toString().padStart(2, "0")}-${(rawDate.getMonth() + 1).toString().padStart(2, "0")}-${rawDate.getFullYear().toString().padStart(4, "0")}`;
                            if (!spans[new_date]) {
                                spans[new_date] = [];
                            }
                            spans[new_date].push({
                                "title": datas[data][i].title,
                                "body": datas[data][i].body,
                                "urgency": datas[data][i].urgency,
                                "time": datas[data][i].time,
                                "idx": datas[data][i].idx,
                                "span": datas[data][i].span,
                                "span_idx": j + 1,
                                "date": datas[data][i].date
                            });
                        }
                    }
                }
            }

            for (const data in spans) {
                for (const i in spans[data]) {
                    if (!datas[data]) {
                        datas[data] = [];
                    }
                    datas[data].push(spans[data][i]);
                }
            }

            root.reminders = datas;
            root.reloaded();
        }
    }

    function moveDate(date: string, new_date: int, new_month: int, new_year: int): string {
        date = date.trim();
        new_date = new_date.toString().padStart(2, "0");
        new_month = new_month.toString().padStart(2, "0");
        new_year = new_year.toString().padStart(4, "0");
        if (weekdays.includes(date)) {
            return getDay(new_date, new_month, new_year);
        } else if (/^\d{2}-\d{2}-\d{4}$/.test(date)) {
            return `${new_date}-${new_month}-${new_year}`;
        } else if (/^\d{2}\/\d{2}\/\d{4}$/.test(date)) {
            return `${new_date}/${new_month}/${new_year}`;
        } else if (/^\d{2}$/.test(date)) {
            return `${new_date}`;
        } else if (/^\d{2}-\d{2}$/.test(date)) {
            return `${new_date}-${new_month}`;
        }
    }

    FileView {
        id: load_events

        path: SystemInfo.configdir + "/scripts/events.json"

        onLoaded: {
            let datas = JSON.parse(text());
            let spans = {};
            for (const data in datas) {
                for (const i in datas[data]) {
                    datas[data][i].date = data;
                    datas[data][i].idx = i;
                    if (datas[data][i].span > 1 && (/^\d{2}-\d{2}-\d{4}$/.test(data))) {
                        datas[data][i].span_idx = 1;

                        const split_date = data.split("-");

                        const rawDate = new Date(parseInt(split_date[2]), parseInt(split_date[1] - 1), parseInt(split_date[0]));

                        const span = datas[data][i].span;

                        for (let j = 1; j < span; j++) {
                            rawDate.setDate(rawDate.getDate() + 1);
                            const new_date = `${rawDate.getDate().toString().padStart(2, "0")}-${(rawDate.getMonth() + 1).toString().padStart(2, "0")}-${rawDate.getFullYear().toString().padStart(4, "0")}`;
                            if (!spans[new_date]) {
                                spans[new_date] = [];
                            }
                            spans[new_date].push({
                                "title": datas[data][i].title,
                                "body": datas[data][i].body,
                                "urgency": datas[data][i].urgency,
                                "time": datas[data][i].time,
                                "idx": datas[data][i].idx,
                                "span": datas[data][i].span,
                                "span_idx": j + 1,
                                "date": datas[data][i].date
                            });
                        }
                    }
                }
            }

            for (const data in spans) {
                for (const i in spans[data]) {
                    if (!datas[data]) {
                        datas[data] = [];
                    }
                    datas[data].push(spans[data][i]);
                }
            }

            root.events = datas;
            root.reloaded();
        }
    }

    function timeReminder(day, month, year) {
        const r = getReminders(day, month, year);
        const e = getEvents(day, month, year);

        const datas = [...e, ...r];

        for (const reminder of datas) {
            const time = reminder.time.split(":");

            const rmin = parseInt(time[0]) * 60 + parseInt(time[1]);
            const nmin = parseInt(DateTime.hour24) * 60 + parseInt(DateTime.minute);

            if (!reminder.time && nmin % 30 == 0 && reminder.urgency > 0) {
                NotificationsInfo.send("REMINDERS & EVENTS", "", reminder.title ?? "", reminder.body ?? "", reminder.urgency, true, "qs -c tui ipc call config open_popup calendar");
                continue;
            }

            function sendNotif(text) {
                NotificationsInfo.send("REMINDERS & EVENTS", "", reminder.title, "Happens in <b>" + text + "</b>", reminder.urgency, false, "qs -c tui ipc call config open_popup calendar");
            }

            if (rmin - nmin == 60) {
                sendNotif("1 hour");
            } else if (rmin - nmin == 30) {
                sendNotif("30 minutes");
            } else if (rmin - nmin == 20) {
                sendNotif("20 minutes");
            } else if (rmin - nmin == 15) {
                sendNotif("15 minutes");
            } else if (rmin - nmin == 10) {
                sendNotif("10 minutes");
            } else if (rmin - nmin == 5) {
                sendNotif("5 minutes");
            } else if (rmin - nmin == 2) {
                sendNotif("2 minutes");
            } else if (rmin - nmin == 0) {
                NotificationsInfo.send("REMINDERS & EVENTS", "", reminder.title ?? "", reminder.body ?? "", reminder.urgency, true, "qs -c tui ipc call config open_popup calendar");
            }
        }
    }

    function forseeDeadlines(day, month, year, range) {
        let deadlines = [];

        let rawDate = new Date(year, month - 1, day);

        for (let i = 0; i < range; i++) {
            rawDate.setDate(rawDate.getDate() + 1);
            const d = rawDate.getDate();
            const m = rawDate.getMonth() + 1;
            const y = rawDate.getFullYear();

            const r = getReminders(d, m, y);
            const e = getEvents(d, m, y);

            for (const reminder of r) {
                if (reminder.urgency > 0) {
                    deadlines.push({
                        "title": reminder.title,
                        "body": reminder.body,
                        "urgency": reminder.urgency,
                        "time": reminder.time,
                        "date": reminder.date,
                        "idx": reminder.idx,
                        "range": i + 1
                    });
                }
            }

            for (const reminder of e) {
                deadlines.push({
                    "title": reminder.title,
                    "body": reminder.body,
                    "urgency": reminder.urgency,
                    "time": reminder.time,
                    "date": reminder.date,
                    "isEvent": true,
                    "idx": reminder.idx,
                    "range": i + 1
                });
            }
        }

        deadlines = deadlines.filter((item, index, self) => index === self.findIndex(t => {
                return t.title === item.title;
            }));

        deadlines.sort((a, b) => a.time.localeCompare(b.time));

        return deadlines;
    }

    function getDay(day, month, year) {
        const rawDay = new Date(year, month - 1, day).getDay();
        const firstDay = (rawDay === 0 ? 6 : rawDay - 1);

        return root.weekdays[firstDay];
    }

    function reload() {
        load_events.reload();
        load_reminders.reload();
    }

    function edit(mode = "", title, body, date, index, urgency = 0, time = "", span = 1) {
        if (mode == "r") {
            exec(`-es --index=${index} --span=${span} --time=${time} --date=${date} --body=${body.trim().split(" ").join("-")} --urgency=${urgency} ${title}`);
        } else if (mode == "e") {
            exec(`-ems --index=${index} --span=${span} --time=${time} --date=${date} --body=${body.trim().split(" ").join("-")} --urgency=${urgency} ${title}`);
        }
    }

    function add(mode = "", title, body, date, urgency = 0, time = "", span = 1) {
        if (mode == "r") {
            exec(`-as --time=${time} --span=${span} --date=${date} --body=${body.trim().split(" ").join("-")} --urgency=${urgency} ${title}`);
        } else if (mode == "e") {
            exec(`-ams --time=${time} --span=${span} --date=${date} --body=${body.trim().split(" ").join("-")} --urgency=${urgency} ${title}`);
        }
    }

    function remove(mode, date, index = -1) {
        if (index == -1) {
            exec(`-rs --index=${index} --date=${date}`);
        }
        if (!mode)
            return;
        if (mode == "r") {
            exec(`-rs --index=${index} --date=${date}`);
        } else if (mode == "e") {
            exec(`-rms --index=${index} --date=${date}`);
        }
    }

    function exec(text) {
        process.command = ["python", root.backend, text];
        process.running = true;
    }

    function getReminders(day, month, year) {
        let reminders = [];

        const rawDate = new Date(year, month - 1, day);
        const rawDay = new Date(year, month - 1, day).getDay();
        const firstDay = (rawDay === 0 ? 6 : rawDay - 1);

        const weekday = root.weekdays[firstDay];

        const paddedDay = day.toString().padStart(2, "0");
        const paddedMonth = month.toString().padStart(2, "0");
        const paddedYear = year.toString().padStart(4, "0");

        reminders = root.reminders[`${paddedDay}-${paddedMonth}-${paddedYear}`] ?? [];
        reminders = [...reminders, ...root.reminders[`${paddedDay}`] ?? []];
        reminders = [...reminders, ...root.reminders[`${paddedDay}-${paddedMonth}`] ?? []];
        reminders = [...reminders, ...root.reminders[`${weekday}`] ?? []];

        rawDate.setDate(rawDate.getDate() - firstDay);

        for (let i = 0; i < 7; i++) {
            reminders = [...reminders, ...root.reminders[`${rawDate.getDate().toString().padStart(2, "0")}/${(rawDate.getMonth() + 1).toString().padStart(2, "0")}/${rawDate.getFullYear()}`] ?? []];
            rawDate.setDate(rawDate.getDate() + 1);
        }

        reminders.sort((a, b) => a.time.localeCompare(b.time));

        return reminders;
    }

    function getEvents(day, month, year) {
        let events = [];

        const rawDate = new Date(year, month - 1, day);
        const rawDay = new Date(year, month, 1).getDay();
        const firstDay = (rawDay === 0 ? 6 : rawDay - 1);

        const weekday = root.weekdays[firstDay];

        const paddedDay = day.toString().padStart(2, "0");
        const paddedMonth = month.toString().padStart(2, "0");
        const paddedYear = year.toString().padStart(4, "0");

        events = root.events[`${paddedDay}-${paddedMonth}-${paddedYear}`] ?? [];
        events = [...events, ...root.events[`${paddedDay}`] ?? []];
        events = [...events, ...root.events[`${paddedDay}-${paddedMonth}`] ?? []];
        events = [...events, ...root.events[`${weekday}`] ?? []];

        rawDate.setDate(rawDate.getDate() - firstDay);

        for (let i = 0; i < 7; i++) {
            events = [...events, ...root.events[`${rawDate.getDate().toString().padStart(2, "0")}/${(rawDate.getMonth() + 1).toString().padStart(2, "0")}/${rawDate.getFullYear()}`] ?? []];
            rawDate.setDate(rawDate.getDate() + 1);
        }

        events.sort((a, b) => a.time.localeCompare(b.time));

        return events;
    }

    function generateCalendar(year, month, todayObj) {
        // month: 0-11 (JS style)

        month -= 1;

        const result = [];

        const today = todayObj.day;
        const currentMonth = todayObj.month - 1;
        const currentYear = todayObj.year;

        const isCurrentMonth = (month === currentMonth && year === currentYear);

        // 1. First day of this month
        const rawDay = new Date(year, month, 1).getDay();
        const firstDay = (rawDay === 0 ? 6 : rawDay - 1);

        // 2. Days in this month
        const daysInMonth = new Date(year, month + 1, 0).getDate();

        // 3. Days in previous month
        const daysInPrevMonth = new Date(year, month, 0).getDate();

        // ---- PREVIOUS MONTH FILL ----
        for (let i = firstDay - 1; i >= 0; i--) {
            let reminders = getReminders(daysInPrevMonth - i, month == 0 ? 12 : month, year);
            let events = getEvents(daysInPrevMonth - i, month == 0 ? 12 : month, year);

            result.push({
                day: daysInPrevMonth - i,
                inMonth: false,
                reminders: reminders,
                events: events,
                isToday: false,
                isCurrentMonth: isCurrentMonth,
                nextMonth: false
            });
        }

        // ---- CURRENT MONTH ----
        for (let day = 1; day <= daysInMonth; day++) {
            let reminders = getReminders(day, month + 1, year);
            let events = getEvents(day, month + 1, year);

            result.push({
                day: day,
                inMonth: true,
                reminders: reminders,
                events: events,
                isToday: (day === today && month === currentMonth && year === currentYear),
                isCurrentMonth: isCurrentMonth
            });
        }

        // ---- NEXT MONTH FILL (to complete 6 rows x 7 days = 42 cells) ----
        const totalCells = 42;
        let nextDay = 1;

        while (result.length < totalCells) {
            let reminders = getReminders(nextDay, month + 2 > 12 ? month + 2 - 12 : month + 2, year);
            let events = getEvents(nextDay, month + 2 > 12 ? month + 2 - 12 : month + 2, year);

            result.push({
                day: nextDay++,
                inMonth: false,
                reminders: reminders,
                events: events,
                isToday: false,
                isCurrentMonth: isCurrentMonth,
                nextMonth: true
            });
        }

        return result;
    }

    Process {
        id: process

        onRunningChanged: {
            root.reload();
        }

        stdout: StdioCollector {
            onStreamFinished: {
                // if (text) {
                //     console.log("CalendarInfo: " + text)
                // }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text) {
                    console.log("CalendarInfo: Error:" + text);
                }
            }
        }
    }

    Component.onCompleted: {
        DateTime.minuteChanged.connect(() => {
            timeReminder(parseInt(DateTime.date), parseInt(DateTime.month_numeral), parseInt(DateTime.year));
        });
        DateTime.dateChanged.connect(() => {
            reload();
        });
    }
}
