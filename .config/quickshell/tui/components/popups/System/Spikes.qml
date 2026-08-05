pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 0

    property int w
    property var box

    property var log: [realtime_log, ...event_log]

    Connections {
        target: ProcessInfo
        function onSpiked(data) {
            root.event_log.push({
                type: "spike",
                data: {
                    program: data.program,
                    pid: data.pid,
                    startTime: data.startTime,
                    spikes: data.spikes,
                    severity: data.severity
                }
            });
        }
        function onSustainEnded(data) {
            root.event_log.push({
                type: "sustained",
                data: {
                    program: data.program,
                    pid: data.pid,
                    metrics: data.avg_metrics,
                    duration_ms: DateTime.getDuration(data.startTime)
                }
            });
        }
    }

    property var event_log: []
    property var realtime_log: {
        let raw = Object.values(ProcessInfo.sustained_data);
        let result = [];
        if (raw.length > 0) {
            result = raw.map(s => ({
                        program: s.program,
                        pid: s.pid,
                        gpu_type: ProcessInfo.name_process[s.program]?.gpu_type,
                        duration: Math.floor(DateTime.getDuration(s.startTime) / 1000),
                        metrics: s.metrics
                    }));
        }
        return {
            type: "high_usage",
            data: result
        };
    }

    CellText {
        text: "USAGE LOG"
        font: Cell.fontB
        color: Colors.secondary
        preferedW: root.w
        centered: true
    }

    CellSeparator {
        w: root.w
        color: Colors.accentStrong
        bg: "transparent"
        connectStart: true
        connectEnd: true
    }

    CellScrollView {
        id: list
        w: root.w
        h: root.box.contentH - 15

        source: ColumnLayout {
            spacing: 0

            Repeater {
                model: root.log

                delegate: Loader {
                    id: log_loader
                    required property var modelData

                    active: modelData.type == "high_usage" ? modelData.data.length > 0 : true

                    property Component high_usage: Component {

                        ColumnLayout {
                            id: hu

                            property var p: log_loader.modelData.data

                            spacing: 0

                            Repeater {
                                model: hu.p

                                delegate: ColumnLayout {
                                    id: hui

                                    required property int index
                                    required property var modelData

                                    property var metrics: Object.entries(modelData.metrics)

                                    spacing: 0

                                    RowLayout {
                                        spacing: 0

                                        CellText {
                                            text: ` ${hui.modelData.program} (${hui.modelData.pid.length == 1 ? hui.modelData.pid : hui.modelData.pid.length + " processes"})`
                                            font: Cell.fontB
                                            color: Colors.secondary
                                            preferedW: list.contentW - 1 - hui_duration.w
                                        }

                                        CellText {
                                            id: hui_duration
                                            text: DateTime.formatDuration(hui.modelData.duration)
                                            color: Colors.fgSubtle
                                        }
                                    }

                                    CellSeparator {
                                        w: list.contentW
                                        padding: 1
                                        color: Colors.bgOverlay
                                    }

                                    Repeater {
                                        model: parent.metrics

                                        delegate: RowLayout {
                                            required property int index
                                            required property var modelData
                                            spacing: 0

                                            property string unit: ""

                                            CellText {

                                                text: parent.index == 0 ? " HIGH USAGE:" : "            "
                                                color: Colors.danger
                                                font: Cell.fontB
                                            }

                                            CellText {
                                                text: {
                                                    switch (parent.modelData[0]) {
                                                    case "cpu":
                                                        parent.unit = "%";
                                                        return " CPU";
                                                    case "ram":
                                                        parent.unit = "MB";
                                                        return " RAM";
                                                    case "vram":
                                                        parent.unit = "MB";
                                                        return " VRAM";
                                                    case "sm":
                                                        parent.unit = "%";
                                                        let gpu_type = "";
                                                        switch (ProcessInfo.name_process[hui.modelData.program].gpu_type) {
                                                        case "G":
                                                            gpu_type = "GRAPHIC";
                                                            break;
                                                        case "C":
                                                            gpu_type = "COMPUTE";
                                                            break;
                                                        case "G+C":
                                                            gpu_type = "GFX+COMP";
                                                            break;
                                                        }
                                                        return ` GPU (${gpu_type})`;
                                                    case "mem":
                                                        parent.unit = "%";
                                                        return ` GPU (MEMORY)`;
                                                    case "enc":
                                                        parent.unit = "%";
                                                        return ` GPU (ENCODE)`;
                                                    case "dec":
                                                        parent.unit = "%";
                                                        return ` GPU (DECODE)`;
                                                    default:
                                                        " N/A";
                                                    }
                                                }
                                                preferedW: list.contentW - 13 - hui_met.w
                                                font: Cell.fontB
                                            }

                                            CellText {
                                                id: hui_met
                                                text: parent.modelData[1].toFixed(1) + " " + parent.unit
                                                color: Colors.warning
                                                font: Cell.fontB
                                            }
                                        }
                                    }

                                    CellSeparator {
                                        visible: hui.index < hu.p.length - 1
                                        w: list.contentW
                                        color: Colors.bgOverlay
                                    }
                                }
                            }
                            CellSeparator {
                                w: list.w
                                type: 2
                                color: Colors.bgOverlay
                            }
                        }
                    }

                    property Component sustained: Component {

                        ColumnLayout {
                            id: st
                            spacing: 0
                            property var p: log_loader.modelData.data

                            RowLayout {

                                spacing: 0

                                CellText {
                                    text: ` ${st.p.program} (${st.p.pid.length == 1 ? st.p.pid : st.p.pid.length + " processes"})`
                                    font: Cell.fontB
                                    color: Colors.secondary
                                    preferedW: list.contentW - 1 - st_ts.w
                                }

                                CellText {
                                    id: st_ts
                                    text: DateTime.formatDuration(st.p.duration_ms / 1000)
                                    color: Colors.fgSubtle
                                }
                            }

                            CellSeparator {
                                w: list.contentW
                                padding: 1
                                color: Colors.bgOverlay
                            }

                            ColumnLayout {
                                spacing: 0
                                Repeater {
                                    model: Object.entries(st.p.metrics)

                                    delegate: RowLayout {

                                        required property int index
                                        required property var modelData
                                        spacing: 0
                                        property string unit: ""

                                        CellText {

                                            text: parent.index == 0 ? " SUSTAINED:" : "           "
                                            color: Colors.info
                                            font: Cell.fontB
                                        }

                                        CellText {
                                            text: {
                                                switch (parent.modelData[0]) {
                                                case "cpu":
                                                    parent.unit = "%";
                                                    return " CPU";
                                                case "ram":
                                                    parent.unit = "MB";
                                                    return " RAM";
                                                case "vram":
                                                    parent.unit = "MB";
                                                    return " VRAM";
                                                case "sm":
                                                    parent.unit = "%";
                                                    let gpu_type = "";
                                                    switch (ProcessInfo.name_process[st.p.program].gpu_type) {
                                                    case "G":
                                                        gpu_type = "GRAPHIC";
                                                        break;
                                                    case "C":
                                                        gpu_type = "COMPUTE";
                                                        break;
                                                    case "G+C":
                                                        gpu_type = "GFX+COMP";
                                                        break;
                                                    }
                                                    return ` GPU (${gpu_type})`;
                                                case "mem":
                                                    parent.unit = "%";
                                                    return ` GPU (MEMORY)`;
                                                case "enc":
                                                    parent.unit = "%";
                                                    return ` GPU (ENCODE)`;
                                                case "dec":
                                                    parent.unit = "%";
                                                    return ` GPU (DECODE)`;
                                                default:
                                                    " N/A";
                                                }
                                            }
                                            preferedW: list.contentW - 12 - st_met.w
                                            font: Cell.fontB
                                        }

                                        CellText {
                                            id: st_met
                                            text: "~" + parent.modelData[1].toFixed(1) + " " + parent.unit
                                            font: Cell.fontB
                                        }
                                    }
                                }
                            }
                            CellSeparator {
                                w: list.w
                                type: 2
                                color: Colors.bgOverlay
                            }
                        }
                    }

                    property Component spike: Component {

                        ColumnLayout {
                            id: s
                            spacing: 0
                            property var p: log_loader.modelData.data

                            RowLayout {

                                spacing: 0

                                CellText {
                                    text: ` ${s.p.program} (${s.p.pid.length == 1 ? s.p.pid : s.p.pid.length + " processes"})`
                                    font: Cell.fontB
                                    color: Colors.secondary
                                    preferedW: list.contentW - 1 - s_ts.w
                                }

                                CellText {
                                    id: s_ts
                                    text: DateTime.formatTimestamp(s.p.startTime, 3)
                                    color: Colors.fgSubtle
                                }
                            }

                            CellSeparator {
                                w: list.contentW
                                padding: 1
                                color: Colors.bgOverlay
                            }

                            ColumnLayout {
                                spacing: 0
                                Repeater {
                                    model: Object.entries(s.p.spikes)

                                    delegate: RowLayout {

                                        required property int index
                                        required property var modelData
                                        spacing: 0
                                        property string unit: ""

                                        CellText {

                                            text: parent.index == 0 ? " SPIKED:" : "        "
                                            color: Colors.warning
                                            font: Cell.fontB
                                        }

                                        CellText {
                                            text: {
                                                switch (parent.modelData[0]) {
                                                case "cpu":
                                                    parent.unit = "%";
                                                    return " CPU";
                                                case "ram":
                                                    parent.unit = "MB";
                                                    return " RAM";
                                                case "vram":
                                                    parent.unit = "MB";
                                                    return " VRAM";
                                                case "sm":
                                                    parent.unit = "%";
                                                    let gpu_type = "";
                                                    switch (ProcessInfo.name_process[s.p.program].gpu_type) {
                                                    case "G":
                                                        gpu_type = "GRAPHIC";
                                                        break;
                                                    case "C":
                                                        gpu_type = "COMPUTE";
                                                        break;
                                                    case "G+C":
                                                        gpu_type = "GFX+COMP";
                                                        break;
                                                    }
                                                    return ` GPU (${gpu_type})`;
                                                case "mem":
                                                    parent.unit = "%";
                                                    return ` GPU (MEMORY)`;
                                                case "enc":
                                                    parent.unit = "%";
                                                    return ` GPU (ENCODE)`;
                                                case "dec":
                                                    parent.unit = "%";
                                                    return ` GPU (DECODE)`;
                                                default:
                                                    " N/A";
                                                }
                                            }
                                            preferedW: list.contentW - 9 - s_met.w
                                            font: Cell.fontB
                                        }

                                        CellText {
                                            id: s_met
                                            text: "+" + parent.modelData[1].toFixed(1) + " " + parent.unit
                                            color: {
                                                switch (s.p.severity) {
                                                case "normal":
                                                    return Colors.fgBase;
                                                case "warning":
                                                    return Colors.warning;
                                                case "critical":
                                                    return Colors.danger;
                                                }
                                            }
                                            font: Cell.fontB
                                        }
                                    }
                                }
                            }
                            CellSeparator {
                                w: list.w
                                type: 2
                                color: Colors.bgOverlay
                            }
                        }
                    }

                    sourceComponent: {
                        switch (modelData.type) {
                        case "spike":
                            return spike;
                        case "high_usage":
                            return high_usage;
                        case "sustained":
                            return sustained;
                        }
                    }
                }
            }
        }
    }
}
