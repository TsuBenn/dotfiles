pragma ComponentBehavior:Bound

import qs.services

import QtQuick
import QtQuick.Layouts

Rectangle {

    id: root

    onVisibleChanged: {

    }

    property int spacing: 0
    property bool round: false
    property bool centered: false
    property string color: "light blue"

    anchors.fill: parent

    RowLayout {

        anchors.bottom: !root.centered ? parent.bottom : undefined
        anchors.centerIn: root.centered ? parent : undefined
        anchors.horizontalCenter: !root.centered ? parent.horizontalCenter : undefined

        spacing: root.spacing

        Repeater {
            model: Cava.points

            delegate: Rectangle {

                Layout.alignment: !root.centered ? (Qt.AlignBottom | Qt.AlignHCenter) : Qt.AlignVCenter

                required property int modelData

                radius: root.round ? implicitWidth/2 : 0
                bottomRightRadius: root.centered ? undefined : 0
                bottomLeftRadius: root.centered ? undefined : 0

                implicitHeight: !root.centered ? (modelData/100)*root.height : (modelData/100)*root.height*0.5 + implicitWidth

                Behavior on implicitHeight {NumberAnimation {duration: 100}}

                implicitWidth: root.width/Cava.bars - root.spacing - root.spacing/Cava.bars

                color: root.color

            }

        }

    }

}

