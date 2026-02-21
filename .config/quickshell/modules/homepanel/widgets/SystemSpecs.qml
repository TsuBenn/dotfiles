pragma ComponentBehavior: Bound

import qs.assets
import qs.services
import qs.modules.homepanel
import qs.modules.common

import QtQuick
import QtQuick.Layouts

Item {
    id: sys_info

    property int info_size: 10
    property int header_size: 11
    property int spec_width: 330
    property color stat_color: Qt.lighter(Color.textDisabled,1.3)
    property color value_color: Color.textPrimary
    property color header_color: Color.accentSoft

    component SpecContainer: Rectangle {

        property int box_height: 100
        property string header_text
        property var header_bottom: spec_header_text_container.bottom

        id: spec_container

        implicitWidth: sys_info.spec_width
        implicitHeight: box_height + spec_header_text_container.implicitHeight + 8
        color: "transparent"
        radius: Config.radius

        Rectangle {

            anchors.left: spec_header_text_container.left
            anchors.verticalCenter: spec_header_text_container.verticalCenter

            implicitWidth: spec_container.implicitWidth - spec_header_text_container.anchors.margins*2 - 8
            implicitHeight: 4

            color: Qt.lighter(Color.bgMuted,1.5)
        }

        Rectangle {

            id: spec_header_text_container

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 8

            implicitWidth: spec_header_text.implicitWidth + 14
            implicitHeight: spec_header_text.implicitHeight
            color: Color.bgSurface

            Text {

                id: spec_header_text

                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -2

                text: spec_container.header_text

                color: sys_info.header_color

                font.family: Fonts.system
                font.weight: 800
                font.pointSize: sys_info.header_size
            }
        }

    }

    RowLayout {

        spacing: 0
        x: 2

        ColumnLayout {

            Layout.alignment: Qt.AlignTop 

            SpecContainer {

                box_height: cpu_spec.implicitHeight
                header_text: "CPU"

                ColumnLayout {

                    id: cpu_spec

                    anchors.top: parent.header_bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 2

                    spacing: 5

                    Rectangle {

                        Layout.alignment: Qt.AlignLeft

                        Layout.leftMargin: 20

                        implicitWidth: 290
                        implicitHeight: cpu_name.implicitHeight

                        color: "transparent"

                        Text {
                            id: cpu_name

                            width: 290
                            elide: Text.ElideRight

                            text: SystemInfo.cpumodel

                            color: {
                                if (text.toLowerCase().includes("amd")) {
                                    return Color.blend(Color.error,sys_info.value_color,0.3)
                                }
                                else if (text.toLowerCase().includes("intel")) {
                                    return Color.blend(Color.info,sys_info.value_color,0.3)
                                }
                                else {
                                    return sys_info.value_color
                                }
                            }

                            font.family: Fonts.system
                            font.weight: 700
                            font.pointSize: sys_info.info_size

                        }

                    }

                    RowLayout {

                        Layout.alignment: Qt.AlignHCenter

                        spacing: 0

                        HorizontalProgressBar {

                            box_width: sys_info.spec_width - 76
                            box_height: 14
                            round: false
                            preferedPercentage: SystemInfo.cpuusage

                        }

                        Rectangle {
                            implicitHeight: 18
                            implicitWidth: 38
                            color: "transparent"

                            Text {

                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter

                                text: String(Math.round(SystemInfo.cpuusage)).padStart(3, " ") + "%"

                                color: sys_info.value_color

                                font.family: Fonts.system
                                font.weight: 700
                                font.pointSize: sys_info.info_size
                            }
                        }
                    }

                    Rectangle {

                        Layout.fillWidth: true

                        implicitWidth: parent.implicitWidth
                        implicitHeight: cpu_stat.implicitHeight
                        color: "transparent"

                        Text {
                            id: cpu_stat

                            anchors.left: parent.left

                            anchors.margins: 18

                            text: "Temp:\nFrequency:\nMax Frequency:\nCores:\nThreads:"

                            color: sys_info.stat_color

                            font.family: Fonts.system
                            font.weight: 700
                            font.pointSize: sys_info.info_size
                        }

                        Text {

                            anchors.right: parent.right

                            anchors.margins: 20

                            text: `${SystemInfo.cputemp.toFixed(1) + "°C"}\n${SystemInfo.cpubase} MHz\n${SystemInfo.cpuboost} MHz\n${SystemInfo.cpucores}\n${SystemInfo.cputhreads}`

                            color: sys_info.value_color

                            font.family: Fonts.system
                            font.weight: 500
                            font.pointSize: sys_info.info_size
                        }
                    }
                }

            }

            SpecContainer {

                id: gpu_spec_container

                box_height: 154
                header_text: "GPU"
                property int index: 0

                function advanceGpu(interval) {
                    index = Math.min(Math.max(index + interval,0),gpu_nav.gpu_amount-1)
                }

                Repeater {

                    id: gpu_spec

                    model: SystemInfo.gpumodels

                    delegate: Loader {

                        active: root.visible

                        id: gpu_spec_loader

                        anchors.top: gpu_spec_container.header_bottom
                        anchors.left: gpu_spec_container.left
                        anchors.right: gpu_spec_container.right
                        anchors.topMargin: 2

                        required property int index
                        required property string type
                        required property string name
                        required property real memorytotal
                        required property real memoryused
                        required property int cores
                        required property real usage
                        required property real temp

                        sourceComponent: ColumnLayout {

                            anchors.fill: parent
                            visible: gpu_spec_loader.index == gpu_spec_container.index

                            spacing: 5

                            Rectangle {

                                Layout.alignment: Qt.AlignLeft
                                Layout.leftMargin: 20

                                implicitWidth: 290
                                implicitHeight: gpu_name.implicitHeight

                                color: "transparent"

                                Text {
                                    id: gpu_name

                                    width: 290
                                    elide: Text.ElideRight

                                    text: gpu_spec_loader.name

                                    color: {
                                        if (text.toLowerCase().includes("amd")) {
                                            return Color.blend(Color.error,sys_info.value_color,0.3)
                                        }
                                        else if (text.toLowerCase().includes("intel")) {
                                            return Color.blend(Color.info,sys_info.value_color,0.3)
                                        }
                                        else if (text.toLowerCase().includes("nvidia")) {
                                            return Color.blend(Color.success,sys_info.value_color,0.3)
                                        }
                                        else {
                                            return sys_info.value_color
                                        }
                                    }

                                    font.family: Fonts.system
                                    font.weight: 700
                                    font.pointSize: sys_info.info_size

                                }

                            }

                            RowLayout {

                                Layout.alignment: Qt.AlignHCenter

                                spacing: 0

                                HorizontalProgressBar {

                                    box_width: sys_info.spec_width - 76
                                    box_height: 14
                                    round: false
                                    preferedPercentage: gpu_spec_loader.usage

                                }

                                Rectangle {
                                    implicitHeight: 18
                                    implicitWidth: 38
                                    color: "transparent"

                                    Text {

                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter

                                        text: String(gpu_spec_loader.usage).padStart(3, " ") + "%"

                                        color: sys_info.value_color

                                        font.family: Fonts.system
                                        font.weight: 700
                                        font.pointSize: sys_info.info_size
                                    }
                                }
                            }

                            Rectangle {

                                Layout.fillWidth: true

                                implicitWidth: parent.implicitWidth
                                implicitHeight: gpu_stat.implicitHeight
                                color: "transparent"

                                Text {
                                    id: gpu_stat

                                    anchors.left: parent.left

                                    anchors.margins: 18

                                    text: "Temp:\nType:\nCores:"

                                    color: sys_info.stat_color

                                    font.family: Fonts.system
                                    font.weight: 700
                                    font.pointSize: sys_info.info_size
                                }

                                Text {

                                    anchors.right: parent.right

                                    anchors.margins: 20

                                    text: `${gpu_spec_loader.temp.toFixed(1) + "°C"}\n${gpu_spec_loader.type}\n${gpu_spec_loader.cores}`

                                    color: sys_info.value_color

                                    font.family: Fonts.system
                                    font.weight: 500
                                    font.pointSize: sys_info.info_size
                                }
                            }

                            Rectangle {

                                Layout.fillWidth: true

                                implicitWidth: parent.implicitWidth
                                implicitHeight: gpu_mem_stat.implicitHeight
                                color: "transparent"

                                Text {
                                    id: gpu_mem_stat

                                    anchors.left: parent.left

                                    anchors.margins: 18

                                    text: "VRAM:"

                                    color: sys_info.stat_color

                                    font.family: Fonts.system
                                    font.weight: 700
                                    font.pointSize: sys_info.info_size
                                }

                                Text {

                                    anchors.right: parent.right

                                    anchors.margins: 20

                                    text: String(SystemInfo.ktoG(gpu_spec_loader.memoryused).toFixed(1)).padStart(4, " ") + "G/" + SystemInfo.ktoG(gpu_spec_loader.memorytotal).toFixed(1) + "G (" + Math.round((gpu_spec_loader.memoryused/gpu_spec_loader.memorytotal)*100) + "%)"

                                    color: sys_info.value_color

                                    font.family: Fonts.system
                                    font.weight: 500
                                    font.pointSize: sys_info.info_size
                                }
                            }

                            RowLayout {

                                Layout.alignment: Qt.AlignHCenter
                                Layout.topMargin: -4

                                spacing: 0

                                HorizontalProgressBar {

                                    box_width: sys_info.spec_width - 38
                                    box_height: 10
                                    round: false
                                    preferedPercentage: Math.round((gpu_spec_loader.memoryused/gpu_spec_loader.memorytotal)*100)

                                }
                            }

                        }
                    }

                }

                RowLayout {

                    y: 170
                    anchors.horizontalCenter: parent.horizontalCenter

                    id: gpu_nav

                    property int gpu_amount: SystemInfo.gpumodels.length

                    opacity: root.gpu_nav

                    Behavior on opacity {NumberAnimation {duration: 300; easing.type: Easing.OutCubic}}

                    Text {
                        text: "\uf0d9"
                        font.family: Fonts.system
                        font.pointSize: 12
                        font.weight: 1000
                        color: gpu_spec_container.index > 0 ? sys_info.value_color : Color.textDisabled
                        MouseArea {
                            anchors.fill: parent
                            anchors.topMargin: -10
                            anchors.bottomMargin: -50
                            anchors.leftMargin: -200
                            anchors.rightMargin: -10

                            hoverEnabled: true

                            onReleased: {
                                gpu_spec_container.advanceGpu(-1)
                            }
                        }
                    }
                    Rectangle {

                        implicitHeight: 20
                        implicitWidth: gpu_page.implicitWidth

                        color: "transparent"

                        RowLayout {

                            id: gpu_page
                            anchors.centerIn: parent

                            Repeater {

                                model: gpu_nav.gpu_amount

                                delegate: Rectangle {

                                    required property int index

                                    property bool selected: gpu_spec_container.index == index 

                                    property real size: selected ? 8 : 6
                                    implicitWidth: size
                                    implicitHeight: size

                                    Behavior on color {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}

                                    color: selected ? sys_info.value_color : Color.textDisabled
                                    radius: size/2
                                }
                            }
                        }

                    }
                    Text {
                        text: "\uf0da"
                        font.family: Fonts.system
                        font.pointSize: 12
                        font.weight: 1000
                        color: gpu_spec_container.index < gpu_nav.gpu_amount-1 ? sys_info.value_color : Color.textDisabled

                        MouseArea {
                            anchors.fill: parent
                            anchors.topMargin: -10
                            anchors.bottomMargin: -50
                            anchors.leftMargin: -10
                            anchors.rightMargin: -200

                            hoverEnabled: true

                            onReleased: {
                                gpu_spec_container.advanceGpu(1)
                            }
                        }
                    }


                }

            }

            SpecContainer {
                id: board

                box_height: board_spec.implicitHeight
                header_text: "MOTHERBOARD"

                Rectangle {

                    id: board_spec

                    anchors.top: parent.header_bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 2

                    Layout.fillWidth: true

                    implicitWidth: parent.implicitWidth
                    implicitHeight: board_stat.implicitHeight
                    color: "transparent"

                    Text {
                        id: board_stat

                        anchors.left: parent.left

                        anchors.margins: 18

                        text: "Name:"

                        color: sys_info.stat_color

                        font.family: Fonts.system
                        font.weight: 700
                        font.pointSize: sys_info.info_size
                    }

                    Text {

                        anchors.right: parent.right

                        anchors.margins: 20

                        text: `${SystemInfo.board}\n`

                        color: sys_info.value_color

                        font.family: Fonts.system
                        font.weight: 500
                        font.pointSize: sys_info.info_size
                    }
                }

            }
        }

        ColumnLayout {

            Layout.alignment: Qt.AlignTop 

            SpecContainer {
                id: mem_container

                box_height: mem_spec.implicitHeight
                header_text: "MEMORY"

                ColumnLayout {

                    id: mem_spec

                    anchors.top: parent.header_bottom
                    anchors.left: parent.left
                    anchors.right: parent.right

                    spacing: 5

                    Rectangle {

                        Layout.fillWidth: true

                        implicitWidth: parent.implicitWidth
                        implicitHeight: mem_stat.implicitHeight
                        color: "transparent"

                        Text {
                            id: mem_stat

                            anchors.left: parent.left

                            anchors.margins: 18

                            text: "RAM:"

                            color: sys_info.stat_color

                            font.family: Fonts.system
                            font.weight: 700
                            font.pointSize: sys_info.info_size
                        }

                        Text {

                            anchors.right: parent.right

                            anchors.margins: 20

                            text: String(SystemInfo.ktoG(SystemInfo.memused).toFixed(1)).padStart(4, " ") + "G/" + SystemInfo.ktoG(SystemInfo.memtotal).toFixed(1) + "G (" + Math.round(SystemInfo.memusage) + "%)"

                            color: sys_info.value_color

                            font.family: Fonts.system
                            font.weight: 500
                            font.pointSize: sys_info.info_size
                        }
                    }

                    RowLayout {

                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: -4

                        spacing: 0

                        HorizontalProgressBar {

                            box_width: sys_info.spec_width - 38
                            box_height: 10
                            round: false
                            preferedPercentage: SystemInfo.memusage

                        }
                    }

                    Rectangle {

                        Layout.fillWidth: true

                        Layout.topMargin: 4

                        implicitWidth: parent.implicitWidth
                        implicitHeight: swap_stat.implicitHeight
                        color: "transparent"

                        Text {
                            id: swap_stat

                            anchors.left: parent.left

                            anchors.margins: 18

                            text: "SWAP:"

                            color: sys_info.stat_color

                            font.family: Fonts.system
                            font.weight: 700
                            font.pointSize: sys_info.info_size
                        }

                        Text {

                            anchors.right: parent.right

                            anchors.margins: 20

                            text: String(SystemInfo.ktoG(SystemInfo.swapused).toFixed(1)).padStart(4, " ") + "G/" + SystemInfo.ktoG(SystemInfo.swaptotal).toFixed(1) + "G (" + Math.round(SystemInfo.swapusage) + "%)"

                            color: sys_info.value_color

                            font.family: Fonts.system
                            font.weight: 500
                            font.pointSize: sys_info.info_size
                        }
                    }

                    RowLayout {

                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: -4

                        spacing: 0

                        HorizontalProgressBar {

                            box_width: sys_info.spec_width - 38
                            box_height: 10
                            round: false
                            preferedPercentage: SystemInfo.swapusage

                        }
                    }
                }

            }

            SpecContainer {
                id: disks

                box_height: disks_list.implicitHeight
                header_text: "DISKS"

                Layout.topMargin: 2

                List {

                    anchors.top: parent.header_bottom
                    anchors.left: parent.left
                    anchors.right: parent.right

                    id: disks_list

                    box_width: sys_info.spec_width
                    box_height: 114

                    bg_color: "transparent"
                    container_color: "transparent"

                    spacing: 6
                    padding: 0

                    items_data: SystemInfo.disks

                    items: Loader {

                        id: disk_loader

                        active: sys_info.visible

                        required property string name
                        required property string mountpoint
                        required property string filesystem
                        required property real total
                        required property real used

                        sourceComponent: ColumnLayout {

                            implicitWidth: disks_list.implicitWidth

                            spacing: 6

                            Rectangle {

                                id: disk

                                Layout.fillWidth: true

                                Layout.topMargin: 4

                                implicitWidth: parent.implicitWidth
                                implicitHeight: disk_stat.implicitHeight
                                color: "transparent"

                                Text {

                                    anchors.left: parent.left

                                    anchors.margins: 18

                                    width: parent.implicitWidth - disk_stat.paintedWidth - 20*2
                                    elide: Text.ElideRight

                                    text: disk_loader.name

                                    color: sys_info.stat_color

                                    font.family: Fonts.system
                                    font.weight: 700
                                    font.pointSize: sys_info.info_size
                                }

                                Text {
                                    id: disk_stat

                                    anchors.right: parent.right

                                    anchors.margins: 20

                                    text: String(SystemInfo.ktoG(disk_loader.used).toFixed(1)).padStart(4, " ") + "G/" + SystemInfo.ktoG(disk_loader.total).toFixed(1) + "G (" + Math.round((disk_loader.used/disk_loader.total)*100) + "%)"

                                    color: sys_info.value_color

                                    font.family: Fonts.system
                                    font.weight: 500
                                    font.pointSize: sys_info.info_size
                                }
                            }

                            RowLayout {

                                Layout.alignment: Qt.AlignHCenter
                                Layout.topMargin: -4

                                spacing: 0

                                HorizontalProgressBar {

                                    box_width: sys_info.spec_width - 38
                                    box_height: 10
                                    round: false
                                    preferedPercentage: Math.round((disk_loader.used/disk_loader.total)*100)

                                }

                            }

                        }

                    }
                }
            }

            SpecContainer {
                id: disksio

                box_height: disksio_spec.implicitHeight
                header_text: "DISKS IO"
                Layout.topMargin: 2

                Rectangle {

                    id: disksio_spec

                    anchors.top: parent.header_bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 2

                    Layout.fillWidth: true

                    implicitWidth: parent.implicitWidth
                    implicitHeight: disksio_stat.implicitHeight
                    color: "transparent"

                    Text {
                        id: disksio_stat

                        anchors.left: parent.left

                        anchors.margins: 18

                        text: "Write:\nRead:"

                        color: sys_info.stat_color

                        font.family: Fonts.system
                        font.weight: 700
                        font.pointSize: sys_info.info_size
                    }

                    Text {

                        anchors.right: parent.right

                        anchors.margins: 20

                        text: `${SystemInfo.storageRounder(SystemInfo.diskwritespeed,1,10)}/s\n${SystemInfo.storageRounder(SystemInfo.diskreadspeed,1,10)}/s`

                        color: sys_info.value_color

                        font.family: Fonts.system
                        font.weight: 500
                        font.pointSize: sys_info.info_size
                    }
                }

            }

            SpecContainer {
                id: battery

                box_height: battery_spec.implicitHeight
                header_text: "BATTERY"

                Rectangle {

                    id: battery_spec

                    anchors.top: parent.header_bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 2

                    Layout.fillWidth: true

                    implicitWidth: parent.implicitWidth
                    implicitHeight: battery_stat.implicitHeight
                    color: "transparent"

                    Text {
                        id: battery_stat

                        anchors.left: parent.left

                        anchors.margins: 18

                        text: "Current:\nState:\nOn battery"

                        color: sys_info.stat_color

                        font.family: Fonts.system
                        font.weight: 700
                        font.pointSize: sys_info.info_size
                    }

                    Text {

                        anchors.right: parent.right

                        anchors.margins: 20

                        text: `${SystemInfo.battery}\n` + 
                        `${SystemInfo.batterystate}\n` +
                        `${SystemInfo.onbattery}`

                        color: sys_info.value_color

                        font.family: Fonts.system
                        font.weight: 500
                        font.pointSize: sys_info.info_size
                    }
                }

            }

        }

        ColumnLayout {
            Layout.alignment: Qt.AlignTop 

            SpecContainer {
                id: network

                box_height: network_spec.implicitHeight
                header_text: "NETWORK"

                Rectangle {

                    id: network_spec

                    anchors.top: parent.header_bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 2

                    Layout.fillWidth: true

                    implicitWidth: parent.implicitWidth
                    implicitHeight: network_stat.implicitHeight
                    color: "transparent"

                    Text {
                        id: network_stat

                        anchors.left: parent.left

                        anchors.margins: 18

                        text: "Wifi:\nLocal IP:\nSignal quality:\nChannel:\nFrequency:\nReceive:\nTransmit:"

                        color: sys_info.stat_color

                        font.family: Fonts.system
                        font.weight: 700
                        font.pointSize: sys_info.info_size
                    }

                    Text {

                        anchors.right: parent.right

                        anchors.margins: 20

                        property string signal: {
                            const sig = SystemInfo.wifi.signal
                            if (sig > 90) {
                                return "S"
                            }
                            else if (sig > 80) {
                                return "A"
                            }
                            else if (sig > 70) {
                                return "B"
                            }
                            else if (sig > 60) {
                                return "C"
                            }
                            else if (sig > 50) {
                                return "D"
                            }
                            else if (sig > 40) {
                                return "E"
                            }
                            else if (sig >= 0) {
                                return "F"
                            }

                        }

                        text: `${SystemInfo.wifi.name} (${SystemInfo.wifi.device})\n` +
                        `${SystemInfo.wifi.localip}\n` +
                        `${signal} (${Math.round(SystemInfo.wifi.signal)})\n` +
                        `${SystemInfo.wifi.channel}\n` +
                        `${(SystemInfo.wifi.freq/1024).toFixed(1)} GHz\n` +
                        `${SystemInfo.storageRounder(SystemInfo.networkreceive)}/s\n` +
                        `${SystemInfo.storageRounder(SystemInfo.networktransmit)}/s\n`


                        color: sys_info.value_color

                        font.family: Fonts.system
                        font.weight: 500
                        font.pointSize: sys_info.info_size
                    }
                }

            }

            SpecContainer {
                id: phydisks

                box_height: phydisks_list.implicitHeight
                header_text: "PHYSICAL DISKS"
                Layout.topMargin: 4


                List {

                    anchors.top: parent.header_bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 2

                    id: phydisks_list

                    box_width: sys_info.spec_width
                    box_height: 106

                    bg_color: "transparent"
                    container_color: "transparent"

                    spacing: 6
                    padding: 0

                    items_data: SystemInfo.phydisks

                    items: Loader {

                        id: phydisk_loader

                        active: sys_info.visible

                        required property string name
                        required property string type
                        required property real size

                        sourceComponent: Rectangle {

                            id: phydisk

                            Layout.fillWidth: true


                            implicitWidth: phydisks_list.implicitWidth
                            implicitHeight: phydisk_stat.implicitHeight
                            color: "transparent"

                            PillButton {

                                id: physdisk_type

                                box_height: phydisk_stat.implicitHeight
                                box_width: 20

                                anchors.left: parent.left
                                anchors.margins: 18

                                text: {
                                    if (phydisk_loader.type.toLowerCase() == "ata" || phydisk_loader.type.toLowerCase() == "nvme") {
                                        return "\uf0a0"
                                    } else  if (phydisk_loader.type.toLowerCase() == "usb") {
                                        return "\udb84\ude9f"
                                    } else {
                                        return "\ueb32"
                                    }
                                }

                                clickable: false
                            }

                            Text {

                                anchors.left: physdisk_type.right

                                anchors.margins: 2

                                width: parent.implicitWidth - phydisk_stat.paintedWidth - 20*2 - physdisk_type.implicitWidth
                                elide: Text.ElideRight

                                text: phydisk_loader.name

                                color: sys_info.stat_color

                                font.family: Fonts.system
                                font.weight: 700
                                font.pointSize: sys_info.info_size
                            }

                            Text {
                                id: phydisk_stat

                                anchors.right: parent.right

                                anchors.margins: 20

                                text: SystemInfo.ktoG(phydisk_loader.size).toFixed(1) + "GB"

                                color: sys_info.value_color

                                font.family: Fonts.system
                                font.weight: 500
                                font.pointSize: sys_info.info_size
                            }
                        }

                    }
                }
            }

            SpecContainer {
                id: os

                box_height: network_spec.implicitHeight
                header_text: "OPERATION SYSTEM"

                Rectangle {

                    id: os_spec

                    anchors.top: parent.header_bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 2

                    Layout.fillWidth: true

                    implicitWidth: parent.implicitWidth
                    implicitHeight: os_stat.implicitHeight
                    color: "transparent"

                    Text {
                        id: os_stat

                        anchors.left: parent.left

                        anchors.margins: 18

                        text: "OS:\nKernel:\nUptime:\nWM:"

                        color: sys_info.stat_color

                        font.family: Fonts.system
                        font.weight: 700
                        font.pointSize: sys_info.info_size
                    }

                    Text {

                        anchors.right: parent.right

                        anchors.margins: 20

                        text: `${SystemInfo.os}\n` +
                        `${SystemInfo.kernel}\n` +
                        `${SystemInfo.uptime}\n` +
                        `${SystemInfo.wm}`


                        color: sys_info.value_color

                        font.family: Fonts.system
                        font.weight: 500
                        font.pointSize: sys_info.info_size
                    }
                }

            }
        }

    }
}

