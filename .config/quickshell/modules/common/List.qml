pragma ComponentBehavior:Bound

import qs.modules.common 
import qs.services

import Quickshell
import Quickshell.Widgets
import QtQuick.Layouts
import QtQuick

ClippingRectangle {

    id: list

    property int    box_height
    property int    box_width
    property int    padding
    property int    spacing

    property int    max_height              : implicitHeight
    property string bg_color                : "#aaaaaa"
    property string container_color         : "#aaaaaa"
    property int    container_radius        : 18

    property int    container_top_margin    : 0
    property int    container_left_margin   : 0
    property int    container_right_margin  : 0
    property int    container_bottom_margin : 0

    property string scroller_bg_color       : "#555555"
    property string scroller_fg_color       : "gray"
    property int    scroller_width          : 5
    property int    scrolling_sen           : (content.implicitHeight/items_data.length)-(spacing/items_data.length)
    property bool   show_scroller           : true

    property var    items_data              : AudioInfo.sinks

    property Component items

    clip: true

    property int container_implicitWidth: container.width

    property int scroller_implicitWidth: {
        scroller.visible ? list.scroller_width+list.padding : 0
    }

    property real scroll_progress: 0
    Behavior on scroll_progress {NumberAnimation {duration: 100; easing.type: Easing.OutQuad}}

    implicitWidth: box_height
    implicitHeight: box_width

    color: list.bg_color

    property real maxScroll: {
        if (content.implicitHeight > list.implicitHeight-list.spacing*2-list.container_bottom_margin) {
            return -content.implicitHeight-list.padding*2 + list.implicitHeight - list.container_bottom_margin - list.container_top_margin
        } else {
            return 0
        }
    }

    MouseControl {

        anchors.fill: parent

        acceptedButtons: Qt.NoButton

        preventStealing: true
        propagateComposedEvents: true

        hoverEnabled: false

        z:1

        onWheelDelta: (delta) => {

            listOvershootup.stop() 
            listOvershootdown.stop() 

            const sen = list.scrolling_sen

            list.scroll_progress += delta * sen

            if (content.y + delta * sen > 0) {
                listOvershootup.start() 
                return
            }
            else if (content.y + delta * sen < list.maxScroll) {
                listOvershootdown.start()
                return
            }


        }
    }

    ClippingRectangle {

        visible: list.show_scroller && ((list.max_height-list.padding-list.container_bottom_margin-list.container_top_margin)/(-list.maxScroll + (list.max_height-list.padding-list.container_bottom_margin-list.container_top_margin))) < 1

        id: scroller


        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.topMargin: list.padding + list.container_radius/2 + list.container_top_margin/2
        anchors.bottomMargin: list.padding + list.container_bottom_margin/2 + list.container_radius/2
        anchors.rightMargin: list.padding

        radius: implicitWidth/2

        implicitWidth: visible ? list.scroller_width : 0

        color: list.scroller_bg_color


        MouseControl {
            anchors.fill: parent

            property real relativeY: (-((mouseY - scroller_thumb.height/2)/scroller.height)*content.implicitHeight)

            cursorShape: Qt.OpenHandCursor

            onHeld: {
                list.scroll_progress = relativeY
            }
            onReleased: {
                if (relativeY > 0) {
                    scroller_overshootup.start()
                } else if (relativeY < list.maxScroll) {
                    scroller_overshootdown.start()
                }
            }

        }

        NumberAnimation {
            id: scroller_overshootup
            target: list
            property: "scroll_progress"
            duration: 200
            to: 0
            easing.type: Easing.OutQuart
        }
        NumberAnimation {
            id: scroller_overshootdown
            target: list
            property: "scroll_progress"
            duration: 200
            to: list.maxScroll
            easing.type: Easing.OutQuart
        }

        Rectangle {

            id: scroller_thumb

            anchors.right: parent.right
            anchors.left: parent.left

            radius: width/2

            y: (list.scroll_progress/list.maxScroll)*(scroller.height-implicitHeight)

            color: list.scroller_fg_color

            implicitHeight: (contentContainer.implicitHeight/(-list.maxScroll + contentContainer.implicitHeight))*scroller.height

        }

    }

    SequentialAnimation {
        id: listOvershootup
        NumberAnimation {
            target: list
            property: "scroll_progress"
            duration: 100
            to: list.scrolling_sen*0.5
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: list
            property: "scroll_progress"
            duration: 100
            to: 0
            easing.type: Easing.OutQuad
        }
    }
    SequentialAnimation {
        id: listOvershootdown
        NumberAnimation {
            target: list
            property: "scroll_progress"
            duration: 100
            to: list.maxScroll - list.scrolling_sen*0.5
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: list
            property: "scroll_progress"
            duration: 100
            to: list.maxScroll
            easing.type: Easing.OutQuad
        }
    }

    ClippingRectangle {

        id: container

        anchors.fill: parent
        anchors.topMargin: list.padding + list.container_top_margin
        anchors.leftMargin: list.padding + list.container_left_margin
        anchors.rightMargin: list.padding + list.scroller_implicitWidth + list.container_right_margin
        anchors.bottomMargin: list.padding + list.container_bottom_margin


        y: list.container_top_margin

        radius: list.container_radius-list.padding

        color: list.container_color


        Item {

            id: contentContainer

            implicitWidth: parent.implicitWidth
            implicitHeight: content.implicitHeight


            ColumnLayout {

                id: content

                spacing: list.spacing

                y: list.scroll_progress

                Repeater {

                    model: list.items_data

                    delegate: list.items

                }
            }

        }
    }

}
