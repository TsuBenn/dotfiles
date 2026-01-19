import qs.assets

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {

    id: root

    property int preferedWidth
    property bool typing: searchtext.text.length >= 1
    property var results: []

    implicitWidth: preferedWidth
    implicitHeight: 40
    radius: implicitHeight/2

    border.color: "gray"
    border.width: 3 * (searchtext.text.length >= 1)
    Behavior on border.width {NumberAnimation {duration: 200; easing.type: Easing.OutCubic}}

    RowLayout {

        x: 18
        y: 0.8

        spacing: 6

        Text {

            id: searchicon

            text: "\ue68f"
            font.family: Fonts.system
            font.pointSize: 12
            font.weight: 700
        }

        TextField {

            id: searchtext

            onVisibleChanged: text = ""

            onTextChanged: {
                if (text == "") return
                if (text == " ") {
                    text = ""
                    return
                }
                console.log(text)
                root.updateQuery(text)
            }

            focus: true

            implicitHeight: root.implicitHeight

            background: Item {}

            focusReason: Qt.PopupFocusReason

            placeholderText: qsTr("Search")
            font.family: Fonts.system
            font.pointSize: 12
            font.weight: 700

            color: text.length ? "black" : "gray"

        }
    }

    function updateQuery(query: string) {
        backend.exec(["python", ".config/quickshell/services/backend/launcher.py", query])
    }


    Process {
        id: backend

        stdout: StdioCollector {
            onStreamFinished: {
                console.log(text)
            }
        }
    }
}


