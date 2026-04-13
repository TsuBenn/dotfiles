pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

ColumnLayout {

    id: root

    property var box

    spacing: 0

    CellScrollView {

        id: list

        w: root.box.contentW
        h: 26

        signal collapse()

        ColumnLayout {

            spacing: 0

            Repeater {

                model: NotificationsInfo.notifications_groups

                delegate: Cells {

                    id: notif

                    required property var modelData

                    property bool group: modelData.notifications.length > 1
                    property bool expanded: false

                    w: list.contentW
                    h: Cell.hCount(notif_layout.implicitHeight)

                    color: "transparent"

                    Component.onCompleted: {
                        list.collapse.connect(()=> {
                            notif.expanded = false
                        })
                    }

                    Cells {

                        x: Cell.w(1)

                        property bool hovered: false

                        w: list.contentW - 2
                        h: 2

                        color: "transparent"

                        MouseControl {

                            id: expander

                            visible: notif.group

                            anchors.fill: parent

                            onEntered: {
                                arrow.bg = Colors.bgOverlay
                            }
                            onExited: {
                                arrow.bg = "transparent"
                            }

                            onReleased: (button) => {
                                if (button == "L") {
                                    notif.expanded = !notif.expanded
                                }
                            }

                        }

                    }

                    ColumnLayout {

                        id: notif_layout

                        spacing: 0

                        RowLayout {

                            spacing: 0

                            CellText {
                                text: " "
                            }

                            Cells {

                                Layout.alignment: Qt.AlignTop

                                w: 6
                                h: 2

                                color: "transparent"

                                Image {
                                    source: "image://icon/zen-browser"
                                    height: Cell.h(2)
                                    width: Cell.h(2)

                                    fillMode: Image.PreserveAspectCrop
                                }

                            }

                            ColumnLayout {

                                Layout.alignment: Qt.AlignTop

                                spacing: 0

                                RowLayout {
                                    spacing: 0
                                    CellText {
                                        text: notif.group ? notif.modelData.app : notif.modelData.notifications[notif.modelData.notifications.length - 1].summary
                                        font: Cell.fontB
                                        preferedW: list.contentW - 7 - 4*notif.group
                                    }

                                    CellText {

                                        id: arrow

                                        visible: notif.group

                                        Layout.alignment: Qt.AlignTop

                                        text: !notif.expanded ? " ⯆ " : " ⯅ "

                                    }
                                }

                                CellText {
                                    visible: !notif.expanded
                                    text: notif.expanded ? "" : (notif.group ? notif.modelData.notifications[notif.modelData.notifications.length - 1].summary : notif.modelData.notifications[notif.modelData.notifications.length - 1].body)
                                    preferedW: list.contentW - 7 - 4*notif.group
                                    color: notif.group ? Colors.fgSubtle : Colors.fgBase
                                }

                                ColumnLayout {

                                    visible: notif.expanded
                                    spacing: 0

                                    Repeater {

                                        model: notif.modelData.notifications

                                        delegate: ColumnLayout {

                                            id: sub_notif

                                            required property string summary
                                            required property string body
                                            required property bool tracked

                                            spacing: 0

                                            CellSeparator {
                                                padding: 0
                                                color: Colors.bgOverlay
                                                w: list.contentW - 8
                                            }

                                            Cells {

                                                w: list.contentW - 8
                                                h: 2

                                                color: "transparent"

                                                ColumnLayout {

                                                    spacing: 0

                                                    RowLayout {

                                                        spacing: 0

                                                        CellText {
                                                            text: sub_notif.summary
                                                            preferedW: list.contentW - 11
                                                        }

                                                        CellButton {
                                                            padding: 1
                                                            text: "\uea76"
                                                            color: [Colors.bgOverlay, Colors.fgBase]
                                                            fg: [Colors.fgBase, Colors.bgSurface]

                                                            onReleased: (button) => {
                                                            }
                                                        }

                                                    }

                                                    CellText {
                                                        text: sub_notif.body
                                                    }

                                                }

                                            }


                                        }

                                    }

                                    CellSeparator {
                                        padding: 0
                                        color: Colors.bgOverlay
                                        w: list.contentW - 8
                                    }
                                }

                            }

                        }

                        CellSeparator {

                            type: 2
                            padding: 1
                            color: Colors.bgOverlay
                            w: list.contentW

                        }

                    }


                }

            }

        }

        ColumnLayout {

            spacing: 0

            CellText {
                visible: NotificationsInfo.notifications_groups.length == 0
                text: " "
            }

            CellText {
                visible: NotificationsInfo.notifications_groups.length == 0
                Layout.leftMargin: Cell.centerWCell(implicitWidth, Cell.w(list.contentW))

                text: "No notifications"
                color: Colors.fgSubtle
            }

        }

    }

    CellSeparator {
        w: root.box.contentW
        padding: 1
        color: Colors.fgSubtle
    }

    RowLayout {
        spacing: 0

        CellText {
            text: " "
        }

        CellButton {

            text: "Clear"

            color: [Colors.bgOverlay, Colors.fgBase]
            fg: [Colors.fgBase, Colors.bgSurface]

            font: buttonDown ? Cell.fontB : Cell.font

        }

        CellText {
            text: " "
        }

        CellButton {

            text: "Collapse All"

            color: [Colors.bgOverlay, Colors.fgBase]
            fg: [Colors.fgBase, Colors.bgSurface]

            font: buttonDown ? Cell.fontB : Cell.font

            onReleased: (button) => {
                if (button == "L") {
                    list.collapse()
                }
            }

        }
    }

}

