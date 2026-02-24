pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {

    id: root

    width: 400
    height: 400
    visible: true
    title: "AyanoAI"

    color: "transparent"

    flags: Qt.Window
    | Qt.FramelessWindowHint
    | Qt.WindowStaysOnTopHint
    | Qt.Tool

    property var stateModels: [
        {
            title: "Happy",
            path: "../assets/ayano_happy.png"
        },
        {
            title: "Sad",
            path: "../assets/ayano_sad.png"
        },
        {
            title: "Angry",
            path: "../assets/ayano_angry.png"
        },
    ]

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        Rectangle {

            anchors.left: parent.left
            anchors.top: parent.top

            implicitWidth: 200
            implicitHeight: 500

            ColumnLayout {

                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 10

                spacing: 10

                Repeater {

                    model: root.stateModels

                    delegate: Button {


                        required property string title
                        required property string path

                        implicitWidth: 180
                        implicitHeight: 30
                        text: `${title}`

                        onPressed: {
                            character.source = path
                        }

                    }

                }

            }

        }

        Image {
            id: character

            anchors.fill: parent

            fillMode: Image.PreserveAspectFit
            source: "../assets/ayano_angry.png"
        }

    }
}
