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

    focusable: true
    visible: false
    exclusionMode: ExclusionMode.Auto

    color: Qt.rgba(0.0,0.0,0.0,0.4)

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

            animationRunning: searchresults.animationRunning

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
            events.accepted = true
            KeyHandlers.signalPressed(events.key, events.modifiers, events.isAutoRepeat)
        }
        Keys.onReleased: (events) => {
            events.accepted = true
            KeyHandlers.signalReleased(events.key, events.modifiers, events.isAutoRepeat)
        }

        Component.onCompleted: {
            KeyHandlers.pressed.connect((key, mod, auto)=> {
                if (key == Qt.Key_Escape) {
                    root.visible = false
                }
            })
            KeyHandlers.released.connect((key, mod, auto) => {
                if (searchbar.typing) return
                if (key == Qt.Key_Space && !auto) {
                    MediaPlayerInfo.playPauseMedia()
                } else if (key == Qt.Key_Left && !auto) {
                    MediaPlayerInfo.prevMedia()
                } else if (key == Qt.Key_Right && !auto) {
                    MediaPlayerInfo.nextMedia()
                } else if (key == Qt.Key_AsciiTilde && !auto) {
                    AudioInfo.muteVolume(AudioInfo.sinkDefault)
                } else if (key == Qt.Key_Up) {
                    AudioInfo.setVolume(AudioInfo.sinkDefault, Math.min(Math.max(AudioInfo.volume+10, 0), 100))
                } else if (key == Qt.Key_Down) {
                    AudioInfo.setVolume(AudioInfo.sinkDefault, Math.min(Math.max(AudioInfo.volume-10, 0), 100))
                }

            })

        }

    }

}
