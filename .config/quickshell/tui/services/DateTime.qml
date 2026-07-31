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

    function formatDuration(totalSeconds) {
        if (!totalSeconds || totalSeconds < 1)
            return "0s";

        let days = Math.floor(totalSeconds / 86400);
        let hours = Math.floor((totalSeconds % 86400) / 3600);
        let minutes = Math.floor((totalSeconds % 3600) / 60);
        let seconds = Math.floor(totalSeconds % 60);

        if (days > 0)
            return hours > 0 ? `${days}d${hours}h` : `${days}d`;
        if (hours > 0)
            return minutes > 0 ? `${hours}h${minutes}m` : `${hours}h`;
        if (minutes > 0)
            return seconds > 0 ? `${minutes}m${seconds}s` : `${minutes}m`;
        return `${seconds}s`;
    }

    function formatTimestampToHHMM(timestampMs = Date.now()) {
        if (!timestampMs)
            return "00:00";
        const date = new Date(timestampMs);
        const hours = date.getHours();
        const minutes = date.getMinutes();
        return (hours < 10 ? "0" + hours : hours) + ":" + (minutes < 10 ? "0" + minutes : minutes);
    }

    function monthNumToShort(month) {
        return months[month - 1];
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
}
