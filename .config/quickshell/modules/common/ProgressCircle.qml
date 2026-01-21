pragma ComponentBehavior:Bound

import qs.assets 
import qs.services 

import Quickshell
import Quickshell.Widgets
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick

ColumnLayout {

    id: root

    property color  bg_color      : Color.secondary
    property color  fg_color      : Color.accent
    property int    thickness     : 5
    property int    radius        : 25
    property real   percentage    : SystemInfo.cpuusage
    property real   maxPercentage : 1
    property real   angle         : 0
    property bool   autoAngle     : true
    property bool   autoOffset    : true

    property string icon          : "\uf0ad"
    property string icon_font     : Fonts.system
    property int    icon_size     : 20
    property int    icon_weight   : 600
    property bool   icon_offset   : true
    property color  icon_color    : Color.accent

    property string label         : "Text"
    property int    label_height  : 0
    property string label_type    : "In"                  // Possible: In, Out
    property string label_show    : "true"                // Possible: true, false
    property string font          : Fonts.system
    property int    font_weight   : 600
    property int    font_size     : 13
    property int    font_spacing  : 0
    property color  font_color    : Color.text

    property real desiredWidth: container.implicitWidth
    property real desiredHeight: container.implicitHeight

    implicitHeight: root.radius*2
    implicitWidth: implicitHeight

    component Label: Rectangle {
        Layout.alignment: Qt.AlignCenter

        implicitWidth: label.implicitWidth
        implicitHeight: root.label_height > 0 ? root.label_height : label.implicitHeight
        visible: root.label == "" ? false : true
        color: "transparent"

        Text {
            id: label
            anchors.centerIn: parent
            text: root.label
            font.family: root.font
            font.weight: root.font_weight
            font.pointSize: root.font_size
            font.wordSpacing: root.font_spacing
            color: root.font_color
        }
    }

    component Circle: Shape {

        id: circle
        property color color: "black"
        property real percentage: 1
        property real thickness: root.thickness

        implicitHeight: root.radius * 2
        implicitWidth: height
        horizontalAlignment: Qt.AlignCenter
        verticalAlignment: Qt.AlignCenter
        preferredRendererType: Shape.CurveRenderer

        rotation: root.autoAngle && root.maxPercentage < 1 ? -180 + ((1 - root.maxPercentage)*360*0.5) : root.angle

        ShapePath {

            id: path

            startX: root.radius + root.thickness/2
            startY: 0 + root.thickness/2
            fillColor: "transparent"
            strokeColor: circle.color
            strokeWidth: circle.thickness
            capStyle: ShapePath.RoundCap

            trim.end: circle.percentage
            Behavior on trim.end {NumberAnimation {duration: 200; easing.type: Easing.OutCubic} }

            PathArc {
                x: root.radius + root.thickness/2
                y: root.radius * 2 + root.thickness/2
                radiusX: root.radius
                radiusY: radiusX
                useLargeArc: true
            }
            PathArc {
                x: root.radius + root.thickness/2
                y: 0 + root.thickness/2
                radiusX: root.radius
                radiusY: radiusX
                useLargeArc: true
            }

        }
    }

    Rectangle {

        id: container

        Layout.alignment: Qt.AlignCenter

        implicitHeight: root.autoOffset ? progresscirlce.implicitHeight - (root.radius - Math.sqrt((root.radius ** 2) * 0.5 * (Math.cos(2*Math.PI*(1 - root.maxPercentage)) + 1))) : progresscirlce.implicitHeight
        implicitWidth: progresscirlce.implicitWidth

        color: "transparent"

        Circle {
            id: progresscirlce
            color: root.bg_color
            percentage: root.maxPercentage
        }
        Circle {
            color: root.fg_color
            percentage: root.percentage/100 * root.maxPercentage
            thickness: root.thickness + 0.5
        }

        Text {
            id: icon

            anchors.centerIn: {
                if (root.icon_offset)
                return container
                else
                return progresscirlce
            }

            text: root.icon
            font.family: root.icon_font
            font.pointSize: root.icon_size
            font.weight: root.icon_weight
            color: root.icon_color

            Label {
                anchors.top: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: -parent.implicitHeight*0.1

                visible: {
                    if (root.label_type == "In" && root.label_show == "true") {
                        return true
                    } else { return false }
                }
            }
        }

    }

    Label {
        visible: {
            if (root.label_type == "Out" && root.label_show == "true") {
                return true
            } else { return false }
        }
    }
}
