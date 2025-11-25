pragma ComponentBehavior:Bound

import qs.assets
import qs.modules.common
import qs.services

import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import QtQuick.Layouts
import QtQuick.Controls
import QtQml.Models
import QtQuick

PillButton {

    id: button

    text                                         : "Output \udb80\udf60"
    font_family                                  : Fonts.system
    font_weight                                  : 700
    box_width                                    : 122
    box_height                                   : 36
    bg_color                                     : ["light gray", "light gray", "black"]

    property int    list_spacing                 : 5
    property int    maxWidth                     : 400
    property int    maxHeight                    : 146

    property string selected_text                : AudioInfo.getName(AudioInfo.sinkDefault)
    property int    selected_font_size           : 11
    property int    selected_font_weight         : 700
    property bool   selected_list                : true
    property var    selected_color               : ["light gray", "light gray", "black"]
    property var    selected_font_color          : ["black", "black", "white"]
    property int    selected_padding             : 25
    property bool   selected_marquee             : false
    property bool   selected_centered            : false

    property real   list_container_implicitWidth : list.container_implicitWidth
    property string list_container_color         : "#aaaaaa"
    property string list_bg_color                : "#aaaaaa"

    property string scroller_bg_color            : "#555555"
    property string scroller_fg_color            : "gray"
    property bool   show_scroller                : true
    property bool   scroller_needed              : list.scroller_needed
    property bool   dropdown                     : false

    property int    animation_speed              : 5
    property int    animation_duration           : 1000/animation_speed

    property var items: AudioInfo.sinks

    property Component list_items

    signal itemPressed(item: QtObject)

    function closeList() {
        closeList.start()
    }

    Layout.alignment: Qt.AlignCenter

    onReleased: {
        if (!closeList.running) popup.open()
    }

    Popup {
        id: popup

        y: {
            if (!button.dropdown) {
                return parent.y - implicitHeight + button.implicitHeight
            } else {
                return parent.y
            }
        }

        x: parent.x - implicitWidth/2 + button.implicitWidth/2

        focus: true

        onOpened: {
            openList.start() 
            list.scroll_progress = 0
        }

        closePolicy: Popup.NoAutoClose

        ParallelAnimation{
            id: openList
            NumberAnimation {
                target: temp
                property: "opacity"
                duration: button.animation_duration*(2/3)
                from: 1
                to: 0
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: selected
                property: "box_width"
                duration: button.animation_duration*button.maxWidth*0.0035
                from: button.box_width
                to: button.maxWidth
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: selected
                property: "x"
                duration: button.animation_duration*button.maxWidth*0.0035
                from: button.maxWidth/2 - button.box_width/2
                to: 0
                easing.type: Easing.OutCubic
            }
            SequentialAnimation {
                NumberAnimation {
                    target: selected
                    property: "text_opacity"
                    duration: 0
                    to: 0
                }
                PauseAnimation {duration: button.animation_duration*(2/3)}
                NumberAnimation {
                    target: selected
                    property: "text_opacity"
                    duration: button.animation_duration
                    from: 0
                    to: 1
                    easing.type: Easing.OutCubic
                }
            }
            NumberAnimation {
                target: list
                property: "implicitHeight"
                duration: 0
                from: 0
                to: 0
            }
            NumberAnimation {
                target: list
                property: "implicitWidth"
                duration: button.animation_duration*button.maxWidth*0.0035
                from: button.box_width
                to: button.maxWidth
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: list
                property: "x"
                duration: button.animation_duration*button.maxWidth*0.0035
                from: button.maxWidth/2 - button.box_width/2
                to: 0
                easing.type: Easing.OutCubic
            }
            SequentialAnimation {
                ScriptAction {
                    script: list.show_scroller = false;
                }
                PauseAnimation {duration: button.animation_duration*button.maxWidth*0.0035*(4/5)}
                NumberAnimation {
                    target: list
                    property: "implicitHeight"
                    duration: button.animation_duration*button.maxHeight*0.007
                    from: 0
                    to: button.maxHeight
                    easing.type: Easing.OutCubic
                }
                ScriptAction {
                    script: list.show_scroller = button.show_scroller;
                }
            }
        }

        ParallelAnimation {
            id: closeList
            NumberAnimation {
                target: list
                property: "implicitHeight"
                duration: button.animation_duration*button.maxHeight*0.007
                to: 0
                easing.type: Easing.InOutCubic
            }
            SequentialAnimation {
                ScriptAction {script: {list.show_scroller = button.scroller_needed;}}
                PauseAnimation {duration: button.animation_duration*button.maxHeight*0.007*(3/4)}
                ParallelAnimation {
                    NumberAnimation {
                        target: list
                        property: "x"
                        duration: button.animation_duration*button.maxWidth*0.0035
                        to: button.maxWidth/2 - button.box_width/2
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: list
                        property: "implicitWidth"
                        duration: button.animation_duration*button.maxWidth*0.0035
                        to: button.box_width
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: selected
                        property: "text_opacity"
                        duration: button.animation_duration*(2/5)
                        to: 0
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: selected
                        property: "box_width"
                        duration: button.animation_duration*button.maxWidth*0.0035
                        to: button.box_width
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: selected
                        property: "x"
                        duration: button.animation_duration*button.maxWidth*0.0035
                        to: button.maxWidth/2 - button.box_width/2
                        easing.type: Easing.OutCubic
                    }
                    SequentialAnimation {
                        PauseAnimation {duration: button.animation_duration*(4/5)}
                        NumberAnimation {
                            target: temp
                            property: "opacity"
                            duration: button.animation_duration*(2/3)
                            from: 0
                            to: 1
                            easing.type: Easing.OutCubic
                        }
                    }
                }
                ScriptAction {script: {popup.close();}}
            }
        }

        background: Rectangle {
            color: "transparent"
        }

        padding: 0

        contentItem: Rectangle {

            implicitWidth: button.maxWidth
            implicitHeight: button.maxHeight

            color: "transparent"


            List {

                id: list

                padding: button.list_spacing
                spacing: button.list_spacing

                max_height: button.maxHeight ?? button.box_height

                anchors.top: button.dropdown ? selected.top : undefined
                anchors.topMargin: button.dropdown ? selected.implicitHeight/2 : undefined
                anchors.bottom: !button.dropdown ? selected.bottom : undefined
                anchors.bottomMargin: !button.dropdown ? selected.implicitHeight/2 : undefined

                container_color: button.list_container_color
                bg_color: button.list_bg_color
                scroller_bg_color: button.scroller_bg_color
                scroller_fg_color: button.scroller_fg_color

                bottomRightRadius: button.dropdown ? button.radius : 0
                bottomLeftRadius: button.dropdown ? button.radius : 0
                topRightRadius: !button.dropdown ? button.radius : 0
                topLeftRadius: !button.dropdown ? button.radius : 0

                implicitWidth: parent.implicitWidth
                implicitHeight: button.maxHeight

                container_radius: button.radius

                container_top_margin: button.dropdown ? selected.implicitHeight/2 : 0
                container_bottom_margin: !button.dropdown ? selected.implicitHeight/2 : 0

                items_data: button.items

                items: button.list_items

            }

            PillButton {
                id: selected

                visible: button.selected_list

                anchors.bottom: !button.dropdown ? parent.bottom : undefined
                anchors.top: button.dropdown ? parent.top : undefined

                radius: button.radius

                text: button.selected_text

                box_width: parent.implicitWidth
                box_height: button.box_height
                font_size: button.selected_font_size
                font_weight: button.selected_font_weight

                preferedWidth: button.maxWidth

                centered: button.selected_centered
                text_padding: button.selected_padding
                marquee: button.selected_marquee

                bg_color: button.selected_color
                fg_color: button.selected_font_color

                onReleased: {
                    if (!openList.running) closeList.start()
                }

            }

            PillButton {

                visible: !button.selected_list

                anchors.bottom: !button.dropdown ? parent.bottom : undefined
                anchors.top: button.dropdown ? parent.top : undefined

                radius: button.radius

                text: button.selected_text

                box_width: parent.implicitWidth
                box_height: button.box_height
                font_size: button.selected_font_size
                font_weight: button.selected_font_weight

                preferedWidth: button.maxWidth

                centered: button.selected_centered
                text_padding: button.selected_padding
                marquee: button.selected_marquee

                bg_color: button.selected_color
                fg_color: button.selected_font_color

                onReleased: {
                    if (!openList.running) closeList.start()
                }

            }

            PillButton {

                id: temp

                clickable: false

                anchors.bottom: !button.dropdown ? parent.bottom : undefined
                anchors.top: button.dropdown ? parent.top : undefined

                x: selected.x + selected.implicitWidth/2 - implicitWidth/2

                text        : button.text
                font_family : button.font_family
                font_weight : button.font_weight
                font_size   : button.font_size
                box_width   : button.box_width
                box_height  : button.box_height
                bg_color    : button.bg_color
                spacing     : button.spacing
            }

            MouseControl {

                width: SystemInfo.monitorwidth*1.5
                height: SystemInfo.monitorheight*1.5

                x:-SystemInfo.monitorwidth
                y:-SystemInfo.monitorheight

                z:-1

                onReleased: {
                    if (openList.running) return
                    closeList.start()
                }
            }

        }

    }

}
