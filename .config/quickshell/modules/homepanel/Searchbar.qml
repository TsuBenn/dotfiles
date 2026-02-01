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

    property bool animationRunning: false

    implicitWidth: preferedWidth
    implicitHeight: 40
    radius: implicitHeight/2

    color: Color.bgSurface

    border.color: searchtext.text ? Color.accentStrong : Color.blend(Color.accentStrong,Color.bgSurface,0.75)
    border.width: searchtext.text ? 3 : 2

    Behavior on border.color {ColorAnimation {duration: 400; easing.type: Easing.OutCubic}}
    Behavior on border.width {NumberAnimation {duration: 400; easing.type: Easing.OutCubic}}

    signal textChanged()

    RowLayout {

        x: 18
        y: 0.8

        spacing: 6

        Text {

            id: searchicon

            text: "\ue68f"
            color: Color.accentStrong
            font.family: Fonts.system
            font.pointSize: 12
            font.weight: 700
        }

        TextField {

            id: searchtext

            property bool newsearch: true

            onVisibleChanged: text = ""

            implicitWidth: Math.max(70, contentWidth + 20) + 100*(searchtext.text == "")

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
                root.updateQuery(searchtext.text)
                root.textChanged()
            }

            focus: true

            implicitHeight: root.implicitHeight

            background: Item {}

            focusReason: Qt.PopupFocusReason

            placeholderText: qsTr("Search")
            placeholderTextColor: Color.textDisabled
            font.family: Fonts.system
            font.pointSize: 12
            font.weight: 700

            color: Color.textPrimary

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
                color: Color.textDisabled

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
                    color: Color.textDisabled

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

    function updateQuery(query: string) {
        backend.exec(["python", ".config/quickshell/services/backend/launcher.py", query])
    }

    Process {
        id: backend

        stdout: StdioCollector {
            onStreamFinished: {
                //console.log(text)
                if (!text) return
                root.results = JSON.parse(text.trim())
            }
        }
    }
}


