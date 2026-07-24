pragma ComponentBehavior: Bound

import qs.components.popups.System

import qs.config
import qs.modules
import qs.services

import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    function fmt(str, ...args) {
        return str.replace(/{}/g, () => args.shift());
    }

    function strip(str: string): string {
        return str.trim().replace(/<[^>]*>/g, "");
    }

    property var box
    property bool minimal

    spacing: 0

    ColumnLayout {

        Layout.alignment: Qt.AlignTop

        spacing: 0

        Header {
            text: "CPU"
        }

        Stat {
            key: "Name:"
            value: root.fmt("<b>{}</b>", SystemInfo.cpumodel)

            value_color: {
                if (value.toLowerCase().includes("amd")) {
                    return Colors.blend(Colors.danger, Colors.fgBase, 0.2);
                } else if (value.toLowerCase().includes("intel")) {
                    return Colors.blend(Colors.danger, Colors.info, 0.2);
                }
                return Colors.fgBase;
            }
        }

        CellSeparator {

            visible: !root.minimal

            w: root.box.eW
            padding: 1
            color: Colors.bgOverlay
        }

        Bar {

            key: root.fmt("<b>{}%<b>", parseInt(SystemInfo.cpuusage).toString().padStart(3, " "))
            value: SystemInfo.cpuusage

            value_color: {
                if (value > root.box.danger_thres) {
                    return Colors.blend(Colors.warning, Colors.danger, Math.min(value - root.box.danger_thres, 10) / 10);
                } else if (value > root.box.warning_thres) {
                    return Colors.blend(root.box.bar, Colors.warning, Math.min(value - root.box.warning_thres, 10) / 10);
                }
                return root.box.bar;
            }

            key_color: {
                if (value > root.box.danger_thres) {
                    return Colors.blend(Colors.warning, Colors.danger, Math.min(value - root.box.danger_thres, 10) / 10);
                } else if (value > root.box.warning_thres) {
                    return Colors.blend(root.box.dyn, Colors.warning, Math.min(value - root.box.warning_thres, 10) / 10);
                }
                return root.box.dyn;
            }
        }

        CellSeparator {

            visible: !root.minimal

            w: root.box.eW
            padding: 1
            color: Colors.bgOverlay
        }

        Stat {
            key: "Temp:"
            value: root.fmt("<b>{}°C</b>", parseInt(SystemInfo.cputemp))

            value_color: {
                const value = SystemInfo.cputemp;
                if (value > root.box.warning_thres) {
                    return Colors.blend(Colors.warning, Colors.danger, Math.min(value - root.box.danger_thres, 10) / 10);
                } else if (value > 70) {
                    return Colors.blend(root.box.dyn, Colors.warning, Math.min(value - root.box.warning_thres, 10) / 10);
                }
                return root.box.dyn;
            }
        }

        Stat {
            key: "Freq:"
            value: root.fmt("<b>{}MHz</b>", parseInt(SystemInfo.cpubase))
        }

        Stat {
            key: "Boost:"
            value: root.fmt("{}MHz", parseInt(SystemInfo.cpuboost))
            stc: true
        }

        Stat {
            key: "Cores:"
            value: parseInt(SystemInfo.cpucores)
            stc: true
        }

        Stat {
            key: "Threads:"
            value: parseInt(SystemInfo.cputhreads)
            stc: true
        }

        CellText {
            text: ""
        }

        Header {
            id: gpu

            text: "GPU"

            property int index: 0
            property var model: SystemInfo.gpumodels[index] ?? ({
                    "name": "None",
                    "usage": 0,
                    "memoryused": 0,
                    "memorytotal": 0,
                    "cores": 0,
                    "type": "None",
                    "temp": 0
                })
        }

        Stat {
            key: "Name:"
            value: root.fmt("<b>{}</b>", gpu.model.name)

            value_color: {
                if (value.toLowerCase().includes("amd")) {
                    return Colors.blend(Colors.danger, Colors.fgBase, 0.2);
                } else if (value.toLowerCase().includes("intel")) {
                    return Colors.blend(Colors.danger, Colors.info, 0.2);
                } else if (value.toLowerCase().includes("nvidia")) {
                    return Colors.blend(Colors.success, Colors.info, 0.2);
                }
                return Colors.fgBase;
            }
        }

        CellSeparator {

            visible: !root.minimal

            w: root.box.eW
            padding: 1
            color: Colors.bgOverlay
        }

        Bar {

            key: root.fmt("<b>{}%</b>", parseInt(gpu.model.usage).toString().padStart(3, " "))
            value: gpu.model.usage

            value_color: {
                if (value > root.box.danger_thres) {
                    return Colors.blend(Colors.warning, Colors.danger, Math.min(value - root.box.danger_thres, 10) / 10);
                } else if (value > root.box.warning_thres) {
                    return Colors.blend(root.box.bar, Colors.warning, Math.min(value - root.box.warning_thres, 10) / 10);
                }
                return root.box.bar;
            }

            key_color: {
                if (value > root.box.danger_thres) {
                    return Colors.blend(Colors.warning, Colors.danger, Math.min(value - root.box.danger_thres, 10) / 10);
                } else if (value > root.box.warning_thres) {
                    return Colors.blend(root.box.dyn, Colors.warning, Math.min(value - root.box.warning_thres, 10) / 10);
                }
                return root.box.dyn;
            }
        }

        CellSeparator {

            visible: !root.minimal

            w: root.box.eW
            padding: 1
            color: Colors.bgOverlay
        }

        Stat {
            key: "Temp:"
            value: root.fmt("<b>{}°C</b>", gpu.model.temp)

            value_color: {
                const value = gpu.model.temp;
                if (value > root.box.warning_thres) {
                    return Colors.blend(Colors.warning, Colors.danger, Math.min(value - root.box.danger_thres, 10) / 10);
                } else if (value > 70) {
                    return Colors.blend(root.box.dyn, Colors.warning, Math.min(value - root.box.warning_thres, 10) / 10);
                }
                return root.box.dyn;
            }
        }

        Stat {
            key: "Type:"
            value: gpu.model.type
            stc: true
        }

        Stat {
            key: "Cores:"
            value: gpu.model.cores
            stc: true
        }

        RowLayout {

            spacing: 0

            Stat {
                key: "VRAM:"
                value: root.fmt("<b>{}G</b>", SystemInfo.ktoG(gpu.model.memoryused).toFixed(1))

                w: root.box.eW - vram.w

                value_color: {
                    const value = (SystemInfo.ktoG(gpu.model.memoryused).toFixed(1) / SystemInfo.ktoG(gpu.model.memorytotal).toFixed(1)) * 100;
                    if (value > root.box.danger_thres) {
                        return Colors.blend(Colors.warning, Colors.danger, Math.min(value - root.box.danger_thres, 10) / 10);
                    } else if (value > root.box.warning_thres) {
                        return Colors.blend(root.box.dyn, Colors.warning, Math.min(value - root.box.warning_thres, 10) / 10);
                    }
                    return root.box.dyn;
                }
            }

            CellText {
                id: vram

                Layout.leftMargin: -Cell.w(root.box.p)

                text: root.fmt("/{}G", SystemInfo.ktoG(gpu.model.memorytotal).toFixed(1))
                color: root.box.stc
            }
        }

        CellSeparator {

            visible: !root.minimal

            w: root.box.eW
            padding: 1
            color: Colors.bgOverlay
        }

        Bar {

            key: root.fmt("<b>{}%</b>", parseInt(value).toString().padStart(3, " "))
            value: (gpu.model.memoryused / gpu.model.memorytotal) * 100

            value_color: {
                if (value > root.box.danger_thres) {
                    return Colors.blend(Colors.warning, Colors.danger, Math.min(value - root.box.danger_thres, 10) / 10);
                } else if (value > root.box.warning_thres) {
                    return Colors.blend(root.box.bar, Colors.warning, Math.min(value - root.box.warning_thres, 10) / 10);
                }
                return root.box.bar;
            }

            key_color: {
                if (value > root.box.danger_thres) {
                    return Colors.blend(Colors.warning, Colors.danger, Math.min(value - root.box.danger_thres, 10) / 10);
                } else if (value > root.box.warning_thres) {
                    return Colors.blend(root.box.dyn, Colors.warning, Math.min(value - root.box.warning_thres, 10) / 10);
                }
                return root.box.dyn;
            }
        }

        CellSeparator {

            visible: !root.minimal

            w: root.box.eW
            padding: 1
            color: Colors.bgOverlay
        }

        RowLayout {

            Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)

            spacing: 0

            CellText {

                property bool available: gpu.index > 0

                text: "      < "
                font: Cell.fontBB
                color: available ? Colors.fgBase : Colors.fgSubtle

                MouseControl {

                    anchors.fill: parent
                    anchors.topMargin: Cell.h(-1)
                    anchors.bottomMargin: Cell.h(-1)

                    onReleased: button => {
                        if (button == "L" && parent.available) {
                            gpu.index -= 1;
                        }
                    }
                }
            }

            CellText {
                text: {
                    const base = [..."-".repeat(SystemInfo.gpumodels.length)];
                    base[gpu.index] = "*";
                    return base.join("");
                }
                font: Cell.fontBB
            }

            CellText {

                property bool available: gpu.index < SystemInfo.gpumodels.length - 1

                text: " >      "
                font: Cell.fontBB
                color: available ? Colors.fgBase : Colors.fgSubtle

                MouseControl {

                    anchors.fill: parent
                    anchors.topMargin: Cell.h(-1)
                    anchors.bottomMargin: Cell.h(-1)

                    onReleased: button => {
                        if (button == "L" && parent.available) {
                            gpu.index += 1;
                        }
                    }
                }
            }
        }

        CellText {
            text: ""
        }

        Header {

            text: "Motherboard"
        }

        Stat {
            key: "Name:"
            value: SystemInfo.board
            stc: true
        }
    }

    CellSeparator {
        vertical: true
        h: root.box.contentH - 2
        color: Colors.bgOverlay
    }

    ColumnLayout {

        Layout.alignment: Qt.AlignTop

        spacing: 0

        Header {
            text: "MEMORY"
        }

        RowLayout {

            spacing: 0

            Stat {
                key: "RAM:"
                value: root.fmt("<b>{}G</b>", SystemInfo.ktoG(SystemInfo.memused).toFixed(1))

                w: root.box.eW - ram.w
            }

            CellText {
                id: ram

                Layout.leftMargin: -Cell.w(root.box.p)

                text: root.fmt("/{}G", SystemInfo.ktoG(SystemInfo.memtotal).toFixed(1))
                color: root.box.stc
            }
        }

        Bar {

            key: root.fmt("<b>{}%<b>", parseInt(SystemInfo.memusage).toString().padStart(3, " "))
            value: SystemInfo.memusage

            value_color: {
                if (value > root.box.danger_thres) {
                    return Colors.blend(Colors.warning, Colors.danger, Math.min(value - root.box.danger_thres, 10) / 10);
                } else if (value > root.box.warning_thres) {
                    return Colors.blend(root.box.bar, Colors.warning, Math.min(value - root.box.warning_thres, 10) / 10);
                }
                return root.box.bar;
            }

            key_color: {
                if (value > root.box.danger_thres) {
                    return Colors.blend(Colors.warning, Colors.danger, Math.min(value - root.box.danger_thres, 10) / 10);
                } else if (value > root.box.warning_thres) {
                    return Colors.blend(root.box.dyn, Colors.warning, Math.min(value - root.box.warning_thres, 10) / 10);
                }
                return root.box.dyn;
            }
        }

        CellSeparator {

            visible: !root.minimal

            w: root.box.eW
            padding: 1
            color: Colors.bgOverlay
        }

        RowLayout {

            spacing: 0

            Stat {
                key: "SWAP:"
                value: root.fmt("<b>{}G</b>", SystemInfo.ktoG(SystemInfo.swapused).toFixed(1))

                w: root.box.eW - swap.w
            }

            CellText {
                id: swap

                Layout.leftMargin: -Cell.w(root.box.p)

                text: root.fmt("/{}G", SystemInfo.ktoG(SystemInfo.swaptotal).toFixed(1))
                color: root.box.stc
            }
        }

        Bar {

            key: root.fmt("<b>{}%<b>", parseInt(SystemInfo.swapusage).toString().padStart(3, " "))
            value: SystemInfo.swapusage

            value_color: {
                if (value > root.box.danger_thres) {
                    return Colors.blend(Colors.warning, Colors.danger, Math.min(value - root.box.danger_thres, 10) / 10);
                } else if (value > root.box.warning_thres) {
                    return Colors.blend(root.box.bar, Colors.warning, Math.min(value - root.box.warning_thres, 10) / 10);
                }
                return root.box.bar;
            }

            key_color: {
                if (value > root.box.danger_thres) {
                    return Colors.blend(Colors.warning, Colors.danger, Math.min(value - root.box.danger_thres, 10) / 10);
                } else if (value > root.box.warning_thres) {
                    return Colors.blend(root.box.dyn, Colors.warning, Math.min(value - root.box.warning_thres, 10) / 10);
                }
                return root.box.dyn;
            }
        }

        CellSeparator {

            visible: !root.minimal

            w: root.box.eW
            padding: 1
            color: Colors.bgOverlay
        }

        CellText {
            text: " "
        }

        Header {
            text: "DISKS"
        }

        CellScrollView {

            w: root.box.eW
            h: root.minimal ? 4 : 8

            source: ColumnLayout {

                spacing: 0

                Repeater {

                    model: SystemInfo.disks.length

                    delegate: ColumnLayout {
                        id: disks

                        required property int index

                        property string name: SystemInfo.disks[index]?.name ?? ""
                        property string mountpoint: SystemInfo.disks[index]?.mountpoint ?? ""
                        property string mountfrom: SystemInfo.disks[index]?.mountfrom ?? ""
                        property int total: SystemInfo.disks[index]?.total ?? 0
                        property int used: SystemInfo.disks[index]?.used ?? 0
                        property string fs: SystemInfo.disks[index]?.filesystem ?? 0

                        spacing: 0

                        RowLayout {

                            spacing: 0

                            MarqueeCellText {

                                Layout.leftMargin: Cell.w(1)

                                text: root.fmt("<b>{}</b> <i>{}</i>", disks.name, disks.fs)
                                fg: root.box.stc
                                cellw: root.box.eW - root.box.p * 2 - 2 - diskused.w - disktotal.w
                            }

                            CellText {
                                text: " "
                            }

                            CellText {
                                id: diskused

                                text: root.fmt("<b>{}G</b>", SystemInfo.ktoG(disks.used))
                                color: root.box.dyn
                            }

                            CellText {
                                id: disktotal

                                text: root.fmt("<b>/{}G</b>", SystemInfo.ktoG(disks.total))
                                color: root.box.stc
                            }
                        }

                        MarqueeCellText {

                            visible: !root.minimal

                            Layout.leftMargin: Cell.w(1)

                            text: disks.mountpoint

                            fg: Colors.fgSubtle

                            cellw: root.box.eW - root.box.p * 2 - 1
                        }

                        Bar {

                            key: root.fmt("<b>{}%<b>", parseInt((disks.used / disks.total) * 100).toString().padStart(3, " "))
                            value: (disks.used / disks.total) * 100

                            w: root.box.eW - root.box.p

                            value_color: {
                                if (value > root.box.danger_thres) {
                                    return Colors.blend(Colors.warning, Colors.danger, Math.min(value - root.box.danger_thres, 10) / 10);
                                } else if (value > root.box.warning_thres) {
                                    return Colors.blend(root.box.bar, Colors.warning, Math.min(value - root.box.warning_thres, 10) / 10);
                                }
                                return root.box.bar;
                            }

                            key_color: {
                                if (value > root.box.danger_thres) {
                                    return Colors.blend(Colors.warning, Colors.danger, Math.min(value - root.box.danger_thres, 10) / 10);
                                } else if (value > root.box.warning_thres) {
                                    return Colors.blend(root.box.dyn, Colors.warning, Math.min(value - root.box.warning_thres, 10) / 10);
                                }
                                return root.box.dyn;
                            }
                        }

                        CellSeparator {

                            visible: !root.minimal

                            w: root.box.eW - root.box.p
                            padding: 1
                            color: Colors.bgOverlay
                        }
                    }
                }
            }
        }

        CellText {
            text: " "
        }

        Header {
            text: "DISKS IO"
        }

        RowLayout {

            spacing: 0

            Stat {
                key: "Write:"
                value: root.fmt("<b>{}</b>", SystemInfo.storageRounder(SystemInfo.diskwritespeed, 1, 10))

                w: root.box.eW - diskio.w
            }

            CellText {
                id: diskio

                Layout.leftMargin: -Cell.w(root.box.p)

                text: "/s"
                color: root.box.stc
            }
        }

        RowLayout {

            spacing: 0

            Stat {
                key: "Read:"
                value: root.fmt("<b>{}</b>", SystemInfo.storageRounder(SystemInfo.diskreadspeed, 1, 10))

                w: root.box.eW - diskio.w
            }

            CellText {

                Layout.leftMargin: -Cell.w(root.box.p)

                text: "/s"
                color: root.box.stc
            }
        }

        CellText {
            text: " "
        }

        Header {
            text: "POWER"
        }

        Stat {
            key: "Battery:"
            value: root.fmt("<b>{}</b>", SystemInfo.battery)
            value_color: {
                if (SystemInfo.batterystate == "charging" || SystemInfo.batterystate == "fully-charged") {
                    return Colors.success;
                }
                const value = parseInt(SystemInfo.battery);
                if (value) {
                    if (value <= 10) {
                        return Colors.danger;
                    } else if (value <= 20) {
                        return Colors.warning;
                    }
                }
                return root.box.dyn;
            }
        }

        Stat {
            key: "Health:"
            value: SystemInfo.batteryhealth != "" ? parseFloat(SystemInfo.batteryhealth).toFixed(1) + "%" : "inf"
            value_color: {
                const value = parseInt(SystemInfo.batteryhealth);
                if (value) {
                    if (value <= 80) {
                        return Colors.danger;
                    } else if (value <= 90) {
                        return Colors.warning;
                    }
                }
                return root.box.stc;
            }
            stc: true
        }

        Stat {
            key: "State:"
            value: root.fmt("<b>{}</b>", SystemInfo.batterystate)
        }

        Stat {
            key: "On battery:"
            value: SystemInfo.onbattery ? "YES" : "NO"
            stc: true
        }
    }

    CellSeparator {
        vertical: true
        h: root.box.contentH - 2
        color: Colors.bgOverlay
    }

    ColumnLayout {

        Layout.alignment: Qt.AlignTop

        spacing: 0

        Header {
            text: "NETWORK"
        }

        Stat {
            key: SystemInfo.wifi["ethernet"] ? "Ethernet:" : "Wifi:"
            value: root.fmt("<b>{}</b>", SystemInfo.wifi["ethernet"] ? SystemInfo.wifi["device"] : SystemInfo.wifi["name"])
        }

        Stat {
            key: "Local IP:"
            value: root.fmt("<b>{}</b>", SystemInfo.wifi["localip"])
        }

        Stat {
            key: "Signal:"
            value: root.fmt("<b>{}</b>", SystemInfo.wifi["signal"])
            value_color: {
                const value = SystemInfo.wifi["signal"];
                if (value > 80) {
                    return Colors.success;
                } else if (value > 50) {
                    return Colors.warning;
                }
                return Colors.danger;
            }
        }

        Stat {
            key: "Frequency:"
            value: root.fmt("{}G", (SystemInfo.wifi["freq"] / 1000).toFixed(1))
            stc: true
        }

        Stat {

            visible: !root.minimal

            key: "Channel:"
            value: SystemInfo.wifi["channel"]
            stc: true
        }

        CellText {
            text: " "
        }

        Header {
            text: "NETWORK IO"
        }

        RowLayout {

            spacing: 0

            Stat {
                key: "Transmit:"
                value: root.fmt("<b>{}</b>", SystemInfo.storageRounder(SystemInfo.networktransmit, 1, 10))

                w: root.box.eW - networkio.w
            }

            CellText {
                id: networkio

                Layout.leftMargin: -Cell.w(root.box.p)

                text: "/s"
                color: root.box.stc
            }
        }

        RowLayout {

            spacing: 0

            Stat {
                key: "Receive:"
                value: root.fmt("<b>{}</b>", SystemInfo.storageRounder(SystemInfo.networkreceive, 1, 10))

                w: root.box.eW - networkio.w
            }

            CellText {

                Layout.leftMargin: -Cell.w(root.box.p)

                text: "/s"
                color: root.box.stc
            }
        }

        CellText {
            text: " "
        }

        Header {
            text: "PHYSICAL DISKS"
        }

        CellScrollView {

            w: root.box.eW
            h: root.minimal ? 3 : 6

            source: ColumnLayout {

                spacing: 0

                Repeater {

                    model: SystemInfo.phydisks.length

                    delegate: ColumnLayout {
                        id: phydisks

                        required property int index

                        property string name: SystemInfo.phydisks[index]?.name ?? ""
                        property string type: SystemInfo.phydisks[index]?.type ?? 0
                        property int size: SystemInfo.phydisks[index]?.size ?? 0

                        spacing: 0

                        RowLayout {

                            spacing: 0

                            MarqueeCellText {

                                Layout.leftMargin: Cell.w(1)

                                text: root.fmt("<b>{}</b> <i>{}</i>", phydisks.name, phydisks.type)
                                fg: root.box.stc
                                cellw: root.box.eW - root.box.p * 2 - 2 - phydisk.w
                            }

                            CellText {
                                text: " "
                            }

                            CellText {
                                id: phydisk

                                text: root.fmt("<b>{}G</b>", SystemInfo.ktoG(phydisks.size))
                                color: root.box.stc
                            }
                        }

                        CellSeparator {

                            visible: !root.minimal

                            w: root.box.eW - root.box.p
                            padding: 1
                            color: Colors.bgOverlay
                        }
                    }
                }
            }
        }

        CellText {
            text: " "
        }

        Header {
            text: "OPERATION SYSTEM"
        }

        Stat {

            visible: !root.minimal

            key: "Username:"
            value: SystemInfo.username
            stc: true
        }

        Stat {

            visible: !root.minimal

            key: "Hostname:"
            value: SystemInfo.hostname
            stc: true
        }

        Stat {

            visible: root.minimal

            key: "user@host:"
            value: root.fmt("{}@{}", SystemInfo.username, SystemInfo.hostname)
            stc: true
        }

        Stat {
            key: "OS:"
            value: root.minimal ? root.fmt("{} ({})", SystemInfo.os, SystemInfo.architecture) : SystemInfo.os
            stc: true
        }

        Stat {

            visible: !root.minimal

            key: "Arch:"
            value: SystemInfo.architecture
            stc: true
        }

        Stat {
            key: "Kernel:"
            value: SystemInfo.kernel
            stc: true
        }

        Stat {
            key: "Uptime:"
            value: root.fmt("<b>{}</b>", SystemInfo.uptime)
        }

        Stat {
            key: "WM:"
            value: SystemInfo.wm
            stc: true
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

    component Stat: Cells {
        id: stat

        property string key: "Name:"
        property string value: "Ryzen R5 7600"

        property color key_color: root.box.key
        property color value_color: stc ? root.box.stc : root.box.dyn

        property bool stc: false
        property bool debug: false

        w: root.box.eW
        h: 1

        color: "transparent"

        CellText {
            id: stat_key

            anchors.left: stat.left
            anchors.leftMargin: Cell.w(root.box.p)

            text: stat.key
            color: stat.key_color
            debug: stat.debug
        }

        MarqueeCellText {
            id: stat_value

            anchors.right: stat.right
            anchors.rightMargin: Cell.w(root.box.p)

            text: stat.value
            fg: stat.value_color
            cellw: stat.w - root.strip(stat.key).length - root.box.p * 2 - 1
            alignRight: true
        }
    }

    component Bar: Cells {
        id: bar

        property string key: value + "%"
        property int value: SystemInfo.cpuusage

        property color key_color: Colors.fgBase
        property color value_color: Colors.fgBase

        w: root.box.eW
        h: 1

        color: "transparent"

        CellProgressSquare {
            id: bar_bar

            anchors.left: bar.left
            anchors.leftMargin: Cell.w(root.box.p)

            w: bar.w - 2 * root.box.p - bar_value.w - 1
            percent: bar.value

            fg: bar.value_color
        }

        CellText {
            id: bar_value

            anchors.right: bar.right
            anchors.rightMargin: Cell.w(root.box.p)

            text: bar.key
        }
    }
}
