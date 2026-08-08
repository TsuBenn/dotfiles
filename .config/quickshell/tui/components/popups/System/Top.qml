pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root
    spacing: 0

    Repeater {
        model: 3

        delegate: RowLayout {
            id: top
            required property int index
            spacing: 0
            Cells {
                id: top_cell
                w: 27
                h: 10
                color: "transparent"

                ColumnLayout {
                    spacing: 0

                    RowLayout {
                        spacing: 0
                        CellText {
                            text: {
                                switch (top.index) {
                                case 0:
                                    return "TOP CPU";
                                case 1:
                                    return "TOP MEMORY";
                                case 2:
                                    return "TOP GPU";
                                }
                                return "";
                            }
                            color: Colors.fgBase
                            font: Cell.fontB
                            preferedW: top_cell.w
                            centered: true
                        }
                    }

                    CellSeparator {
                        w: top_cell.w
                        color: Colors.accentStrong
                        bg: "transparent"
                        connectStart: true
                        connectEnd: true
                    }

                    CellTabs {
                        id: top_selected
                        items: {
                            switch (top.index) {
                            case 0:
                                return ["Per core", "All cores"];
                            case 1:
                                return ["RAM", "VRAM"];
                            case 2:
                                return ["SM", "MEM", "ENC", "DEC"];
                            }
                            return [];
                        }
                        w: top_cell.w
                        distributed: false
                        offset: 1
                        spacing: 0
                        onSelectedChanged: {
                            top_list.update();
                        }
                    }

                    CellScrollList {
                        id: top_list
                        h: top_cell.h - 4
                        w: top_cell.w
                        scrollbar.enabled: model.length * itemH > h

                        Component.onCompleted: {
                            update();
                        }

                        onVisibleChanged: {
                            update();
                        }

                        Connections {
                            target: ProcessInfo
                            function onUpdated() {
                                top_list.update();
                            }
                        }

                        function update() {
                            if (!root.visible)
                                return;
                            model = (() => {
                                    switch (top.index) {
                                    case 0:
                                        return ProcessInfo.getSortedCPU();
                                    case 1:
                                        return top_selected.selected == 0 ? ProcessInfo.getSortedRAM() : ProcessInfo.getSortedVRAM();
                                    case 2:
                                        switch (top_selected.selected) {
                                        case 0:
                                            return ProcessInfo.getSortedSM();
                                        case 1:
                                            return ProcessInfo.getSortedMEM();
                                        case 2:
                                            return ProcessInfo.getSortedENC();
                                        case 3:
                                            return ProcessInfo.getSortedDEC();
                                        }
                                    }
                                    return [];
                                })();
                        }

                        model: []

                        delegate: Cells {
                            property var modelData
                            property var index
                            w: top_list.contentW
                            h: 1
                            color: "transparent"
                            RowLayout {
                                property var modelData: parent.modelData

                                spacing: Cell.w(1)

                                CellText {
                                    text: " " + parent.modelData.program
                                    preferedW: top_cell.w - 3 - top_usage.w
                                    color: top_usage.color
                                    font: color == Colors.fgBase ? Cell.font : Cell.fontB
                                }

                                CellText {
                                    id: top_usage

                                    function getGradientColor(value, minVal, midVal, maxVal) {
                                        if (value <= minVal)
                                            return Colors.fgBase;
                                        if (value >= maxVal)
                                            return Colors.danger;

                                        if (value < midVal) {
                                            // Interpolate between fgBase and warning
                                            let factor = (value - minVal) / (midVal - minVal);
                                            return Colors.blend(Colors.fgBase, Colors.warning, factor);
                                        } else {
                                            // Interpolate between warning and danger
                                            let factor = (value - midVal) / (maxVal - midVal);
                                            return Colors.blend(Colors.warning, Colors.danger, factor);
                                        }
                                    }

                                    property real value: {
                                        switch (top.index) {
                                        case 0:
                                            return (parent.modelData.cpu_pct / (top_selected.selected == 1 ? SystemInfo.cputhreads : 1)).toFixed(1);
                                        case 1:
                                            switch (top_selected.selected) {
                                            case 0:
                                                return parent.modelData.ram_mb.toFixed(1);
                                            case 1:
                                                return parent.modelData.vram_mb.toFixed(1);
                                            }
                                        case 2:
                                            switch (top_selected.selected) {
                                            case 0:
                                                return parent.modelData.sm_pct.toFixed(1);
                                            case 1:
                                                return parent.modelData.mem_pct.toFixed(1);
                                            case 2:
                                                return parent.modelData.enc_pct.toFixed(1);
                                            case 3:
                                                return parent.modelData.dec_pct.toFixed(1);
                                            }
                                        }
                                        return 0;
                                    }
                                    text: value + (top.index == 1 ? "MB" : "%")
                                    color: {
                                        if (top.index === 1) { // MEMORY
                                            let total = (top_selected.selected === 0) ? SystemInfo.ktoM(SystemInfo.memtotal) : SystemInfo.ktoM(SystemInfo.gpumemtotal);

                                            let used = (top_selected.selected === 0) ? parent.modelData.ram_mb : parent.modelData.vram_mb;

                                            // Multiply by 100 to get percentage 0-100
                                            let pct = (total > 0) ? (used / total) * 100 : 0;

                                            // Smooth transition: 0% (fgBase) -> 30% (warning) -> 50% (danger)
                                            return getGradientColor(pct, 0, (top_selected.selected === 0 ? 15 : 25), (top_selected.selected === 0 ? 30 : 50));
                                        } else if (top.index === 0) { // CPU
                                            let threads = SystemInfo.cputhreads;
                                            if (top_selected.selected === 0) { // CPU per core
                                                // Smooth transition: 0 -> 100/threads (warning) -> 50*threads (danger)
                                                return getGradientColor(value, 0, 80, 30 * threads);
                                            } else { // CPU all cores
                                                // Smooth transition: 0% -> 60% (warning) -> 80% (danger)
                                                return getGradientColor(value, 0, 20, 40);
                                            }
                                        } else { // GPU
                                            // Smooth transition: 0% -> 60% (warning) -> 80% (danger)
                                            switch (top_selected.selected) {
                                            case 0:
                                                return getGradientColor(value, 0, 45, 80);
                                            case 1:
                                                return getGradientColor(value, 0, 45, 80);
                                            case 2:
                                                return getGradientColor(value, 0, 30, 60);
                                            case 3:
                                                return getGradientColor(value, 0, 30, 60);
                                            }
                                        }
                                    }
                                    font: Cell.fontB
                                }
                            }
                        }
                    }
                }
            }

            CellSeparator {
                visible: parent.index != 2
                vertical: true
                h: 10
                color: Colors.accentStrong
                bg: "transparent"
                connectEnd: true
                connectStart: true
            }
        }
    }
}
