pragma ComponentBehavior:Bound

import qs.services 

import Quickshell
import Quickshell.Widgets
import QtQuick.Layouts
import QtQuick

ClippingRectangle {

    id: root

    property real box_width          : 28
    property real box_height         : 300
    property int  padding            : 0
    property var  bg_color           : "gray"
    property var  bg_hover           : "gray"
    property var  fg_color           : "light gray"
    property var  fg_hover           : "light gray"
    property real percentage         : SystemInfo.cpuusage               // Only percentage value (Do math or whatever)

    property real preferedPercentage : SystemInfo.cpuusage

    property bool interactive        : false

    signal pressed()
    signal released()
    signal entered()
    signal exited()
    signal adjusted() 

    function syncBar() {
        sync.running = true
    }

    Timer {
        id:sync

        interval: 100
        repeat: false
        onTriggered: {
            root.percentage = Qt.binding(()=>root.preferedPercentage)
        }
    }

    Layout.alignment: Qt.AlignCenter

    implicitWidth: root.box_width
    implicitHeight: root.box_height
    radius: height/2
    color: root.bg_color

    MouseControl {

        visible: root.interactive

        hoverEnabled: true

        function percentageClamp() {
            root.percentage = Math.min(Math.max(root.percentage, 0), 100)
        }

        implicitWidth: root.box_width + root.padding
        implicitHeight: root.box_height + root.padding

        anchors.centerIn: parent

        onHeld: (button) => {
            if (button == Qt.LeftButton) {
                root.percentage = (1 - mouseY/root.implicitHeight).toFixed(2)*100
                percentageClamp()
            }
            else if (button == Qt.RightButton) {
                root.percentage = (1 - mouseY/root.implicitHeight).toFixed(1)*100
                percentageClamp()
            }
        }

        onWheelDelta: (delta) => {
            root.percentage += delta*5
            percentageClamp()
            root.adjusted()
        }

        onPressed: {
            root.pressed()
        }

        onReleased: {
            root.adjusted()
            root.released()
        }

        onEntered: {
            root.entered()
        }

        onExited: {
            root.exited()
        }

    }

    Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.left: parent.left

        implicitHeight: parent.height*root.percentage/100

        Behavior on implicitHeight {NumberAnimation {duration: 200; easing.type: Easing.OutCubic}}

        color: root.fg_color
        topRightRadius: parent.height/2
        topLeftRadius: parent.height/2
    }

}

