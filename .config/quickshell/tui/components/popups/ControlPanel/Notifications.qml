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

    onVisibleChanged: {
        NotificationsInfo.refresh()
        list.expanded = 0
    }

    CellScrollView {

        id: list

        w: root.box.contentW
        h: 25

        property int expanded: 0

        signal collapse()

        onCollapse: {
            expanded = 0
        }

        ColumnLayout {

            spacing: 0

            Repeater {

                model: NotificationsInfo.notifications_groups

                delegate: Cells {

                    id: notif

                    required property var modelData

                    property var notif_group: modelData.notifications

                    property bool group: modelData.notifications.length > 1 || modelData.notifications[0].body.length > 1
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

                            anchors.fill: parent

                            onEntered: {
                                arrow.bg = Colors.bgOverlay
                            }
                            onExited: {
                                arrow.bg = "transparent"
                            }

                            onReleased: (button) => {
                                if (button == "L") {
                                    if (notif.group) {
                                        notif.expanded = !notif.expanded
                                        if (notif.expanded) {
                                            list.expanded += 1
                                        } else {
                                            list.expanded -= 1
                                        }
                                    }
                                }
                                if (button == "R") {
                                    const global = mapToGlobal(mouseX, mouseY)
                                    ContextMenuManager.show(
                                        [
                                            {label: "Dismiss", action: () => {
                                                NotificationsInfo.dismiss(notif.modelData.app, -1)
                                                NotificationsInfo.refresh()
                                            }},
                                            {label: notif.expanded ? "Collapse" : "Expand", disabled: !notif.group, action: () => {
                                                notif.expanded = !notif.expanded
                                            }}
                                        ],
                                        global.x,
                                        global.y,
                                        undefined,
                                        notif.modelData.app
                                    )
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
                                        text: notif.group ? notif.modelData.app : notif.modelData.notifications[0].summary
                                        font: Cell.fontB
                                        preferedW: list.contentW - 11
                                    }

                                    CellButton {
                                        visible: !notif.group
                                        padding: 1
                                        text: "\uea76"
                                        color: [Colors.bgOverlay, Colors.fgBase]
                                        fg: [Colors.fgBase, Colors.bgSurface]

                                        onReleased: (button) => {
                                            NotificationsInfo.dismiss(notif.modelData.app, 0)
                                            NotificationsInfo.refresh()
                                        }
                                    }

                                    CellText {

                                        id: arrow

                                        visible: notif.group

                                        Layout.alignment: Qt.AlignTop

                                        text: !notif.expanded ? " ⯆ " : " ⯅ "

                                    }
                                }

                                RowLayout {

                                    visible: !notif.expanded

                                    spacing: 0

                                    CellText {
                                        text: notif.expanded ? "" : (notif.group ? notif.modelData.notifications[0].summary : notif.modelData.notifications[0].body[0])
                                        preferedW: list.contentW - 8 - timer.text.length
                                        color: notif.group ? Colors.fgSubtle : Colors.fgBase
                                        wrap: true
                                    }

                                    CellText {
                                        id: timer
                                        text: "  " + NotificationsInfo.formatTime(notif.modelData.notifications[0].time)
                                        color: Colors.fgSubtle
                                    }

                                }

                                ColumnLayout {

                                    visible: notif.expanded
                                    spacing: 0

                                    Repeater {

                                        model: notif.notif_group

                                        delegate: ColumnLayout {

                                            id: sub_notif

                                            required property int index
                                            required property string summary
                                            required property var body

                                            spacing: 0

                                            CellSeparator {
                                                padding: 0
                                                color: Colors.bgOverlay
                                                w: list.contentW - 8
                                            }

                                            Cells {

                                                w: list.contentW - 8
                                                h: Cell.hCount(sub_notif_layout.implicitHeight)

                                                color: "transparent"

                                                MouseControl {

                                                    anchors.fill: parent

                                                    onReleased: (button) => {
                                                        if (button == "R") {
                                                            const global = mapToGlobal(mouseX, mouseY)
                                                            ContextMenuManager.show(
                                                                [
                                                                    {label: "Dismiss", action: () => {
                                                                        NotificationsInfo.dismiss(notif.modelData.app, sub_notif.index)
                                                                        if (notif.notif_group.length == 2) {
                                                                            NotificationsInfo.refresh()
                                                                        }
                                                                        notif.notif_group = notif.notif_group.filter((_, i) => i !== sub_notif.index);
                                                                    }},
                                                                ],
                                                                global.x,
                                                                global.y,
                                                                undefined,
                                                                notif.modelData.app
                                                            )
                                                        }
                                                    }

                                                }

                                                ColumnLayout {

                                                    id: sub_notif_layout

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
                                                                NotificationsInfo.dismiss(notif.modelData.app, sub_notif.index)
                                                                if (notif.notif_group.length == 2) {
                                                                    NotificationsInfo.refresh()
                                                                }
                                                                notif.notif_group = notif.notif_group.filter((_, i) => i !== sub_notif.index);
                                                            }
                                                        }

                                                    }

                                                    RowLayout {

                                                        spacing: 0

                                                        ColumnLayout {

                                                            spacing: 0

                                                            Repeater {

                                                                model: sub_notif.body

                                                                delegate: RowLayout {

                                                                    required property string modelData

                                                                    spacing: 0

                                                                    CellText {
                                                                        Layout.alignment: Qt.AlignTop

                                                                        text: "· "
                                                                        color: Colors.fgSubtle

                                                                    }

                                                                    CellText {
                                                                        Layout.alignment: Qt.AlignTop

                                                                        text: modelData
                                                                        preferedW: list.contentW - 10 - sub_timer.text.length
                                                                        color: Colors.fgDim
                                                                        wrap: true
                                                                    }

                                                                }
                                                            }


                                                        }

                                                        CellText {
                                                            id: sub_timer
                                                            Layout.alignment: Qt.AlignTop
                                                            text: "  " + NotificationsInfo.formatTime(notif.modelData.notifications[sub_notif.index].time)
                                                            color: Colors.fgSubtle
                                                        }

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
        padding: 0
        color: Colors.bgOverlay
        type: 2
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

            onReleased: (button) => {
                if (button == "L") {
                    NotificationsInfo.clear()
                }
            }

        }

        CellText {
            text: " "
        }

        CellButton {

            text: "Collapse All"

            clickable: list.expanded > 0

            color: [Colors.bgOverlay, Colors.fgBase]
            fg: clickable ? [Colors.fgBase, Colors.bgSurface] : Colors.fgSubtle

            font: buttonDown ? Cell.fontB : Cell.font

            onReleased: (button) => {
                if (button == "L") {
                    list.collapse()
                }
            }

        }
    }

}

