pragma ComponentBehavior:Bound

import qs.services

import QtQuick
import QtQuick.Layouts

Item {

    id: root

    property int    spacing  : 0
    property bool   round    : false
    property bool   centered : false
    property bool   flipped  : true
    property string color    : "white"

    anchors.fill: parent

    RowLayout {


        anchors.bottom: !parent.centered ? parent.bottom : null
        anchors.centerIn: parent.centered ? parent : null
        anchors.horizontalCenter: !parent.centered ? parent.horizontalCenter : null

        spacing: root.spacing

        Repeater {

            model: root.visible ? (root.flipped ? Cava.pointsFlipped : Cava.points) : []

            delegate: Rectangle {

                Layout.alignment: !root.centered ? (Qt.AlignBottom | Qt.AlignHCenter) : Qt.AlignVCenter

                required property int modelData

                radius: root.round ? implicitWidth/2 : 0
                bottomRightRadius: root.centered ? null : 0
                bottomLeftRadius: root.centered ? null : 0

                implicitHeight: !root.centered ? (modelData/100)*root.height : (modelData/100)*root.height*0.5 + implicitWidth

                implicitWidth: root.width/Cava.bars - root.spacing - root.spacing/Cava.bars

                color: root.color

            }

        }

    }

}

