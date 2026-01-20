import qs.services
import qs.modules.common
import qs.modules.homepanel

import Quickshell
import Quickshell.Hyprland
import QtQuick.Layouts
import QtQuick

PanelWindow {

    id: root

    anchors { top: true; left: true; bottom: true; right: true }

    HyprlandFocusGrab {
        active: root.visible
        windows: [root]
    }

    focusable: true
    visible: false
    exclusionMode: ExclusionMode.Auto

    color: Qt.rgba(0, 0, 0, 0.5)

    //UI
    ColumnLayout {

        id:homepanel

        anchors.centerIn: parent
        anchors.verticalCenterOffset: -20

        spacing: Config.gap

        Clock {
            Layout.alignment: Qt.AlignCenter
            preferedWidth: widgets.implicitWidth
        }

        //Search bar
        Searchbar {

            id: searchbar
            Layout.alignment: Qt.AlignCenter
            preferedWidth: widgets.implicitWidth

            onTextChanged: {
                searchresults.resetScroll()
            }

            SearchResults {

                id: searchresults

                visible: implicitHeight

                z: -1
                y: searchbar.implicitHeight/2

                results: searchbar.results

                onVisibleChanged: searchbar.results = []

                onEnterPressed: {
                    if (visible) root.visible = false
                }

                bottomLeftRadius: searchbar.radius
                bottomRightRadius: searchbar.radius

                implicitWidth: parent.implicitWidth
                implicitHeight: (parent.implicitHeight/2 + widgets.implicitHeight + Config.gap) * parent.typing

                Behavior on implicitHeight {NumberAnimation {duration: 200; easing.type: Easing.OutCubic}}

                MouseArea {
                    anchors.fill: parent
                    z:-1
                }
            }

        }

        //Widgets
        Widgets {

            z:-2

            opacity: !(searchresults.implicitHeight == (searchbar.implicitHeight/2 + widgets.implicitHeight + Config.gap))

            id: widgets

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
                    //console.log(key)
                }
            })
            KeyHandlers.released.connect((key) => {
                if (searchbar.typing) return
                if (key == Qt.Key_Space) {
                    MediaPlayerInfo.playPauseMedia()
                } else if (key == Qt.Key_Left) {
                    MediaPlayerInfo.prevMedia()
                } else if (key == Qt.Key_Right) {
                    MediaPlayerInfo.nextMedia()
                } else if (key == Qt.Key_Up) {
                    AudioInfo.setVolume(AudioInfo.sinkDefault, AudioInfo.volume+5)
                } else if (key == Qt.Key_Down) {
                    AudioInfo.setVolume(AudioInfo.sinkDefault, AudioInfo.volume-5)
                } else if (key == Qt.Key_AsciiTilde) {
                    AudioInfo.muteVolume(AudioInfo.sinkDefault)
                }
            })

        }

    }

}
