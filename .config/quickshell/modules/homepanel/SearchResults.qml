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

    property var execList: []

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
        KeyHandlers.released.connect((key) => {
            if (key == Qt.Key_Up && select > 0) {
                select -= 1
                if (scrollUp()) list.advanceScroll(-Math.min(select+1,6))
            } else if (key == Qt.Key_Down && select < results.length - 1) {
                select += 1
                if (scrollDown()) list.advanceScroll(Math.min(results.length - select,6))
            } else if (key == Qt.Key_Return) {
                runexec.command = ["bash", "-c", execList[select]]
                runexec.startDetached()
                root.enterPressed()
            }
        })
    }

    Process {
        id: runexec
    }

    color: Color.bgSurface

    List {

        id: list

        anchors.fill: parent
        anchors.topMargin: 20

        padding: 9
        spacing: 10
        bg_color: "transparent"
        container_color: "transparent"
        container_radius: Config.radius + 5 
        container_right_margin: scroller_implicitWidth ? 0 : 8
        container_left_margin: 8
        container_bottom_margin: 4

        items_data: root.results
        items: Rectangle {

            Component.onCompleted: {
                spawn.start()
            }

            SequentialAnimation {
                id: spawn
                PauseAnimation {
                    duration: app.index * 500
                }
                NumberAnimation {
                    property: "opacity"
                    duration: 500
                    from: 0
                    to: 1
                    easing.type: Easing.OutCubic
                }
            }

            id: app

            required property int index
            required property string name
            required property string exec
            required property string icon

            property bool selected: root.select == index

            implicitHeight: 60
            implicitWidth: list.container_implicitWidth

            color: selected ? Color.accentStrong : "transparent"
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

                spacing: 20

                ClippingRectangle {

                    Layout.leftMargin: 12

                    implicitWidth: 38
                    implicitHeight: implicitWidth

                    color: "transparent"

                    radius: list.container_radius - list.padding

                    Image {

                        anchors.fill: parent

                        source: app.icon ? "image://icon/" + app.icon : "image://icon/kitty"

                    }

                    layer.enabled: true
                    layer.effect: DropShadow {
                        radius: 10
                        samples: 10
                        horizontalOffset: 0
                        verticalOffset: 0
                        color: Qt.rgba(0.0,0.0,0.0,0.2)
                        transparentBorder: true
                    }
                }

                Text {
                    text: `${app.name}`
                    color: app.selected ? Color.textPrimary : Color.textPrimary
                    font.family: Fonts.system
                    font.pointSize: 12
                    font.weight: app.selected ? 700 : 600
                }

            }



        }
    }
}
