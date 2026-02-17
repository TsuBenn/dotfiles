pragma ComponentBehavior: Bound

import qs.services
import qs.assets
import qs.modules.homepanel
import qs.modules.common

import Quickshell.Widgets
import QtQuick.Layouts
import QtQuick
import Qt5Compat.GraphicalEffects


List {

    id: root

    property var new_items_data: AudioInfo.streams

    property bool changing: false

    onNew_items_dataChanged: {
        if (changing) return
        items_data = new_items_data
    }

    items_data: new_items_data

    bg_color: "transparent"
    container_color: "transparent"

    spacing: padding
    padding: 10

    layer.enabled: false
    layer.effect: DropShadow {
        radius: 10
        samples: 10
        color: Qt.rgba(0.0,0.0,0.0,0.3)
    }

    items: Loader {
        id: stream

        active: root.visible

        required property int id
        required property int volume
        required property string app
        required property string name

        sourceComponent: Rectangle {

            id: stream_container

            implicitWidth: root.container_implicitWidth
            implicitHeight: 48 + icon.height

            radius: Config.radius - root.padding

            color: Qt.lighter(Color.bgMuted,1)

            Rectangle {

                anchors.top: parent.top
                anchors.right: parent.right
                anchors.left: parent.left

                radius: parent.radius

                implicitHeight: icon.height + 16

                color: Qt.lighter(Color.bgMuted,1.3)

            }

            ColumnLayout {

                anchors.fill: parent

                anchors.margins: 8

                spacing: 12

                RowLayout {

                    spacing: 11

                    ClippingRectangle {

                        implicitHeight: 30
                        implicitWidth: implicitHeight

                        radius: Config.radius - 10

                        color: "transparent"

                        Image {

                            id: icon

                            anchors.fill: parent

                            visible: source != "image://icon/exception"

                            source: "image://icon/" + HyprInfo.iconFetch(stream.app,stream.app)

                            mipmap: true
                            smooth: true

                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !icon.visible
                            text: "\udb82\udcc6"
                            font.family: Fonts.zalandosans_font
                            font.pointSize: 24
                            font.weight: 1000
                            color: Color.textPrimary
                        }

                        layer.enabled: true
                        layer.effect: DropShadow {
                            radius: 5
                            samples: 10
                            color: Qt.rgba(0.0,0.0,0.0,0.3)
                            transparentBorder: true
                        }

                    }

                    Item {

                        implicitWidth: stream_container.implicitWidth - 66
                        implicitHeight: icon.height
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: 1
                            id: stream_name
                            text: stream.name
                            width: stream_container.implicitWidth - 76
                            elide: Text.ElideRight
                            font.family: Fonts.system
                            font.pointSize: 11
                            color: Color.textPrimary
                            font.weight: 700
                        }

                    }
                }

                RowLayout {

                    spacing: 10

                    Layout.alignment: Qt.AlignHCenter

                    PillButton {
                        text: {
                            if (bar.percentage > 200/3) {
                                return "\udb81\udd7e"
                            }
                            else if (bar.percentage > 100/3) {
                                return "\udb81\udd80"
                            }
                            else if (bar.percentage > 0) {
                                return "\udb81\udd7f"
                            }
                            else {
                                return "\udb81\udf5f"
                            }
                        }

                        font_family: Fonts.system
                        font_size: 15
                        box_width: 24
                        box_height: 24
                        bg_color: ["transparent","transparent","transparent"]
                        fg_color: [Color.textPrimary,Color.textPrimary,Color.textPrimary]
                        border_width: [0,0,0]
                    }

                    HorizontalProgressBar {

                        id: bar

                        box_width: root.container_implicitWidth - 95
                        box_height: 12
                        preferedPercentage: stream.volume

                        bg_color: Color.bgSurface
                        bg_hover: bg_color

                        fg_color: Color.accentStrong
                        fg_hover: fg_color

                        interactive: true

                        onReleased: {
                            stream.volume = percentage
                            AudioInfo.setVolume(stream.id, percentage)
                            syncBar()
                            root.changing = false
                        }

                        onPressed: {
                            root.changing = true
                        }

                    }

                    PillButton {

                        text: Math.round(bar.percentage)

                        font_family: Fonts.system
                        font_size: 10
                        font_weight: 700
                        box_width: 30
                        box_height: 24
                        bg_color: ["transparent","transparent","transparent"]
                        fg_color: [Color.textPrimary,Color.textPrimary,Color.textPrimary]
                        border_width: [0,0,0]

                    }
                }

            }


        }
    }

}

