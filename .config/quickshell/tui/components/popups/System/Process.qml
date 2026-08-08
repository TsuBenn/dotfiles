pragma ComponentBehavior: Bound

import qs.components.popups.System
import qs.config
import qs.services
import qs.modules

import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    spacing: 0

    property var box

    property bool minimal

    ColumnLayout {
        id: cpu_spike

        Layout.alignment: Qt.AlignTop

        spacing: 0

        property int w: 44

        Cores {
            w: parent.w
            box: root.box
        }

        CellSeparator {
            w: cpu_spike.w
            color: Colors.accentStrong
            type: 2
            bg: "transparent"
            connectStart: true
            connectEnd: true
        }

        GPU {
            w: parent.w
            box: root.box
        }
    }

    CellSeparator {
        vertical: true
        h: root.box.contentH - 2
        color: Colors.accentStrong
        bg: "transparent"
        connectEnd: true
        connectStart: true
    }

    ColumnLayout {
        id: top_screentime
        Layout.alignment: Qt.AlignTop
        spacing: 0

        property int w: root.box.contentW - cpu_spike.w - 1

        Top {}

        CellSeparator {
            w: top_screentime.w
            color: Colors.accentStrong
            type: 2
            bg: "transparent"
            connectStart: true
            connectEnd: true
        }

        CellTabs {
            id: date_range

            property int range: selected
            property var date: date_tk.date

            function select(i: int) {
                selected = Math.max(Math.min(i, items.length - 1), 0);
            }

            items: ["Day", "Week", "Month"]

            property var screentime_disabled: []

            w: top_screentime.w
            distributed: false
            disabled: mode.selected == 0 ? screentime_disabled : []
            centered: false
            offset: 1
            spacing: 1
            padding: 0
            color.active: Colors.fgBase
            color.inactive: Colors.fgSubtle
            color.fg: Colors.accentStrong
            connect: true
            onSelectedChanged: {
                date_tk.date = new Date();
                date_tk.offset = 0;
                // screentime.preUpdate();
                date_tk.update();
            }

            RowLayout {
                id: date_tk

                spacing: 0
                x: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                // Date state tracking
                property var date: new Date()
                property int offset: 0 // Track step distance relative to current period (0 = current)

                signal preUpdate
                signal update

                // Helper function to update target date based on tab mode and offset increment
                function shiftDate(delta) {
                    let newOffset = date_tk.offset + delta;
                    let targetDate = new Date();

                    if (date_range.selected === 0) {
                        targetDate.setDate(targetDate.getDate() + newOffset);
                    } else if (date_range.selected === 1) {
                        targetDate.setDate(targetDate.getDate() + (newOffset * 7));
                    } else if (date_range.selected === 2) {
                        targetDate.setMonth(targetDate.getMonth() + newOffset);
                    }

                    preUpdate();
                    date_tk.offset = newOffset;
                    date_tk.date = targetDate;
                    update();
                }

                CellButton {
                    text: "<"
                    color: ["transparent", Colors.bgOverlay, Colors.fgBase]
                    fg: [Colors.fgBase, Colors.bgSurface]
                    font: Cell.fontBB
                    onPressed: button => {
                        if (button === "L") {
                            date_tk.shiftDate(-1);
                        }
                    }
                }

                CellText {
                    id: date_text
                    preferedW: 19
                    centered: true
                    font: Cell.fontB

                    // Formats display dynamically based on mode and offset distance
                    text: {
                        let range = date_range.selected;
                        let off = date_tk.offset;
                        let d = date_tk.date;

                        if (range === 0) { // Daily Mode
                            if (off === 0)
                                return "Today";
                            if (off === -1)
                                return "Yesterday";
                            return DateTime.dayNumToShort(d.getDay()) + ", " + d.getDate() + " " + DateTime.monthNumToShort(d.getMonth() + 1) + ", " + d.getFullYear();
                        } else if (range === 1) { // Weekly Mode
                            if (off === 0)
                                return "This week";
                            if (off === -1)
                                return "Last week";
                            return Math.abs(off) + " weeks ago";
                        } else if (range === 2) { // Monthly Mode
                            if (off === 0)
                                return "This month";
                            if (off === -1)
                                return "Last month";
                            return d.getFullYear() === (new Date()).getFullYear() ? DateTime.monthNumToShort(d.getMonth() + 1) : DateTime.monthNumToShort(d.getMonth() + 1) + " " + d.getFullYear();
                        }
                        return "";
                    }
                }

                CellButton {
                    text: ">"
                    // Block navigation into future ranges (offset >= 0)
                    readonly property bool isCurrent: date_tk.offset >= 0

                    clickable: !isCurrent
                    color: clickable ? ["transparent", Colors.bgOverlay, Colors.fgBase] : "transparent"
                    fg: clickable ? [Colors.fgBase, Colors.bgSurface] : Colors.fgSubtle
                    font: Cell.fontBB
                    onPressed: button => {
                        if (button === "L" && clickable) {
                            date_tk.shiftDate(1);
                        }
                    }
                }
            }

            // CellSeparator {
            //     vertical: true
            //     h: 1
            //     bg: "transparent"
            //     // connectStart: true
            //     // connectEnd: true
            //     // color: Colors.accentStrong
            //     color: Colors.bgOverlay
            // }

            CellDropdown {
                id: mode
                x: parent.implicitWidth - Cell.w(w) - Cell.w(1)
                w: 20
                text: ""
                items: [
                    {
                        label: "Screen Time"
                    },
                    {
                        label: "Performance"
                    },
                ]

                onActivated: index => {
                    selected = index;
                }
            }
        }

        Loader {
            active: mode.selected == 0
            sourceComponent: ScreenTime {
                id: screentime
                Connections {
                    target: date_tk
                    function onPreUpdate() {
                        screentime.preUpdate();
                    }
                    function onUpdate() {
                        screentime.update();
                    }
                }
                onDisabledChanged: {
                    date_range.screentime_disabled = disabled;
                }
                visible: mode.selected == 0
                w: top_screentime.w
                h: root.box.contentH - 19
                date: date_tk.date
                date_offset: date_tk.offset
                range: date_range.selected
                onRangeSelect: i => {
                    date_range.select(i);
                }
            }
        }

        Loader {
            active: mode.selected == 1
            sourceComponent: Performance {}
        }
    }

    component Header: CellSeparator {

        property string text: "CPU"

        w: root.box.eW
        type: 2
        padding: 1
        title {
            text: text
            centered: false
            font: Cell.fontBB
            color: root.box.head
        }
        color: Colors.accentDim
    }
}
