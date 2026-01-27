pragma ComponentBehavior:Bound 

import qs.modules.common
import qs.services
import qs.assets

import QtQuick
import QtQuick.Layouts

RowLayout {
    id: workspace

    Repeater {

        model: 5

        delegate: Rectangle {

            id: wb

            required property int index

            property bool selected: index + 1 == HyprInfo.id

            implicitHeight: 28
            implicitWidth: window.implicitWidth

            Behavior on implicitWidth {NumberAnimation {duration: 200; easing.type: Easing.OutCubic}}
            Behavior on border.width {NumberAnimation {duration: 200; easing.type: Easing.OutCubic}}

            radius: implicitHeight/2

            color: Color.bgBase
            border.width: selected ? 2 : 0
            border.color: Color.accentStrong

            RowLayout {

                id: window
                spacing: 0

                PillButton {

                    box_height: 28
                    box_width: box_height
                    text_padding: 0

                    text: wb.index + 1

                    bg_color: [
                        wb.selected ? Color.accentStrong : Color.bgBase,
                        wb.selected ? Color.accentStrong : Color.bgBase, 
                        wb.selected ? Color.accentStrong : Color.bgBase, 
                    ]
                    fg_color: [
                        wb.selected ? Color.textPrimary : HyprInfo.windowCount(wb.index+1) > 0 ? Color.accentSoft : Color.accentStrong,
                        wb.selected ? Color.textPrimary : Color.accentStrong,
                        wb.selected ? Color.textPrimary : Color.accentStrong, 
                    ]
                    border_width: [0,0,wb.selected ? 0 : 2]

                }

                Repeater {

                    visible: HyprInfo.windowCount(wb.index+1) > 0

                    model: HyprInfo.workspaces[wb.index+1]

                    delegate: Item {

                        required property int index
                        required property string windowclass
                        required property bool focused

                        Layout.rightMargin: 5

                        Component.onCompleted: {
                            if (windowclass == "zen") windowclass = "zen-browser"
                        }

                        visible: index < 4

                        width: 28
                        height: 28

                        Image {

                            visible: index < 3

                            height: 18
                            width: 18
                            smooth: true
                            opacity: focused && wb.selected ? 1 : 0.5

                            Behavior on opacity {NumberAnimation {duration: 200; easing.type: Easing.OutCubic}}
                            anchors.centerIn: parent
                            source: "image://icon/" + windowclass
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: index == 3
                            text: "..."
                            font.family: Fonts.system
                            font.pointSize: 8
                            font.weight: 1000
                            color: wb.selected ? Color.accentSoft : Color.accentStrong
                        }
                    }
                }
            }

        }
    }


}
