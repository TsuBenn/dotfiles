pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 0

    property var disabled: mode.selected == 0 ? [1, 2] : []
    property var date
    property int w
    property int h
    property int date_offset
    property int range
    property bool todayOnly: mode.selected == 0

    function getGradientColor(baseColor, value, minVal, midVal, maxVal) {
        if (value <= minVal)
            return Colors.fgBase;
        if (value >= maxVal)
            return Colors.danger;

        if (value < midVal) {
            // Interpolate between fgBase and warning
            let factor = (value - minVal) / (midVal - minVal);
            return Colors.blend(baseColor, Colors.warning, factor);
        } else {
            // Interpolate between warning and danger
            let factor = (value - midVal) / (maxVal - midVal);
            return Colors.blend(Colors.warning, Colors.danger, factor);
        }
    }

    Timer {
        id: timer
        running: root.visible
        interval: SystemInfo.polling_time
        repeat: true
        triggeredOnStart: true
        property int prev_length: 0
        onTriggered: {
            if (mode.selected == 0) {
                ProcessInfo.getRealTimeTicks(d => {
                    realtime.model = d;
                    root.update();
                // console.log(JSON.stringify(d));
                });
            }
        }
    }

    function update() {
        if (realtime.selected == 0) {
            switch (cat.selected) {
            case 0:
                realtime.process_model = ProcessInfo.getSortedCPU();
                break;
            case 1:
                realtime.process_model = ProcessInfo.getSortedRAM();
                break;
            case 2:
                realtime.process_model = ProcessInfo.getSortedSM();
                break;
            case 3:
                realtime.process_model = ProcessInfo.getSortedVRAM();
                break;
            }
        } else {
            ProcessInfo.getProcessTicks(realtime.selected, d => {
                // realtime.process_model = d;
                switch (cat.selected) {
                case 0:
                    realtime.process_model = d.sort((a, b) => b.cpu_pct - a.cpu_pct);
                    break;
                case 1:
                    realtime.process_model = d.sort((a, b) => b.ram_mb - a.ram_mb);
                    break;
                case 2:
                    realtime.process_model = d.sort((a, b) => b.sm_pct - a.sm_pct);
                    break;
                case 3:
                    realtime.process_model = d.sort((a, b) => b.mem_pct - a.mem_pct);
                    break;
                case 4:
                    realtime.process_model = d.sort((a, b) => b.enc_pct - a.enc_pct);
                    break;
                case 5:
                    realtime.process_model = d.sort((a, b) => b.dec_pct - a.dec_pct);
                    break;
                case 6:
                    realtime.process_model = d.sort((a, b) => b.vram_mb - a.vram_mb);
                    break;
                }
            });
        }
        if (realtime.offset != 0 & timer.prev_length < realtime.model.length)
            realtime.advance(1);
        timer.prev_length = realtime.model.length;
    }

    RowLayout {
        spacing: 0
        CellTabs {
            id: mode
            w: root.w - cat.w
            items: ["Real-time", "Events"]
            disabled: root.range == 0 ? [] : [0]
            distributed: false
            padding: 0
            centered: false
            spacing: 0
            offset: 1
        }
        CellTabs {
            id: cat
            onSelectedChanged: {
                timer.restart();
                realtime.selected = 0;
            }
            w: mode.selected == 0 ? 38 : 0
            items: mode.selected == 0 ? ["CPU", "RAM", "SMP", "MEM", "ENC", "DEC", "VRAM"] : []
            disabled: root.range == 0 ? [] : [0]
            distributed: false
            padding: 0
            centered: false
            spacing: 0
            offset: 1
        }
    }

    RowLayout {
        id: realtime
        visible: mode.selected == 0
        spacing: 0

        property var model: [] // Holds the realtime data

        property var process_model: []

        property int offset: 0

        property int maxOffset: Math.max(model.length - (root.w - 24), 0)

        property var selected: 0 // Selected timestamp
        property var selected_index: 0 // Selected index

        onSelectedChanged: {
            root.update();
        }

        signal requestSelect

        property string key: {
            switch (cat.selected) {
            case 0:
                return "cpu_pct";
            case 1:
                return "ram_mb";
            case 2:
                return "sm_pct";
            case 3:
                return "mem_pct";
            case 4:
                return "enc_pct";
            case 5:
                return "dec_pct";
            case 6:
                return "vram_mb";
            }
        }

        function advance(delta) {
            offset = Math.max(0, Math.min(offset + delta, realtime.maxOffset));
        }
        ColumnLayout {
            spacing: 0
            CellScrollList {
                id: realtime_list

                w: 30
                h: root.h - 4

                model: realtime.process_model

                delegate: Cells {
                    id: realtime_process
                    property var modelData
                    w: realtime_list.contentW
                    h: 1
                    color: "transparent"

                    property string key: realtime.key

                    property real value: {
                        switch (realtime.key) {
                        case "ram_mb":
                            return (realtime_process.modelData?.[realtime.key] / SystemInfo.ktoM(SystemInfo.memtotal)) * 100;
                        case "vram_mb":
                            return (realtime_process.modelData?.[realtime.key] / SystemInfo.ktoM(SystemInfo.gpumemtotal) * 100);
                        default:
                            return (realtime_process.modelData?.[realtime.key]);
                        }
                    }

                    RowLayout {
                        spacing: Cell.w(1)
                        CellText {
                            text: " " + realtime_process.modelData.program
                            preferedW: realtime_list.contentW - 2 - realtime_process_usage.w
                            font: Cell.fontB
                        }

                        CellText {
                            id: realtime_process_usage
                            text: realtime_process.modelData[realtime_process.key].toFixed(1) + (realtime.key.includes("mb") ? "MB" : "%")
                            color: root.getGradientColor(Colors.fgBase, realtime_process.value, 0, 70, 90)
                            font: Cell.fontB
                        }
                    }
                }
            }
            CellSeparator {
                w: 30
                color: Colors.accentDim
            }

            RowLayout {
                Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)
                spacing: Cell.w(1)

                CellText {
                    text: realtime.selected == 0 ? "Real-time" : DateTime.formatTimestamp(realtime.selected, 3)
                    font: Cell.fontB
                    color: Colors.secondary
                    centered: true
                    preferedW: 18
                }

                CellButton {
                    visible: clickable
                    text: "Return"
                    clickable: realtime.selected != 0
                    color: clickable ? [Colors.bgOverlay, Colors.fgBase] : Colors.bgOverlay
                    fg: clickable ? [Colors.fgBase, Colors.bgSurface] : Colors.fgSubtle
                    onReleased: button => {
                        if (button == "L")
                            realtime.selected = 0;
                    }
                }
            }
        }

        CellSeparator {
            h: root.h - 2
            vertical: true
            color: Colors.bgOverlay
            bg: "transparent"
            connectStart: true
            connectEnd: true
        }

        Cells {
            id: real_time_chart
            w: root.w - 32
            h: root.h - 2
            color: "transparent"

            ColumnLayout {
                spacing: 0
                RowLayout {
                    spacing: 0
                    layoutDirection: Qt.RightToLeft

                    clip: true

                    Repeater {
                        model: real_time_chart.w
                        delegate: Cells {
                            id: real_time_col
                            required property int index
                            property var modelData: realtime.model[index + realtime.offset]

                            visible: modelData?.timestamp ?? false

                            property var timestamp: modelData?.timestamp ?? 1

                            property bool isMarked: Math.floor(timestamp / 1000) % 15 == 0 && timestamp != 0

                            Connections {
                                target: realtime
                                function onRequestSelect() {
                                    if (col_mouse.hovered) {
                                        if (realtime.selected == real_time_col.timestamp) {
                                            realtime.selected = 0;
                                            realtime.selected_index = 0;
                                        } else {
                                            realtime.selected = real_time_col.timestamp;
                                            realtime.selected_index = realtime_col.index + realtime.offset;
                                        }
                                    }
                                }
                            }

                            w: 1
                            h: root.h - 3

                            color: "transparent"

                            CellProgressSquare {
                                vertical: true
                                y: Cell.h(5)
                                w: 1
                                h: 1
                                percent: 7
                                type: 0
                                fg: Colors.bgOverlay
                                color: "transparent"
                            }

                            CellSeparator {
                                y: Cell.h(2)
                                visible: real_time_col.isMarked
                                h: real_time_col.h - 2
                                vertical: true
                                bg: "transparent"
                                connectStart: true
                                color: Colors.bgOverlay
                            }

                            CellSeparator {
                                y: Cell.h(1)
                                w: parent.w
                                bg: "transparent"
                                // connectStart: true
                                // connectEnd: true
                                color: Colors.bgOverlay
                            }

                            Cells {
                                anchors.bottom: parent.bottom
                                y: Cell.h(2)
                                w: parent.w
                                h: Math.ceil((parent.h - 1) * (real_time_usage.percent / 100))
                                color: Colors.bgSurface
                            }

                            Cells {
                                anchors.bottom: parent.bottom
                                w: parent.w
                                h: parent.h - 1.4
                                whole: false
                                color: realtime.selected == parent.timestamp ? Colors.accentDim : "transparent"
                            }

                            CellProgressSquare {
                                id: real_time_usage

                                property real value: {
                                    switch (realtime.key) {
                                    case "ram_mb":
                                        return ((real_time_col.modelData?.[realtime.key] ?? 0) / SystemInfo.ktoM(SystemInfo.memtotal)) * 100;
                                    case "vram_mb":
                                        return ((real_time_col.modelData?.[realtime.key] ?? 0) / SystemInfo.ktoM(SystemInfo.gpumemtotal) * 100);
                                    default:
                                        return (real_time_col.modelData?.[realtime.key] ?? 0);
                                    }
                                    return 0;
                                }

                                y: Cell.h(1)
                                w: parent.w
                                h: parent.h - 1
                                type: 0
                                vertical: true
                                percentSmoother: 0
                                percent: value * ((h - 0.5) / (h)) ?? 0
                                fg: realtime.selected == parent.timestamp ? Colors.fgBase : root.getGradientColor(Colors.secondary, percent, 0, 70, 90)
                                color: "transparent"
                            }

                            CellText {
                                visible: real_time_col.isMarked
                                x: Cell.centerWCell(implicitWidth, parent.implicitWidth)
                                text: DateTime.formatTimestamp(real_time_col.timestamp, 3)
                                color: Colors.fgSubtle
                                bg: Colors.bgSurface
                            }

                            HoverHandler {
                                id: col_mouse
                            }
                        }
                    }
                }

                // CellSeparator {
                //     w: real_time_chart.w
                //     type: 2
                //     bg: "transparent"
                //     connectStart: true
                //     connectEnd: true
                //     color: Colors.bgOverlay
                // }

                CellScrollBar {
                    onAdjusted: percent => {
                        realtime.offset = Math.max(0, Math.min(Math.floor(realtime.maxOffset * (1 - percent)), realtime.maxOffset));
                    }
                    w: real_time_chart.w
                    horizontal: true
                    contentH: realtime.model.length
                    progress: realtime.maxOffset > 0 ? 1 - (realtime.offset / realtime.maxOffset) : 0
                }
            }

            MouseControl {
                id: realtime_mouse
                anchors.fill: parent
                anchors.bottomMargin: Cell.h(1)
                propagateComposedEvents: true
                hoverEnabled: false
                property int oX
                property int oY
                property int oO
                property int nO
                onPressed: (button, event) => {
                    if (button == "L") {
                        oX = event.x;
                        oY = event.y;
                        oO = realtime.offset;
                        nO = realtime.offset;
                    }
                }
                onMoved: (x, y, event) => {
                    if (buttonDown == "L") {
                        realtime.offset = Math.min(Math.max(oO + Cell.wCount(x - oX), 0), realtime.maxOffset);
                        nO = oO + Cell.wCount(x - oX);
                    }
                }
                onReleased: (button, event) => {
                    if (button == "L" && oO == nO) {
                        realtime.requestSelect();
                    }
                }
                onWheel: (delta, event) => {
                    realtime.advance(event.modifiers & Qt.ControlModifier ? delta : delta * 10);
                    event.accepted = false;
                }
            }
        }

        CellSeparator {
            h: root.h - 4
            vertical: true
            color: Colors.bgOverlay

            bg: "transparent"
            connectStart: true
            connectEnd: true
        }
    }
}
