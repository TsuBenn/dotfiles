pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    signal nextDay

    property string hour24: Qt.formatDateTime(clock.date, "hh")
    property string hour12: Qt.formatDateTime(clock.date, "hh ap").split(" ")[0]
    property string minute: Qt.formatDateTime(clock.date, "mm")
    property string second: Qt.formatDateTime(clock.date, "ss")
    property string ampm: Qt.formatDateTime(clock.date, "AP")

    property string dayofweek_short: Qt.formatDateTime(clock.date, "ddd")
    property string dayofweek_long: Qt.formatDateTime(clock.date, "dddd")
    property string date: Qt.formatDateTime(clock.date, "dd")
    property string month_numeral: Qt.formatDateTime(clock.date, "MM")
    property string month_short: Qt.formatDateTime(clock.date, "MMM")
    property string month_long: Qt.formatDateTime(clock.date, "MMMM")
    property string year: Qt.formatDateTime(clock.date, "yyyy")

    onDateChanged: nextDay()

    property var months: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    property var days: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    function getDay(delta = 0) {
        // 0 means today, 1 means tomorrow and -1 means yesterday and so on
        const d = new Date();
        d.setDate(d.getDate() + delta);
        return d;
    }

    function getWeek(delta = 0) {
        // 0 means today of this week, 1 means this day of next week and -1 means this day of last week and so on
        const d = new Date();
        d.setDate(d.getDate() + (delta * 7));
        return d;
    }

    function getMonth(delta = 0) {
        // 0 means today of this month, 1 means this day of next month and -1 means this day of last month and so on
        const d = new Date();
        d.setMonth(d.getMonth() + delta);
        return d;
    }

    function getStartDay(date = new Date()) {
        const d = new Date(date);
        d.setHours(0, 0, 0, 0);
        return d;
    }

    function getEndDay(date = new Date()) {
        const d = new Date(date);
        d.setHours(23, 59, 59, 999);
        return d;
    }

    function getStartMonth(date = new Date()) {
        const d = new Date(date);
        return new Date(d.getFullYear(), d.getMonth(), 1, 0, 0, 0, 0);
    }

    function getEndMonth(date = new Date()) {
        const d = new Date(date);
        // Passing 0 as the day rolls us back to the last day of the previous month,
        // so we look at month + 1 and day 0 to get the actual end of this month.
        return new Date(d.getFullYear(), d.getMonth() + 1, 0, 23, 59, 59, 999);
    }

    function getStartWeek(date = new Date()) {
        const d = new Date(date);
        const dayOfWeek = d.getDay();
        const distanceToMonday = (dayOfWeek === 0 ? 7 : dayOfWeek) - 1;

        d.setDate(d.getDate() - distanceToMonday);
        d.setHours(0, 0, 0, 0);
        return d;
    }

    function getEndWeek(date = new Date()) {
        const d = new Date(date);
        const dayOfWeek = d.getDay();
        const distanceToSunday = dayOfWeek === 0 ? 0 : 7 - dayOfWeek;

        d.setDate(d.getDate() + distanceToSunday);
        d.setHours(23, 59, 59, 999);
        return d;
    }

    function getStartYear(date = new Date()) {
        const d = new Date(date);
        return new Date(d.getFullYear(), 0, 1, 0, 0, 0, 0);
    }

    function getEndYear(date = new Date()) {
        const d = new Date(date);
        return new Date(d.getFullYear(), 11, 31, 23, 59, 59, 999);
    }

    function getDuration(start_time: int): int {
        return Date.now() - start_time;
    }

    function formatDuration(totalSeconds, precision = 2) {
        if (totalSeconds <= 0)
            return "0s";

        const units = [
            {
                label: "d",
                seconds: 86400
            },
            {
                label: "h",
                seconds: 3600
            },
            {
                label: "m",
                seconds: 60
            },
            {
                label: "s",
                seconds: 1
            }
        ];

        let remaining = totalSeconds;
        const result = [];

        for (const unit of units) {
            const value = Math.floor(remaining / unit.seconds);
            if (value > 0) {
                result.push(`${value}${unit.label}`);
                remaining %= unit.seconds;
            }
        }

        return result.slice(0, precision).join("") || "0s";
    }

    function formatTimestamp(timestamp, precision = 4) {
        // 1. Convert Unix timestamp into a JavaScript Date object
        const date = new Date(timestamp);

        // 2. Extract local time units directly from the Date object
        const hh = String(date.getHours()).padStart(2, '0');
        const mm = String(date.getMinutes()).padStart(2, '0');
        const ss = String(date.getSeconds()).padStart(2, '0');
        const mss = String(date.getMilliseconds()).padStart(3, '0');

        // 3. Collect units and slice by precision level
        const units = [hh, mm, ss, mss];
        return units.slice(0, precision).join(':');
    }

    function monthNumToShort(month) {
        return months[month - 1];
    }

    function dayNumToShort(day) {
        return days[day];
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
}
