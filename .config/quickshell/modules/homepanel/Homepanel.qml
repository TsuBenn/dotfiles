import qs.services
import qs.modules.common
import qs.modules.homepanel

import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick.Layouts
import QtQuick
import Qt5Compat.GraphicalEffects

PanelWindow {

    id: root

    anchors { top: true; left: true; bottom: true; right: true }

    focusable: true
    visible: false
    exclusionMode: ExclusionMode.Auto

    function toggle() {
        if (visible && !openpanel.running) {
            closepanel.start()
            return
        }
        else root.visible = true
    }

    WlrLayershell.layer: WlrLayer.Overlay

    color: Qt.rgba(0.0,0.0,0.0,0.4)

    onVisibleChanged: {
        if (visible) {
            openpanel.start()
        }
    }

    SequentialAnimation {
        id: openpanel
        NumberAnimation {
            target: homepanel
            property: "anchors.verticalCenterOffset"
            from: -SystemInfo.monitorheight
            to: 0
            duration: 400
            easing.type: Easing.OutElastic
            easing.amplitude: 0.8
            easing.period: 1.6
        }
    }

    SequentialAnimation {
        id: closepanel
        NumberAnimation {
            target: homepanel
            property: "anchors.verticalCenterOffset"
            to: -SystemInfo.monitorheight
            duration: 300
            easing.type: Easing.InElastic
            easing.amplitude: 1
            easing.period: 1
        }
        PauseAnimation {
            duration: 50
        }
        ScriptAction {
            script: root.visible = false
        }
    }

    MouseArea {

        z: -3

        anchors.fill: parent

        hoverEnabled: true

        onPressed: {
            closepanel.start()
        }
    }

    MouseArea {

        z: -2

        anchors.fill: homepanel

        hoverEnabled: true
    }

    //UI
    ColumnLayout {

        id:homepanel

        anchors.centerIn: parent
        anchors.verticalCenterOffset: -20

        spacing: Config.gap

        layer.enabled: true
        layer.effect: DropShadow {
            radius: 7
            samples: 20
            color: Qt.rgba(0.0,0.0,0.0,0.3)
            transparentBorder: true
        }

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
                implicitHeight: (parent.implicitHeight/2 + widgets.implicitHeight + Config.gap) * parent.typing - 31

                Behavior on implicitHeight {NumberAnimation {duration: 400; easing.type: Easing.OutCubic}}

                MouseArea {
                    anchors.fill: parent
                    z:-1
                }
            }

        }

        //Widgets
        Widgets {

            panel_navigator: !searchbar.typing

            z: searchresults.visible ? -2 : 1

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
                if (searchbar.typing) return
                if (key == Qt.Key_Space && !auto) {
                    MediaPlayerInfo.playPauseMedia()
                } else if (key == Qt.Key_Left && mod == Qt.ShiftModifier && !auto) {
                    MediaPlayerInfo.prevMedia()
                } else if (key == Qt.Key_Right && mod == Qt.ShiftModifier && !auto) {
                    MediaPlayerInfo.nextMedia()
                } else if (key == Qt.Key_Left && !auto) {
                    widgets.advancePanel(-1)
                } else if (key == Qt.Key_Right && !auto) {
                    widgets.advancePanel(1)
                } else if (key == Qt.Key_AsciiTilde && !auto) {
                    AudioInfo.muteVolume(AudioInfo.sinkDefault)
                } else if (key == Qt.Key_Up) {
                    AudioInfo.setVolume(AudioInfo.sinkDefault, Math.min(Math.max(AudioInfo.volume+10, 0), 100))
                } else if (key == Qt.Key_Down) {
                    AudioInfo.setVolume(AudioInfo.sinkDefault, Math.min(Math.max(AudioInfo.volume-10, 0), 100))
                }
            })
            KeyHandlers.released.connect((key, mod, auto) => {
                if (key == Qt.Key_Escape) {
                    closepanel.start()
                }
            })

        }

    }

}
