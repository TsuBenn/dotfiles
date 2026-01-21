import qs.services
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

    color: Color.primary

    border.color: searchtext.text ? Qt.darker(Color.accent,1.1) : Qt.lighter(Color.primary,1.3)
    border.width: 3
    Behavior on border.color {ColorAnimation {duration: 500; easing.type: Easing.OutCubic}}

    signal textChanged()

    RowLayout {

        x: 18
        y: 0.8

        spacing: 6

        Text {

            id: searchicon

            text: "\ue68f"
            color: Color.icon_sink
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
                    closeSuggest.start()
                    newsearch = true
                    return
                }
                if (text == " ") {
                    text = ""
                    return
                }

                if (text.length == 1 && newsearch) {
                    newsearch = false
                    if (text[0] == "=" || text[0] == ">" || text[0] == "?" || text[0] == "/") {
                        text += " "
                    }
                }
                if (text.length == 1 && !newsearch) {
                    newsearch = true
                    if (text[0] == "=" || text[0] == ">" || text[0] == "?" || text[0] == "/") {
                        text = ""
                    }
                }

                if (text.length < 2) {
                    openSuggest.stop()
                    closeSuggest.stop()
                    suggestion.opacity = 0
                    suggest.restart()
                    return
                }
                closeSuggest.start()
                updatequerycall.restart()
                root.textChanged()
            }

            focus: true

            implicitHeight: root.implicitHeight

            background: Item {}

            focusReason: Qt.PopupFocusReason

            placeholderText: qsTr("Search")
            placeholderTextColor: Color.text_sink
            font.family: Fonts.system
            font.pointSize: 12
            font.weight: 700

            color: Color.text

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
                color: Color.text_sink

                Text {

                    id: suggestion

                    opacity: 0

                    anchors.left: parent.right
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter

                    text: "(Type atleast 2 letters to search)"
                    font.family: Fonts.system
                    font.pointSize: 10
                    font.weight: 700
                    color: Color.text_sink

                    NumberAnimation {
                        id: openSuggest
                        target: suggestion
                        property: "opacity"
                        duration: 500
                        to: 1
                        easing.type: Easing.OutCubic
                    }

                    NumberAnimation {
                        id: closeSuggest
                        target: suggestion
                        property: "opacity"
                        duration: 500
                        to: 0
                        easing.type: Easing.OutCubic
                    }

                }

                Timer {
                    id: suggest
                    interval: 1500
                    onTriggered: if (searchtext.text.length == 1) openSuggest.start()
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


