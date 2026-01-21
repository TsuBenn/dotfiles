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

    property real    container_top_margin    : 0
    property real    container_left_margin   : 0
    property real    container_right_margin  : 0
    property real    container_bottom_margin : 0

    property color  scroller_bg_color       : Color.secondary
    property color  scroller_fg_color       : Color.icon_sink
    property int    scroller_width          : 5
    property int    scrolling_sen           : (content.implicitHeight/items_data.length)-(spacing/items_data.length)
    property bool   show_scroller           : true
    property bool   scroller_needed         : scroller.scroller_needed

    property var    items_data              : AudioInfo.sinks

    property Component items

    clip: true

    property int container_implicitWidth: container.width

    property int scroller_implicitWidth: {
        scroller.scroller_needed ? list.scroller_width+list.padding : 0
    }

    property real prefered_scroll_progress: 0
    property real scroll_progress: prefered_scroll_progress
    Behavior on scroll_progress {
        SequentialAnimation {
            NumberAnimation {
                id: scroll_smoother
                duration: 200
                easing.type: Easing.OutCubic
            } 
        }
    }

    implicitWidth: box_height
    implicitHeight: box_width

    color: list.bg_color

    property real progressStep: (content.height/list.items_data.length) + (list.spacing/(list.items_data.length-1))
    property real stepProgress: Math.round(Math.abs((list.prefered_scroll_progress)/list.progressStep))

    property real maxScroll: {
        if (content.height > list.height-list.spacing*2-list.container_bottom_margin) {
            return -content.height-list.padding*2 + list.height - list.container_bottom_margin - list.container_top_margin
        } else {
            return 0
        }
    }

    function snapProgress() {
        if (content.y > 0) {
            list.prefered_scroll_progress = 0
            return
        }
        else if (content.y < list.maxScroll) {
            list.prefered_scroll_progress = list.maxScroll
            return
        }
        list.prefered_scroll_progress = Math.round(list.scroll_progress/progressStep)*progressStep
    }

    function advanceScroll(interval : int) {
        list.prefered_scroll_progress -= (progressStep)*interval
    }

    function resetScroll() {
        prefered_scroll_progress = 0
    }

    MouseControl {

        anchors.fill: parent

        acceptedButtons: Qt.NoButton

        preventStealing: true
        propagateComposedEvents: true

        hoverEnabled: false

        z:1

        onWheelDelta: (delta) => {

            const sen = list.scrolling_sen

            list.prefered_scroll_progress += delta * list.progressStep

            console.log(list.scroll_progress)

            if (list.prefered_scroll_progress > 0) {
                list.prefered_scroll_progress = 0
                return
            }
            else if (list.prefered_scroll_progress < list.maxScroll) {
                list.prefered_scroll_progress = list.maxScroll
                return
            }
        }
    }

    ClippingRectangle {

        property bool scroller_needed: list.show_scroller && ((list.max_height-list.padding-list.container_bottom_margin-list.container_top_margin)/(-list.maxScroll + (list.max_height-list.padding-list.container_bottom_margin-list.container_top_margin))) < 1

        id: scroller

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.topMargin: list.padding + list.container_radius/2 + list.container_top_margin/2
        anchors.bottomMargin: list.padding + list.container_bottom_margin/2 + list.container_radius/2
        anchors.rightMargin: list.padding

        radius: implicitWidth/2

        implicitWidth: scroller_needed ? list.scroller_width : 0
        Behavior on implicitWidth {NumberAnimation {duration: 300; easing.type: Easing.OutCubic}}

        color: list.scroller_bg_color


        MouseControl {
            anchors.fill: parent

            property real relativeY: (-((mouseY - scroller_thumb.height/2)/scroller.height)*content.implicitHeight)

            cursorShape: Qt.OpenHandCursor

            onHeld: {
                list.prefered_scroll_progress = relativeY
            }
            onReleased: {
                if (relativeY > 0) {
                    scroller_overshootup.start()
                } else if (relativeY < list.maxScroll) {
                    scroller_overshootdown.start()
                }
                list.snapProgress()
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

            implicitHeight: (container.height/(contentContainer.height)*scroller.height)
            Behavior on implicitHeight {NumberAnimation {duration: 500; easing.type: Easing.OutCubic}}

        }

    }

    ClippingRectangle {

        id: container

        anchors.fill: parent
        anchors.topMargin: list.padding + list.container_top_margin
        anchors.leftMargin: list.padding + list.container_left_margin
        anchors.rightMargin: list.padding + list.scroller_implicitWidth + list.container_right_margin
        anchors.bottomMargin: list.padding + list.container_bottom_margin

        Behavior on anchors.rightMargin {NumberAnimation {duration: 300; easing.type: Easing.OutCubic}}

        y: list.container_top_margin

        radius: list.container_radius-list.padding

        color: list.container_color

        clip: true

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
