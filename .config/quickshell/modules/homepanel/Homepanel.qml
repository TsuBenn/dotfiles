import qs.services
import qs.modules.homepanel

import Quickshell
import QtQuick.Layouts
import QtQuick

PanelWindow {

    id: root

    anchors { top: true; left: true; bottom: true; right: true }

    property real scale: SystemInfo.monitorheight < 1080 ? SystemInfo.monitorheight/1080*(1/SystemInfo.monitorscale) : 1

    focusable: true
    visible: false

    color: Qt.rgba(0, 0, 0, 0.5)

    //UI
    ColumnLayout {

        id:homepanel

        anchors.centerIn: parent
        anchors.verticalCenterOffset: -40*root.scale

        spacing: Config.gap

        transform: [
            Scale {yScale: root.scale; xScale: root.scale},
            Translate {x:(homepanel.width-homepanel.width*root.scale)/2; y:(homepanel.height-homepanel.height*root.scale)/2}
        ]

        Clock {}

        //Search bar
        Searchbar {
            Layout.alignment: Qt.AlignCenter
        }

        //Widgets
        Widgets {
            Layout.alignment: Qt.AlignCenter
        }

        Keys.onReleased: (events) => {
            if (events.isAutoRepeat) return
            if (events.key == Qt.Key_Escape) {
                root.visible = false
                events.accepted = true
            }
        }
    }

}
