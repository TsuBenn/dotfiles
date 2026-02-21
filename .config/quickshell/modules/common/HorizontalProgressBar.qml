pragma ComponentBehavior:Bound

import qs.services 

import Quickshell
import Quickshell.Widgets
import QtQuick.Layouts
import QtQuick

ClippingRectangle {

    id: root

    property real box_width          : 300
    property real box_height         : 28
    property int  padding            : 0
    property var  bg_color           : Color.bgMuted
    property var  bg_hover           : Color.bgMuted
    property var  fg_color           : Color.accentStrong
    property var  fg_hover           : Color.accentStrong
    property real percentage         : preferedPercentage               // Only percentage value (Do math or whatever)

    property real preferedPercentage : SystemInfo.cpuusage

    property bool round              : true
    property bool interactive        : false
    property bool containsMouse      : mouse.containsMouse
    property bool containsPress      : mouse.containsPress

    signal pressed()
    signal released()
    signal entered()
    signal exited()
    signal adjusted() 
    signal held() 

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
    radius: (root.box_height/2)*root.round
    color: {
        if (mouse.containsMouse) {
            return root.bg_hover
        } else {
            return root.bg_color
        }
    }

    MouseControl {

        id: mouse

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
                root.percentage = (mouseX/root.implicitWidth).toFixed(2)*100
                percentageClamp()
            }
            else if (button == Qt.RightButton) {
                root.percentage = (mouseX/root.implicitWidth).toFixed(1)*100
                percentageClamp()
            }
            root.held()
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
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left

        implicitWidth: parent.width*root.percentage/100
        Behavior on implicitWidth {NumberAnimation {duration: 200; easing.type: Easing.OutCubic}}

        topRightRadius: (root.box_height/2)*root.round
        bottomRightRadius: (root.box_height/2)*root.round

        color: {
            if (mouse.containsMouse) {
                return root.fg_hover
            } else {
                return root.fg_color
            }
        }

    }

}

