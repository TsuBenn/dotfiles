pragma ComponentBehavior:Bound

import qs.services

import QtQuick
import QtQuick.Layouts

Item {

    id: root

    property int    spacing  : 2
    property bool   round    : false
    property bool   centered : false
    property bool   flipped  : true
    property color  color    : "white"
    property real   maxHeight: height

    anchors.fill: parent

    RowLayout {


        anchors.bottom: !parent.centered ? parent.bottom : undefined
        anchors.centerIn: parent.centered ? parent : undefined
        anchors.horizontalCenter: !parent.centered ? parent.horizontalCenter : undefined

        spacing: root.spacing

        Repeater {

            model: root.visible ? (root.flipped ? Cava.pointsFlipped : Cava.points) : []

            delegate: Rectangle {

                Layout.alignment: !root.centered ? (Qt.AlignBottom | Qt.AlignHCenter) : Qt.AlignVCenter

                required property int modelData

                radius: root.round ? implicitWidth/2 : 0
                bottomRightRadius: root.centered ? undefined : 0
                bottomLeftRadius: root.centered ? undefined : 0

                implicitHeight: !root.centered ? (modelData/100)*root.maxHeight : (modelData/100)*root.maxHeight*0.5 + implicitWidth

                implicitWidth: (root.width - (root.spacing)*(Cava.bars-1))/Cava.bars

                color: root.color

            }

        }

    }

}

