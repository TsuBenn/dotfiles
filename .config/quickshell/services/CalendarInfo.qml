pragma Singleton

import qs.services

import Quickshell
import QtQuick

Singleton {

    id: root

    property var dates: []

    readonly property var date: DateTime.date

    readonly property var monthsof30: [4,6,9,11]
    readonly property var dayofweek: ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]

    function calculateCalendar() {

        root.dates = []

        const dayIndex = dayofweek.indexOf(DateTime.dayofweek_short)
        const isMonthof30 = monthsof30.includes(parseInt(DateTime.month_numeral))
        const today = parseInt(DateTime.date)

        root.dates.push({"day": today, "inMonth": true, "isToday": true})

        function dayItt(day, inc) : int {
            day += inc
            if (day > 6) {
                return 0
            } else if (day < 0) {
                return 6
            } else {
                return day
            }
        }
        function monthItt(month, inc) : int {
            month += inc
            if (month > 12) {
                return 1
            } else if (month < 1) {
                return 12
            } else {
                return month
            }
        }
        function febMaxDate() : int {
            let year = parseInt(DateTime.year)
            if ((year % 4 === 0 && year % 100 !== 0) || (year % 400 === 0)) {
                return 29
            } else {
                return 28
            }
        }
        function monthMaxDate(month) {
                if (root.monthsof30.includes(month)) {
                    return 30
                } else if (month!=2) {
                    return 31
                } else {
                    return febMaxDate()
                }
        }

        let currdate = today - 1
        let thisMonth = parseInt(DateTime.month_numeral)
        let currday = dayIndex

        while (currdate > 0) {
            currday = dayItt(currday, -1)
            root.dates.unshift({"day": currdate, "inMonth": true, "isToday": false})
            currdate -= 1
        }
        if (currday != 0) {
            currdate = monthMaxDate(monthItt(thisMonth,-1))
        }
        while (currday != 0) {
            currday = dayItt(currday, -1)
            root.dates.unshift({"day": currdate, "inMonth": false, "isToday": false})
            currdate -= 1
        }

        currdate = today + 1
        currday = dayIndex

        while (currdate <= monthMaxDate(thisMonth)) {
            currday = dayItt(currday, 1)
            root.dates.push({"day": currdate, "inMonth": true, "isToday": false})
            currdate += 1
        }
        if (currday != 6) {
            currdate = 1
        }
        while (currday != 6) {
            currday = dayItt(currday, 1)
            root.dates.push({"day": currdate, "inMonth": false, "isToday": false})
            currdate += 1
        }

        console.log("It's the Next Day! Re-calculation Calendar")

        /**
         for (const day of dates) {
             console.log(`${day.day} ${day.inMonth} ${day.isToday}`)
         }
        **/

    }

    onDateChanged: {
        calculateCalendar()
    }

    Component.onCompleted: {
        calculateCalendar()
    }

}
