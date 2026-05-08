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
        list.expanded = []
    }

    Timer {

        id: debounce

        property var raw_data: NotificationsInfo.flat
        property var data: [...raw_data]

        onRaw_dataChanged: {
            restart()
        }

        interval: 100
        onTriggered: {
            data = raw_data
        }

    }

    CellScrollView {

        id: list

        w: root.box.contentW
        h: 25

        property var expanded: []

        property var expanded_notif: []

        signal collapse_all()
        signal expand_all()

        onExpand_all: {
            for (const app of debounce.data) {
                expanded = [...expanded,app.app]
                for (const group of app.notifications) {
                    expanded_notif = [...expanded_notif,group.object]
                }
            }
        }

        onCollapse_all: {
            expanded = []
            expanded_notif = []
        }

        ColumnLayout {

            spacing: 0

            CellText {
                visible: NotificationsInfo.flat.length == 0
                text: ""
            }

            CellText {
                visible: NotificationsInfo.flat.length == 0
                Layout.leftMargin: Cell.centerWCell(implicitWidth, list.implicitWidth)
                text: "No notifications"
                color: Colors.fgSubtle
            }


            Repeater {

                model: debounce.data

                delegate: Component {

                    Loader {

                        id: apps

                        required property var modelData

                        property string  a_app        : modelData?.app ?? ""
                        property string  a_icon       : modelData?.icon ?? ""
                        property int     a_urgency    : modelData?.urgency ?? 0
                        property bool    a_expandable : modelData?.expandable ?? false
                        property string  a_summary    : modelData?.summary ?? ""
                        property string  a_body       : modelData?.body ?? ""
                        property int     a_time       : modelData?.time ?? 0
                        property string  a_image      : modelData?.image ?? ""

                        property bool    a_expanded   : list.expandeds.includes(a_app)

                        active: modelData.type == "app"

                        sourceComponent: Cells {

                            w: list.contentW
                            h: 2
                            color: "transparent"

                            MouseControl {

                                anchors.fill: parent


                            }

                            RowLayout {

                                spacing: 0

                                CellText {
                                    text: " "
                                }

                                CellIcon {

                                    id: app_icon

                                    image: a_expandable ? "" : a_image
                                    icon: [a_icon, a_app]

                                    w: 6
                                    h: 2

                                }

                                ColumnLayout {

                                    spacing: 0

                                    CellText {
                                        text: a_expandable ? a_app : a_summary
                                        font: Cell.fontB
                                        preferedW: list.contentW - 1 - app_icon.getW() - app_time.text.length
                                    }

                                    CellText {
                                        text: a_expandable ? a_summary : a_body
                                        color: Colors.fgSubtle
                                        preferedW: list.contentW - 1 - app_icon.getW() - app_time.text.length
                                    }

                                }

                                CellText {

                                    Layout.alignment: Qt.AlignTop

                                    id: app_time

                                    text: a_expanded ? "" : " " + NotificationsInfo.formatTime(a_time).toString().padStart(3, " ") + " "

                                }

                            }

                        }
                    }
                }

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

            text: list.expanded.length > 0 ? "Collapse All" : "Expand all"

            clickable: NotificationsInfo.notifications_groups.length > 0

            color: [Colors.bgOverlay, Colors.fgBase]
            fg: clickable ? [Colors.fgBase, Colors.bgSurface] : Colors.fgSubtle

            font: buttonDown ? Cell.fontB : Cell.font

            onReleased: (button) => {
                if (button == "L") {
                    if (list.expanded.length > 0) list.collapse_all()
                    else if (list.expanded.length == 0) list.expand_all()
                }
            }

        }
    }

}

