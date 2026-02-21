pragma ComponentBehavior: Bound

import qs.services
import qs.assets
import qs.modules.homepanel
import qs.modules.common

import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

ClippingRectangle {

    id: root

    property int searchbar_offset
    property int select: 0
    property int top_visible: list.stepProgress
    property int bottom_visible: list.stepProgress + 5

    property var results: []
    property var newresults: []

    property var execList: []

    border.width: 2
    border.color: Color.blend(Color.accentStrong,Color.bgSurface,0.75)

    signal removeResults()

    signal enterPressed()


    onSelectChanged: {
        //console.log(select)
    }

    function resetScroll() {
        list.resetScroll()
    }

    onResultsChanged: {
        resetSelection()
        execList = [] 
        for (const result of results) {
            execList.push(result.exec)
        }
        mouse.bypass = 1
        mouse.visible = true
    }

    function scrollDown() {
        if (bottom_visible - select == -1 && bottom_visible < results.length - 1) {
            return true
        }
        return false
    }

    function scrollUp() {
        if (select - top_visible == -1 && top_visible > 0) {
            return true
        }
        return false
    }

    function resetSelection() {
        select = 0
    }

    Component.onCompleted: {
        KeyHandlers.pressed.connect((key) => {
            if (key == Qt.Key_Up && select > 0) {
                select -= 1
                if (scrollUp()) list.advanceScroll(-Math.min(select+1,6))
            } else if ( (key == Qt.Key_Down || key == Qt.Key_Tab) && select < results.length - 1) {
                select += 1
                if (scrollDown()) list.advanceScroll(Math.min(results.length - select,6))
            } else if (key == Qt.Key_Return ) {
                preEnter.restart()
            }
        })
    }

    Timer {
        id: preEnter

        property int timer: 0

        interval: 1
        onTriggered: {
            console.log(timer)
            if (root.results.length > 0) {
                //console.log(root.animationRunning)
                //console.log("entered")
                runexec.command = ["bash", "-c", root.execList[root.select]]
                runexec.startDetached()
                root.enterPressed()
                preEnter.timer = 0
                return
            }
            preEnter.timer += 1
            if (preEnter.timer >= 20) {preEnter.timer = 0; return}
            preEnter.restart()
        }
    }

    MouseArea {

        id: mouse

        property int bypass: 1

        anchors.fill: parent
        z:2
        hoverEnabled: true
        preventStealing:true
        onPositionChanged: {
            //console.log("mousemoved")
            if (bypass == 1) {
                bypass = 0
                return
            }
            visible = !visible
        }
    }

    Process {
        id: runexec
    }

    color: Color.bgSurface

    List {

        id: list

        anchors.fill: parent
        anchors.topMargin: 18

        padding: 9
        spacing: 10
        bg_color: "transparent"
        container_color: "transparent"
        container_radius: Config.radius + 5 
        container_right_margin: scroller_implicitWidth ? 0 : 8
        container_left_margin: 8
        container_bottom_margin: 2

        items_data: root.results

        items: Loader {
            id: results_items
            width: list.container_implicitWidth
            height: 60
            active: list.visible

            required property int index
            required property string name
            required property string exec
            required property string icon
            required property string refresh

            sourceComponent: Rectangle {

                //onAdd: if (app.refresh == "true") addAnimation.start()

                Component.onCompleted: {
                    /*
                     root.removeResults.connect(() => {
                         if (app.refresh == "true") {
                             removeAnimaton.start()
                         }
                     })
                     */
                    if (app.refresh == "true") addAnimation.start()
                }

                SequentialAnimation {
                    id: addAnimation
                    ScriptAction {
                        script: {
                            root.animationRunning = true
                        }
                    }
                    PropertyAction {
                        target: app
                        property: "x"
                        value: 100
                    }
                    PropertyAction {
                        target: app
                        property: "opacity"
                        value: 0
                    }
                    PauseAnimation {
                        duration: Math.abs(app.index * 50)
                    }
                    ParallelAnimation {
                        NumberAnimation {
                            target: app
                            property: "x"
                            duration: 250
                            from: 100
                            to: 0
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: app
                            property: "opacity"
                            duration: 250
                            from: 0
                            to: 1
                            easing.type: Easing.OutCubic
                        }
                    }
                    ScriptAction {
                        script: {
                            root.animationRunning = false
                        }
                    }
                }


                id: app

                property int index: results_items.index
                property string name: results_items.name
                property string exec: results_items.exec
                property string icon: results_items.icon
                property string refresh: results_items.refresh

                property bool selected: root.select == index

                Layout.leftMargin: 100

                implicitHeight: 60
                implicitWidth: list.container_implicitWidth

                color: selected ? Color.accentStrong : Qt.rgba(Color.accentStrong.r,Color.accentStrong.g,Color.accentStrong.b,0.0)

                Behavior on color {ColorAnimation {duration: 100; easing.type: Easing.OutCubic}}

                radius: Config.radius

                MouseControl {

                    anchors.fill: parent

                    hoverEnabled: true

                    onEntered: {
                        if (!containsMouse) return
                        root.select = app.index
                    }

                    onReleased: {
                        if (!containsMouse) return
                        runexec.command = ["bash", "-c", app.exec]
                        runexec.startDetached()
                        root.enterPressed()
                    }
                }

                RowLayout {

                    anchors.verticalCenter: parent.verticalCenter

                    spacing: 10

                    ClippingRectangle {

                        id: icon

                        visible: {
                            if (app.icon == "google" || app.icon == "calc") return false
                            return true
                        }

                        Layout.leftMargin: 12*0.85

                        implicitWidth: implicitHeight
                        implicitHeight: 38*(1/0.9)

                        scale: app.selected ? 1 : 0.9
                        transform: Translate {
                            y: 0.9
                        }

                        Behavior on scale {NumberAnimation {duration: 400; easing.type: Easing.OutCubic}}

                        color: "transparent"

                        radius: list.container_radius - 12

                        Image {

                            id: app_icon

                            anchors.fill: parent

                            visible: source != "image://icon/exception"

                            source: "image://icon/" + HyprInfo.iconFetch(app.icon, app.name)

                            cache: false

                            asynchronous: true
                            smooth: true

                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !app_icon.visible
                            text: "\udb82\udcc6"
                            font.family: Fonts.zalandosans_font
                            font.pointSize: 26
                            font.weight: 1000
                            color: Color.textPrimary
                        }


                        layer.enabled: true
                        layer.effect: DropShadow {
                            radius: 10
                            samples: 10
                            horizontalOffset: 0
                            verticalOffset: 0
                            color: Color.transparent(Color.bgBase,0.2)
                            transparentBorder: true
                        }
                    }

                    Text {

                        id: app_name

                        text: `${app.name}`
                        color: app.selected ? Color.textSecondary : Color.textPrimary
                        font.family: Fonts.system
                        font.pointSize: 12

                        Layout.leftMargin: icon.visible ? (2*app.selected) : 18

                        scale: app.selected ? 1.01 : 1

                        Behavior on scale {NumberAnimation {duration: 400; easing.type: Easing.OutCubic}}
                        Behavior on Layout.leftMargin {NumberAnimation {duration: 400; easing.type: Easing.OutCubic}}

                        font.weight: app.selected ? 700 : 600

                    }

                }



            }
        }
    }
}
