pragma ComponentBehavior: Bound

import qs.components.popups.System

import qs.config
import qs.services
import qs.modules

import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root

    property int w
    property int h

    spacing: 0

    Timer {
        id: screentime_timer
        running: root.visible && !SystemInfo.idle
        interval: SettingsInfo.systemPolling
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            let sessions = [];
            if (screentime_range.selected == 0) {
                sessions = ScreenTimeInfo.getDaySessions(date_tk.date.getFullYear(), date_tk.date.getMonth() + 1, date_tk.date.getDate());
            } else if (screentime_range.selected == 1) {
                sessions = ScreenTimeInfo.getWeekSessions(date_tk.date.getFullYear(), date_tk.date.getMonth() + 1, date_tk.date.getDate());
            } else if (screentime_range.selected == 2) {
                sessions = ScreenTimeInfo.getMonthSessions(date_tk.date.getFullYear(), date_tk.date.getMonth() + 1);
            }

            total_screentime.text = ScreenTimeInfo.formatDuration(ScreenTimeInfo.getTotalScreenTime(sessions));
            avg_screentime.text = ScreenTimeInfo.formatDuration(ScreenTimeInfo.getAverageScreenTime(sessions, screentime_range.selected, date_tk.date));

            if (screentime_mode.selected == 0)
                screentime_list.model = ScreenTimeInfo.normalizeSessions(sessions);
            else if (screentime_mode.selected == 1) {
                screentime_dist_list.model = ScreenTimeInfo.normalizeSessions(sessions);
                // screentime_dist.model and .maxDuration are declarative bindings now (see below) —
                // they recalc themselves automatically once screentime_dist_list.model changes above.
                // No manual assignment needed here anymore.
            } else if (screentime_mode.selected == 2 && screentime_range.selected == 0) {
                screentime_timeline_list.model = ScreenTimeInfo.getDayTimelineByApp(date_tk.date);
                screentime_timeline.startMs = ScreenTimeInfo.getDayStartMs(date_tk.date);
                screentime_timeline.endMs = ScreenTimeInfo.getDayEndMs(date_tk.date);
                screentime_timeline.currentTime_offset = Math.floor(screentime_timeline.timeline_w * ((Date.now() - screentime_timeline.startMs) / screentime_timeline.dayMs));
            }
        }
    }

    RowLayout {
        id: date_tk

        spacing: 0
        Layout.leftMargin: Cell.w(1)

        // Date state tracking
        property var date: new Date()
        property int offset: 0 // Track step distance relative to current period (0 = current)

        onDateChanged: screentime_timer.restart()

        // Helper function to update target date based on tab mode and offset increment
        function shiftDate(delta) {
            let newOffset = date_tk.offset + delta;
            let targetDate = new Date(); // Start calculations relative to today

            if (screentime_range.selected === 0) {
                // Daily shifting
                targetDate.setDate(targetDate.getDate() + newOffset);
            } else if (screentime_range.selected === 1) {
                // Weekly shifting (7 days per step)
                targetDate.setDate(targetDate.getDate() + (newOffset * 7));
            } else if (screentime_range.selected === 2) {
                // Monthly shifting
                targetDate.setMonth(targetDate.getMonth() + newOffset);
            }

            date_tk.offset = newOffset;
            date_tk.date = targetDate;
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
            preferedW: 18
            centered: true
            font: Cell.fontB

            // Formats display dynamically based on mode and offset distance
            text: {
                let range = screentime_range.selected;
                let off = date_tk.offset;
                let d = date_tk.date;

                if (range === 0) { // Daily Mode
                    if (off === 0)
                        return "Today";
                    if (off === -1)
                        return "Yesterday";
                    return d.getDate() + " " + DateTime.monthNumToShort(d.getMonth() + 1) + ", " + d.getFullYear();
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

    CellSeparator {
        w: root.w
        color: Colors.accentDim
    }

    RowLayout {
        spacing: 0

        CellTabs {
            id: screentime_range

            property bool dayOnly: screentime_mode.selected == 2

            items: ["Day", "Week", "Month"]

            w: 43
            distributed: false
            disabled: dayOnly ? [1, 2] : []
            centered: false
            offset: 1
            spacing: 1
            padding: 0
            onSelectedChanged: {
                // Reset to current time when switching view granularity
                date_tk.offset = 0;
                date_tk.date = new Date();
                screentime_timer.restart();
            }
        }
        CellTabs {
            id: screentime_mode
            items: ["Most used", "Distribution", "Timeline"]
            w: root.w - screentime_range.w
            distributed: false
            disabled: screentime_range.selected != 0 ? [2] : []
            spacing: 1
            centered: false
            padding: 0
            offset: 2
            onSelectedChanged: {
                if (selected == 2)
                    screentime_range.selected = 0;
                screentime_timer.restart();
            }
        }
    }

    RowLayout {
        id: screentime

        property int h: root.h

        spacing: 0

        CellScrollList {
            id: screentime_list

            visible: screentime_mode.selected == 0

            h: screentime.h
            w: root.w

            model: []

            property int maxDuration: model.length ? Math.max(...model.map(s => s.duration)) : 1

            itemH: 2

            Cells {
                visible: parent.model.length == 0
                w: parent.w
                h: parent.h
                color: "transparent"
                CellText {
                    x: Cell.centerHCell(implicitWidth, parent.implicitWidth)
                    y: Cell.centerHCell(implicitHeight, parent.implicitHeight)
                    text: {
                        let text = "day";
                        if (screentime_range.selected == 1) {
                            text = "week";
                        } else if (screentime_range.selected == 2) {
                            text = "month";
                        }
                        return "No data for this " + text;
                    }
                    color: Colors.fgSubtle
                }
            }

            delegate: ColumnLayout {
                id: screentime_bar

                property var modelData
                spacing: 0

                RowLayout {

                    spacing: Cell.w(1)

                    CellIcon {
                        Layout.leftMargin: Cell.w(1)
                        w: 2
                        h: 1
                        hideOnFail: false
                        icon: [screentime_bar.modelData.name, screentime_bar.modelData.app_class]
                    }

                    CellText {
                        id: screentime_app
                        text: screentime_bar.modelData.name ?? ""
                        font: Cell.fontB
                        color: Colors.fgBase
                        preferedW: 20
                    }

                    CellProgressSquare {
                        id: screentime_progress
                        percent: (screentime_bar.modelData.duration / screentime_list.maxDuration) * 100
                        w: screentime_list.w - screentime_app.w - 15
                        fg: Colors.secondary
                        percentSmoother: 0
                    }

                    CellText {
                        Layout.leftMargin: Cell.w(1)
                        text: ScreenTimeInfo.formatDuration(screentime_bar.modelData.duration)
                        font: Cell.fontB
                        preferedW: 6
                        alignRight: true
                    }
                }

                CellSeparator {
                    w: screentime_list.w
                    color: Colors.bgOverlay
                }
            }
        }

        RowLayout {
            id: screentime_dist
            visible: screentime_mode.selected == 1
            spacing: 0

            property int selected: -1

            property var model: {
                const app_class = screentime_dist.selected == -1 ? "all" : screentime_dist_list.model[screentime_dist.selected]?.app_class;
                if (!app_class)
                    return [];

                if (screentime_range.selected === 0) {
                    // Day mode -> hourly buckets (2h chunks)
                    return ScreenTimeInfo.getAppDayBuckets(app_class, date_tk.date, 4);
                } else if (screentime_range.selected === 2) {
                    // Month mode -> W1..W5 buckets
                    return ScreenTimeInfo.getAppMonthlyWeeks(app_class, date_tk.date.getFullYear(), date_tk.date.getMonth() + 1);
                }

                // Week mode -> Mon..Sun buckets
                return ScreenTimeInfo.getAppWeeklyDays(app_class, date_tk.date);
            }

            // onModelChanged: {
            //     console.log(JSON.stringify(model, null, 2));
            // }

            property int maxDuration: ScreenTimeInfo.calculateTimeDivisions(screentime_dist.model, 4).axisMaxSeconds

            onSelectedChanged: {
                screentime_timer.restart();
            }

            CellScrollList {
                id: screentime_dist_list
                h: screentime.h
                w: 26
                model: []

                onModelChanged: {
                    if (model.length - 1 < parent.selected) {
                        parent.selected = 0;
                    }
                }

                itemH: 2

                scrollbar.enabled: model.length * itemH > h

                CellText {
                    x: Cell.centerWCell(implicitWidth, parent.implicitWidth)
                    y: Cell.centerHCell(implicitHeight, parent.implicitHeight)
                    visible: parent.model.length == 0
                    text: "No apps data"
                    color: Colors.fgSubtle
                    // preferedW: parent.contentW
                    // centered: true
                }

                delegate: ColumnLayout {
                    id: screentime_dist_item

                    spacing: 0

                    property int index
                    property var modelData

                    property bool selected: screentime_dist.selected == index

                    CellButton {
                        w: screentime_dist_list.contentW
                        h: 1
                        centered: false
                        text: "   " + (parent.modelData.name ?? "")
                        font: Cell.fontB
                        color: parent.selected ? Colors.accentStrong : ["transparent", Colors.bgOverlay, Colors.bgOverlay]
                        fg: parent.selected ? Colors.onAccent : Colors.fgBase
                        onPressed: button => {
                            if (parent.selected) {
                                screentime_dist.selected = -1;
                                return;
                            }
                            screentime_dist.selected = parent.index;
                        }

                        CellIcon {
                            x: Cell.w(1)
                            w: 2
                            h: 1
                            hideOnFail: false
                            icon: screentime_dist_item.modelData.app_class == "all" ? "" : [screentime_dist_item.modelData.app_class, screentime_dist_item.modelData.name]
                        }
                    }

                    CellSeparator {
                        w: screentime_dist_list.contentW
                        color: Colors.bgOverlay
                    }
                }
            }

            CellSeparator {
                vertical: true
                h: screentime.h
                color: Colors.bgOverlay
                bg: "transparent"
                connectStart: true
                connectEnd: true
            }

            Cells {
                visible: screentime_dist.model.length == 0
                w: 56
                h: screentime.h

                color: "transparent"

                CellText {
                    y: Cell.centerHCell(implicitHeight, parent.implicitHeight)
                    x: Cell.centerWCell(implicitWidth, parent.implicitWidth)
                    text: {
                        let text = "day";
                        if (screentime_range.selected == 1) {
                            text = "week";
                        } else if (screentime_range.selected == 2) {
                            text = "month";
                        }
                        return "No data for this " + text;
                    }
                    color: Colors.fgSubtle
                }
            }

            RowLayout {
                visible: screentime_dist.model.length > 0
                Layout.leftMargin: Cell.w(1)

                spacing: 0

                // CellText {
                //     text: " "
                // }

                CellSeparator {
                    Layout.alignment: Qt.AlignBottom
                    vertical: true
                    h: screentime.h - 1
                    color: Colors.bgOverlay
                    bg: "transparent"
                    connectStart: true
                }

                Repeater {
                    id: dist_days
                    model: screentime_dist.model?.length ?? 0

                    delegate: RowLayout {
                        id: dist_day
                        Layout.alignment: Qt.AlignBottom
                        required property int index
                        required property var modelData

                        property int w: {
                            if (screentime_range.selected == 2) {
                                return 8;
                            } else if (screentime_range.selected == 1) {
                                return 6;
                            } else {
                                return 7;
                            }
                        }
                        spacing: 0
                        ColumnLayout {

                            Layout.alignment: Qt.AlignBottom

                            spacing: 0

                            Cells {
                                w: 6
                                h: screentime.h - 2
                                color: "transparent"

                                ColumnLayout {
                                    anchors.top: parent.top
                                    spacing: Cell.h(1)
                                    Repeater {
                                        model: 5
                                        delegate: CellSeparator {
                                            w: dist_day.w
                                            color: Colors.bgOverlay
                                            bg: "transparent"
                                            connectStart: true
                                            connectEnd: true
                                        }
                                    }
                                }

                                CellProgressSquare {
                                    id: dist_bar
                                    anchors.bottom: parent.bottom
                                    x: Cell.w(1)
                                    h: parent.h
                                    w: dist_day.w - 2
                                    fg: dist_bar_mouse.hovered ? Colors.info : Colors.secondary
                                    color: "transparent"
                                    type: 0
                                    vertical: true
                                    percent: (screentime_dist.model[dist_day.index].duration / screentime_dist.maxDuration) * (750 / 8)
                                    percentSmoother: 0
                                    HoverHandler {
                                        id: dist_bar_mouse
                                        onHoveredChanged: {
                                            if (hovered && screentime_dist.model[dist_day.index].duration > 0) {
                                                timeline_status.name = screentime_dist.selected == -1 ? "All" : screentime_dist_list.model[screentime_dist.selected]?.name;
                                                timeline_status.time = ScreenTimeInfo.formatDuration(screentime_dist.model[dist_day.index].duration);
                                                const d = screentime_dist.model[dist_day.index]?.day ?? "";
                                                timeline_status.status = "(" + (screentime_range.selected === 1 ? d.slice(0, 2).toUpperCase() : d) + ")";
                                            }
                                        }
                                    }
                                }
                            }

                            CellSeparator {
                                w: dist_day.w
                                color: Colors.bgOverlay
                                bg: "transparent"
                                connectStart: true
                                connectEnd: true
                            }

                            CellText {
                                text: {
                                    const d = screentime_dist.model[dist_day.index]?.day ?? "";
                                    return screentime_range.selected === 1 ? d.slice(0, 2).toUpperCase() : d;
                                }
                                color: Colors.bgOverlay
                                font: Cell.fontB
                                preferedW: dist_day.w
                                centered: true
                            }
                        }

                        CellSeparator {
                            visible: screentime_dist.model.length > 0
                            Layout.alignment: Qt.AlignBottom
                            vertical: true
                            h: screentime.h - 1
                            color: Colors.bgOverlay
                            bg: "transparent"
                            connectStart: true
                        }
                    }
                }
                CellText {
                    text: " "
                }
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    spacing: Cell.h(1)
                    Repeater {
                        model: 4
                        delegate: CellText {
                            required property int index
                            opacity: (index == 0 || index == 2) && (text.length <= 3 || text.includes("d"))
                            text: ScreenTimeInfo.formatDuration(screentime_dist.maxDuration * ((4 - index) / 4))
                            color: Colors.fgSubtle
                            preferedW: {
                                if (text.includes("d")) {
                                    return 6;
                                }
                                return 3;
                            }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            id: screentime_timeline
            visible: screentime_mode.selected == 2
            spacing: 0

            property int timeline_viewWidth: 58
            property int timeline_offset: 0
            property int timeline_maxOffset: timeline_w - timeline_viewWidth + 7
            property int timeline_scale: 0
            property int currentTime_offset: Math.floor(screentime_timeline.timeline_w * ((Date.now() - screentime_timeline.startMs) / screentime_timeline.dayMs))

            property int mergeIntensity: 2

            property var startMs: ScreenTimeInfo.getDayStartMs(date_tk.date)
            property var endMs: ScreenTimeInfo.getDayEndMs(date_tk.date)
            property var dayMs: endMs - startMs

            property int scaler: 2 + screentime_timeline.timeline_scale
            property int timeline_w: 24 * scaler

            onVisibleChanged: {
                if (visible) {
                    timeline_scale = 0;
                    focusToCurrentTime();
                    screentime_timeline.currentTime_offset = Math.floor(screentime_timeline.timeline_w * ((Date.now() - screentime_timeline.startMs) / screentime_timeline.dayMs));
                }
            }

            function focusToCurrentTime() {
                const currentMs = Date.now();

                // 1. Check if the selected date is actually today
                if (currentMs < startMs || currentMs > endMs) {
                    // Not today: default to the start of the day (or handle as preferred)
                    timeline_offset = 0;
                    return;
                }

                // 2. Determine how far along the day we are (0.0 to 1.0)
                const timeRatio = (currentMs - startMs) / dayMs;

                // 3. Find the exact cell position corresponding to the current time
                const currentTimePos = timeRatio * timeline_w;

                // 4. Center that position within the 60-cell viewport
                const viewWidth = timeline_viewWidth;
                const targetOffset = Math.floor(currentTimePos - (viewWidth / 2)) + 3;

                // 5. Clamp to valid scroll boundaries [0, timeline_maxOffset]
                timeline_offset = Math.max(0, Math.min(targetOffset, timeline_maxOffset));
            }

            function setScaleKeepFocus(newScale) {
                newScale = Math.max(Math.min(newScale, timeline_scaler.max), timeline_scaler.min);
                // 1. Calculate the current visual center (in cell units) on screen
                const viewWidth = timeline_viewWidth; // Your visible viewport cell width
                const currentCenterPos = timeline_offset + viewWidth / 2;

                // 2. Determine what percentage of the TOTAL timeline width this center represents (0.0 to 1.0)
                const centerRatio = currentCenterPos / timeline_w;

                // 3. Update the scale (this recalculates timeline_w automatically)
                timeline_scale = Math.max(0, newScale);

                // 4. Calculate where that center point lands in the NEW total width
                const newCenterPos = centerRatio * timeline_w;

                // 5. Shift offset back so that new center point aligns with the screen center
                const newOffset = Math.round(newCenterPos - (viewWidth / 2));

                // 6. Clamp to valid bounds (prevent scrolling past 0 or maxOffset)
                timeline_offset = Math.max(0, Math.min(newOffset, timeline_maxOffset));
            }

            onTimeline_maxOffsetChanged: {
                screentime_timeline.currentTime_offset = Math.floor(screentime_timeline.timeline_w * ((Date.now() - screentime_timeline.startMs) / screentime_timeline.dayMs));
                if (timeline_offset > timeline_maxOffset) {
                    timeline_offset = timeline_maxOffset;
                }
            }

            // -------------------------------------------------------------
            // 2. App Timeline Scroll List
            // -------------------------------------------------------------
            CellScrollList {
                id: screentime_timeline_list

                w: root.w
                // Subtract 2 units for the top header row + bottom scrollbar row
                h: screentime.h - 2

                // itemH: 2
                model: []

                Cells {
                    z: -2
                    x: Cell.w(root.w - screentime_timeline.timeline_viewWidth - 1)
                    w: screentime_timeline.timeline_viewWidth
                    h: screentime.h - 2
                    clip: true
                    color: "transparent"

                    RowLayout {

                        x: -Cell.w(screentime_timeline.timeline_offset) + Cell.w(3) + (screentime_timeline.timeline_scale == 0 ? Cell.w(1) : 0)

                        spacing: Cell.w(screentime_timeline.scaler - 1)

                        Repeater {
                            model: 25

                            delegate: CellSeparator {

                                readonly property int hourW: screentime_timeline.scaler

                                // Calculate interval step based on current scale width to prevent cramping.
                                // If hourW is tight (< 4 cells), skip indices (show every 2nd or 4th hour).
                                readonly property bool shouldShow: {
                                    if (hourW >= 7)
                                        return true;       // Show every hour when wide enough
                                    if (hourW >= 4)
                                        return index % 2 === 0; // Show every 2 hours when moderate
                                    return index % 4 === 0;             // Show every 4 hours when very cramped
                                }
                                required property int index

                                h: screentime_timeline_list.h

                                vertical: true
                                opacity: shouldShow ? 1 : 0.2
                                color: Colors.bgOverlay
                            }
                        }
                    }
                }

                Cells {
                    x: Cell.w(root.w - screentime_timeline.timeline_viewWidth - 1)
                    w: screentime_timeline.timeline_viewWidth
                    h: screentime.h - 2
                    clip: true
                    color: "transparent"

                    CellSeparator {
                        x: Cell.w(-screentime_timeline.timeline_offset + 3 + screentime_timeline.currentTime_offset + (screentime_timeline.timeline_scale == 0 ? 1 : 0))
                        h: screentime.h
                        vertical: true
                        type: 0
                        color: Colors.accentStrong
                        bg: "transparent"
                    }
                }

                CellSeparator {
                    x: Cell.w(root.w - screentime_timeline.timeline_viewWidth - 2)
                    h: screentime.h
                    vertical: true
                    color: Colors.bgOverlay
                    bg: "transparent"
                    connectStart: true
                    connectEnd: true
                }

                delegate: Cells {
                    id: app_timeline

                    property int index
                    property var modelData

                    w: root.w
                    h: screentime_timeline_list.itemH

                    color: "transparent"

                    ColumnLayout {

                        spacing: 0

                        RowLayout {
                            spacing: 0

                            Cells {
                                h: 1
                                w: root.w - screentime_timeline.timeline_viewWidth - 2
                                color: timeline_block_mouse.hovered ? Colors.accentStrong : "transparent"

                                RowLayout {
                                    x: Cell.w(1)

                                    spacing: Cell.w(1)

                                    CellIcon {
                                        w: 2
                                        h: 1
                                        hideOnFail: false
                                        icon: [app_timeline.modelData.app_class, app_timeline.modelData.name]
                                    }

                                    CellText {
                                        text: app_timeline.modelData.name
                                        font: Cell.fontB
                                        preferedW: root.w - screentime_timeline.timeline_viewWidth - 7
                                        color: timeline_block_mouse.hovered ? Colors.onAccent : Colors.fgBase
                                    }
                                }
                            }

                            CellText {
                                text: " "
                            }

                            Cells {
                                w: screentime_timeline.timeline_viewWidth
                                h: 1
                                color: timeline_block_mouse.hovered ? Qt.lighter(Colors.bgOverlay, 1.2) : "transparent"
                                clip: true

                                RowLayout {

                                    x: -Cell.w(screentime_timeline.timeline_offset) + Cell.w(3) + (screentime_timeline.timeline_scale == 0 ? Cell.w(1) : 0)

                                    spacing: Cell.w(screentime_timeline.scaler - 1)

                                    Repeater {
                                        model: 25

                                        delegate: CellSeparator {

                                            readonly property int hourW: screentime_timeline.scaler

                                            // Calculate interval step based on current scale width to prevent cramping.
                                            // If hourW is tight (< 4 cells), skip indices (show every 2nd or 4th hour).
                                            readonly property bool shouldShow: {
                                                if (hourW >= 7)
                                                    return true;       // Show every hour when wide enough
                                                if (hourW >= 4)
                                                    return index % 2 === 0; // Show every 2 hours when moderate
                                                return index % 4 === 0;             // Show every 4 hours when very cramped
                                            }
                                            required property int index

                                            h: 1

                                            vertical: true
                                            opacity: shouldShow ? 1 : 0.2
                                            color: Colors.bgOverlay
                                            bg: "transparent"
                                        }
                                    }
                                }

                                Cells {
                                    id: timeline_blocks
                                    x: -Cell.w(screentime_timeline.timeline_offset) + Cell.w(3) + (screentime_timeline.timeline_scale == 0 ? Cell.w(1) : 0)
                                    w: screentime_timeline.timeline_w
                                    h: 1
                                    color: "transparent"

                                    Repeater {
                                        model: ScreenTimeInfo.mergeAdjacentBlocks(app_timeline.modelData.blocks, (screentime_timeline.dayMs / screentime_timeline.timeline_w) + screentime_timeline.mergeIntensity * 5000)

                                        delegate: Item {
                                            id: timeline_block

                                            required property var modelData

                                            // Timestamps in float cell coordinates across the timeline
                                            // e.g., if a cell is 10 mins, 00:05 is cell 0.5
                                            readonly property real msPerCell: screentime_timeline.dayMs / screentime_timeline.timeline_w
                                            readonly property real startCellFloat: (modelData.start - screentime_timeline.startMs) / msPerCell
                                            readonly property real endCellFloat: (modelData.end - screentime_timeline.startMs) / msPerCell

                                            // Discrete cell indices
                                            readonly property int startCellIndex: Math.floor(startCellFloat)
                                            readonly property int endCellIndex: Math.floor(endCellFloat)

                                            // Total discrete cells spanned by this block
                                            readonly property int totalCellSpan: Math.max(1, (endCellIndex - startCellIndex) + 1)

                                            // Active usage density (0.0 to 1.0) inside the usage block itself
                                            readonly property real blockDensity: {
                                                const duration = modelData.end - modelData.start;
                                                const active = modelData.activeTime !== undefined ? modelData.activeTime : duration;
                                                return duration > 0 ? Math.min(1.0, Math.max(0.2, active / duration)) : 1.0;
                                            }

                                            // Position this block wrapper at its start cell index
                                            x: Cell.w(startCellIndex)
                                            width: Cell.w(totalCellSpan)
                                            height: Cell.h(1)

                                            RowLayout {
                                                anchors.fill: parent
                                                spacing: 0

                                                Repeater {
                                                    model: timeline_block.totalCellSpan

                                                    delegate: Cells {
                                                        required property int index

                                                        w: 1
                                                        h: 1
                                                        color: block_mouse.hovered ? Colors.info : Colors.secondary

                                                        // Calculate how much of THIS specific cell is covered by the block [0.0 to 1.0]
                                                        readonly property real cellCoverage: {
                                                            const globalCellIdx = timeline_block.startCellIndex + index;
                                                            const cellStart = globalCellIdx;
                                                            const cellEnd = globalCellIdx + 1;

                                                            // Find the overlap window between [cellStart, cellEnd] and [startCellFloat, endCellFloat]
                                                            const overlapStart = Math.max(cellStart, timeline_block.startCellFloat);
                                                            const overlapEnd = Math.min(cellEnd, timeline_block.endCellFloat);

                                                            return Math.max(0.0, overlapEnd - overlapStart);
                                                        }

                                                        // Opacity = (Fraction of cell covered) * (Overall usage density)
                                                        opacity: 0.2 + (cellCoverage * timeline_block.blockDensity) * 0.8
                                                    }
                                                }
                                            }

                                            HoverHandler {
                                                id: block_mouse

                                                onHoveredChanged: {
                                                    if (hovered) {
                                                        timeline_status.name = app_timeline.modelData.name + ":";
                                                        timeline_status.time = ScreenTimeInfo.formatTimestampToHHMM(timeline_block.modelData.start) + " - " + ScreenTimeInfo.formatTimestampToHHMM(timeline_block.modelData.end);
                                                        timeline_status.status = timeline_block.modelData.sessionCount > 1 ? "(Merged: " + timeline_block.modelData.sessionCount + ")" : "";
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // CellSeparator {
                        //     w: 20
                        //     color: Colors.bgOverlay
                        // }
                    }

                    HoverHandler {
                        id: timeline_block_mouse
                    }
                }

                Cells {
                    x: Cell.w(root.w - screentime_timeline.timeline_viewWidth - 1)
                    w: screentime_timeline.timeline_viewWidth
                    h: screentime.h - 1
                    color: "transparent"

                    MouseControl {
                        anchors.fill: parent

                        hoverEnabled: false

                        propagateComposedEvents: true

                        onWheel: (delta, event) => {
                            if (event.modifiers & Qt.ShiftModifier) {
                                screentime_timeline.timeline_offset = Math.max(Math.min(screentime_timeline.timeline_offset - delta * 2, screentime_timeline.timeline_maxOffset), 0);
                                event.accepted = true;
                                return;
                            } else if ((event.modifiers & Qt.ControlModifier)) {
                                screentime_timeline.setScaleKeepFocus(screentime_timeline.timeline_scale + delta);
                                event.accepted = true;
                                return;
                            }
                            event.accepted = false;
                        }
                    }
                }
            }

            // -------------------------------------------------------------
            // 1. Time Label Header Row (Static top row, scrolls horizontally)
            // -------------------------------------------------------------
            RowLayout {
                id: timeline_time_header
                spacing: Cell.w(1)

                // 20 cells for app name column + 1 cell for separator alignment
                CellSeparator {
                    w: root.w - screentime_timeline.timeline_viewWidth - 2
                    color: Colors.bgOverlay
                    bg: "transparent"
                    connectEnd: true
                }

                // Viewport (60 cells wide)
                Cells {
                    w: screentime_timeline.timeline_viewWidth
                    h: 1
                    color: "transparent"
                    clip: true

                    // Inner moving track tied to scrollbar offset
                    Cells {
                        x: -Cell.w(screentime_timeline.timeline_offset) + Cell.w(1) + (screentime_timeline.timeline_scale == 0 ? Cell.w(1) : 0)
                        w: screentime_timeline.timeline_w
                        h: 1
                        color: "transparent"

                        RowLayout {
                            anchors.fill: parent
                            spacing: 0

                            Repeater {
                                model: 25

                                delegate: Item {
                                    required property int index

                                    readonly property int hourW: screentime_timeline.scaler

                                    // Calculate interval step based on current scale width to prevent cramping.
                                    // If hourW is tight (< 4 cells), skip indices (show every 2nd or 4th hour).
                                    readonly property bool shouldShow: {
                                        if (hourW >= 8)
                                            return true;       // Show every hour when wide enough
                                        if (hourW >= 4)
                                            return index % 2 === 0; // Show every 2 hours when moderate
                                        return index % 4 === 0;             // Show every 4 hours when very cramped
                                    }

                                    implicitWidth: Cell.w(hourW)
                                    implicitHeight: Cell.h(1)

                                    CellText {
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        text: {
                                            const h = parent.index;
                                            return (h < 10 ? "0" + h : h) + ":00";
                                        }
                                        font: Cell.fontB
                                        color: Qt.lighter(Colors.bgOverlay, 1.5)
                                        // Hide the text instead of omitting the item entirely
                                        // so the grid spacing remains perfectly aligned.
                                        visible: parent.shouldShow
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // -------------------------------------------------------------
            // 3. ScrollBar Row
            // -------------------------------------------------------------
            RowLayout {
                spacing: Cell.w(1)

                Cells {
                    w: root.w - screentime_timeline.timeline_viewWidth - 2
                    h: 1
                    color: "transparent"

                    RowLayout {
                        id: timeline_scaler

                        spacing: 0

                        property int max: 40
                        property int min: 0

                        CellText {

                            text: " Scale: "
                            font: Cell.fontB
                            color: Colors.fgDim
                        }

                        CellButton {
                            text: "-"
                            color: ["transparent", Colors.bgOverlay, Colors.fgBase]
                            fg: [Colors.fgBase, Colors.bgSurface]
                            font: Cell.fontBB
                            onPressed: button => {
                                if (button === "L") {
                                    if (screentime_timeline.timeline_scale > parent.min) {
                                        screentime_timeline.setScaleKeepFocus(screentime_timeline.timeline_scale - 1);
                                    }
                                }
                            }
                        }

                        CellText {

                            text: screentime_timeline.timeline_scale
                            font: Cell.fontB
                            color: Colors.fgDim
                            preferedW: 9
                            centered: true
                        }

                        CellButton {
                            text: "+"
                            color: ["transparent", Colors.bgOverlay, Colors.fgBase]
                            fg: [Colors.fgBase, Colors.bgSurface]
                            font: Cell.fontBB
                            onPressed: button => {
                                if (button === "L") {
                                    if (screentime_timeline.timeline_scale < parent.max) {
                                        screentime_timeline.setScaleKeepFocus(screentime_timeline.timeline_scale + 1);
                                    }
                                }
                            }
                        }
                    }
                }

                CellScrollBar {
                    onAdjusted: percent => {
                        screentime_timeline.timeline_offset = Math.max(0, Math.min(Math.floor((screentime_timeline.timeline_maxOffset) * percent), screentime_timeline.timeline_maxOffset));
                    }
                    contentH: screentime_timeline.timeline_w
                    progress: screentime_timeline.timeline_maxOffset > 0 ? screentime_timeline.timeline_offset / screentime_timeline.timeline_maxOffset : 0
                    w: screentime_timeline.timeline_viewWidth
                    horizontal: true
                }
            }
        }
    }

    CellSeparator {
        w: root.w
        color: Colors.accentDim
    }

    Cells {
        w: root.w
        h: 1
        color: "transparent"
        RowLayout {

            anchors.left: parent.left

            spacing: 0

            CellText {
                text: " "
            }

            CellText {
                text: "Total Screen Time: "
                font: Cell.fontB
            }

            CellText {
                id: total_screentime
                text: ""
                font: Cell.fontB
                color: Colors.fgDim
            }
        }
        RowLayout {
            anchors.right: parent.right
            anchors.rightMargin: Cell.w(1)
            spacing: Cell.w(1)
            RowLayout {
                id: timeline_status

                visible: screentime_mode.selected != 0

                Connections {
                    target: screentime_mode
                    function onSelectedChanged() {
                        timeline_status.name = "";
                        timeline_status.time = "";
                        timeline_status.status = "";
                    }
                }

                onVisibleChanged: {
                    name = "";
                    time = "";
                    status = "";
                }

                property string name
                property string time
                property string status

                spacing: Cell.w(1)

                CellText {
                    text: parent.name
                    color: Colors.secondary
                    font: Cell.fontB
                }

                CellText {
                    text: parent.time
                    color: Colors.fgBase
                    font: Cell.fontB
                }

                CellText {
                    visible: text.length > 0
                    text: parent.status
                    color: Colors.info
                    font: Cell.fontB
                }
            }
            RowLayout {

                visible: screentime_range.selected !== 0 && screentime_mode.selected != 2

                spacing: 0

                CellText {
                    text: "Avg/Day: "
                    font: Cell.fontB
                }

                CellText {
                    id: avg_screentime
                    text: ""
                    font: Cell.fontB
                    color: Colors.fgDim
                }
            }
        }
    }
}
