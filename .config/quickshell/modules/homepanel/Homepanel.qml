import qs.services
import qs.modules.common
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
    exclusionMode: ExclusionMode.Auto

    color: Qt.rgba(0, 0, 0, 0.5)

    //UI
    ColumnLayout {

        id:homepanel

        anchors.centerIn: parent
        anchors.verticalCenterOffset: -20*root.scale

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

        Keys.onPressed: (events) => {
            if (events.isAutoRepeat) return
            events.accepted = true
            KeyHandlers.signalPressed(events.key, events.modifiers)
        }
        Keys.onReleased: (events) => {
            if (events.isAutoRepeat) return
            events.accepted = true
            KeyHandlers.signalReleased(events.key, events.modifiers)
        }

        Component.onCompleted: {
            KeyHandlers.pressed.connect((key, modifiers)=> {
                if (key == Qt.Key_Escape) {
                    root.visible = false
                    console.log(key)
                }
            })
        }

    }

}
