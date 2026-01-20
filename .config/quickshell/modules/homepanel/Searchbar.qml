import qs.assets
import qs.modules.common

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {

    id: root

    property int preferedWidth
    property bool typing: searchtext.text.length > 1
    property var results: []

    implicitWidth: preferedWidth
    implicitHeight: 40
    radius: implicitHeight/2

    border.color: "gray"
    border.width: 3 * (searchtext.text.length >= 1)
    Behavior on border.width {NumberAnimation {duration: 200; easing.type: Easing.OutCubic}}

    signal textChanged()

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

            property bool newsearch: true

            onVisibleChanged: text = ""

            implicitWidth: Math.max(70, contentWidth + 8) + 100*(searchtext.text == "")

            onTextChanged: {
                if (text == "") {
                    suggestion.opacity = 0
                    newsearch = true
                    return
                }
                if (text == " ") {
                    text = ""
                    return
                }

                if (text.length == 1 && newsearch) {
                    newsearch = false
                    if (text[0] == "=" || text[0] == ">" || text[0] == "?") {
                        text += " "
                    }
                }
                if (text.length == 1 && !newsearch) {
                    newsearch = true
                    if (text[0] == "=" || text[0] == ">" || text[0] == "?") {
                        text = ""
                    }
                }

                if (text.length < 2) {
                    suggest.restart()
                    return
                }
                suggestion.opacity = 0
                updatequerycall.restart()
                root.textChanged()
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

            Text {

                id: searchstatus

                x: parent.implicitWidth + 8

                anchors.verticalCenter: parent.verticalCenter

                Behavior on x {NumberAnimation {duration: 200; easing.type: Easing.OutCubic}}

                text: {
                    if (searchtext.text[0] == "?") return "- Google search"
                    else if (searchtext.text[0] == "=") return "- Calculator"
                    else if (searchtext.text[0] == ">") return "- Settings search"
                    else if (searchtext.text[0] == "/") return "- Fuzzy search"
                    return "- App search"
                }

                opacity: searchtext.text != ""

                Behavior on opacity {NumberAnimation {duration: 200; easing.type: Easing.OutCubic}}

                font.family: Fonts.system
                font.pointSize: 12
                font.weight: 700
                color: "gray"

                Text {

                    id: suggestion

                    opacity: 0

                    Behavior on opacity {NumberAnimation {duration: 1000; easing.type: Easing.OutCubic}}

                    anchors.left: parent.right
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter

                    text: "(Type atleast 2 letters to search)"
                    font.family: Fonts.system
                    font.pointSize: 10
                    font.weight: 700
                    color: "gray"
                }

                Timer {
                    id: suggest
                    interval: 1000
                    onTriggered: if (searchtext.text.length == 1) suggestion.opacity = 1
                }

            }

        }

    }

    Timer {

        id: updatequerycall

        interval: 0
        onTriggered: root.updateQuery(searchtext.text)
    }

    function updateQuery(query: string) {

        backend.exec(["python", ".config/quickshell/services/backend/launcher.py", query])
    }

    Process {
        id: backend

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return
                root.results = JSON.parse(text.trim())
            }
        }
    }
}


