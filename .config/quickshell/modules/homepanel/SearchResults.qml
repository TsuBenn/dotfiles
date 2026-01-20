pragma ComponentBehavior: Bound

import qs.assets
import qs.modules.homepanel
import qs.modules.common

import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

ClippingRectangle {

    id: root

    property int searchbar_offset
    property int select: 0
    property int top_visible: 0
    property int bottom_visible: 5
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
        if (bottom_visible - select == 1 && bottom_visible < results.length - 1) {
            top_visible += 1
            bottom_visible += 1
            return true
        }
        return false
    }

    function scrollUp() {
        if (select - top_visible == 1 && top_visible > 0) {
            top_visible -= 1
            bottom_visible -= 1
            return true
        }
        return false
    }

    function resetSelection() {
        select = 0
        top_visible = 0
        bottom_visible = 5
    }

    Component.onCompleted: {
        KeyHandlers.released.connect((key) => {
            if (key == Qt.Key_Up && select > 0) {
                select -= 1
                if (scrollUp()) list.advanceScroll(-1)
            } else if (key == Qt.Key_Down && select < results.length - 1) {
                select += 1
                if (scrollDown()) list.advanceScroll(1)
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

    color: "white"

    List {

        id: list

        anchors.fill: parent
        anchors.topMargin: 20

        padding: 9
        spacing: 10
        bg_color: "white"
        container_color: "transparent"
        container_radius: Config.radius + 5 
        container_left_margin: 8
        container_bottom_margin: 8

        items_data: root.results
        items: Rectangle {

            id: app

            required property int index
            required property string name
            required property string exec
            required property string icon

            implicitHeight: 60
            implicitWidth: list.container_implicitWidth

            color: root.select == index ? "#dddddd" : "transparent"
            radius: Config.radius


            RowLayout {

                anchors.verticalCenter: parent.verticalCenter

                spacing: 20

                ClippingRectangle {

                    Layout.leftMargin: 10

                    implicitWidth: 40
                    implicitHeight: 40

                    color: "transparent"

                    radius: list.container_radius - list.padding

                    Image {

                        anchors.fill: parent


                        source: app.icon ? "image://icon/" + app.icon : "image://icon/kitty"
                    }
                }

                Text {
                    text: `${app.name} (${app.index})`
                    font.family: Fonts.system
                    font.pointSize: 12
                    font.weight: 700
                }

            }



        }
    }
}
