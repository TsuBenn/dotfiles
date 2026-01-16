import qs.modules.homepanel
import qs.assets

import Quickshell
import QtQuick
import QtQuick.Controls

Rectangle {

    property int preferedWidth

    implicitWidth: preferedWidth
    implicitHeight: 40
    radius: implicitHeight/2

    TextField {

        id: searchtext

        onVisibleChanged: text = ""

        onTextChanged: {
            if (text == "") return
            if (text == "Settings:" || text == "Fuzzy:" || text == "Calculate:") {
                text = ""
                return
            }
            if (text == ">") {
                if (text.length == 1) {
                    text = "Settings: "
                }
                console.log("Setting search")
            } else if (text == "/") {
                if (text.length == 1) {
                    text = "Fuzzy: "
                }
                console.log("Fuzzy")
            } else if (text == "=") {
                if (text.length == 1) {
                    text = "Calculate: "
                }
                console.log("Calculate")
            } 
        }

        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 1

        leftPadding: 18
        rightPadding: 18

        focus: true

        implicitWidth: parent.implicitWidth
        implicitHeight: parent.implicitHeight

        background: Item {}

        focusReason: Qt.PopupFocusReason

        placeholderText: qsTr("\ue68f Search")
        font.family: Fonts.system
        font.pointSize: 12
        font.weight: 700

        color: text.length ? "black" : "gray"

    }

}
