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
        list.expanded_app = []
        list.expanded_notif = []
    }

    CellScrollView {

        id: list

        w: root.box.contentW
        h: 25

        property var expanded_app: []

        property var expanded_notif: []

        signal collapse_all()
        signal expand_all()

        onExpand_all: {
            for (const app of NotificationsInfo.flat) {
                expanded_app = [...expanded_app ,app.app]
                for (const group of app.notifications) {
                    expanded_notif = [...expanded_notif,group.object]
                }
            }
        }

        function expand_app(app: string) {
            if (!expanded_app.includes(app)) {
                expanded_app = [...expanded_app, app]
            }
        }

        function collapse_app(app: string) {
            expanded_app = expanded_app.filter(item => item != app)
        }

        onCollapse_all: {
            expanded_app = []
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

                model: NotificationsInfo.flat

                delegate: Component {

                    Loader {

                        id: apps

                        required property var modelData

                        active: modelData.type == "app"

                        sourceComponent: Cells {

                            id: a

                            w: list.contentW
                            h: 2
                            color: "transparent"

                            property string  app        : apps.modelData?.app ?? ""
                            property string  icon       : apps.modelData?.icon ?? ""
                            property int     urgency    : apps.modelData?.urgency ?? 0
                            property bool    expandable : apps.modelData?.expandable ?? false
                            property string  summary    : apps.modelData?.summary ?? ""
                            property string  body       : apps.modelData?.body ?? ""
                            property int     time       : apps.modelData?.time ?? 0
                            property string  image      : apps.modelData?.image ?? ""

                            property bool    expanded   : list.expanded_app.includes(a.app)

                            MouseControl {

                                anchors.fill: parent

                                onReleased: (button) => {
                                    if (button == "L" && a.expandable) {
                                        a.expanded ? list.collapse_app(a.app) : list.expand_app(a.app) 
                                    }
                                }

                            }

                            RowLayout {

                                spacing: 0

                                CellText {
                                    text: " "
                                }

                                CellIcon {

                                    Layout.alignment: Qt.AlignTop

                                    id: app_icon

                                    image: a.expandable ? "" : a.image
                                    icon: [a.icon, a.app]

                                    w: 6
                                    h: 2

                                }

                                ColumnLayout {

                                    Layout.alignment: Qt.AlignTop

                                    spacing: 0

                                    CellText {
                                        text: a.expandable ? a.app : a.summary
                                        font: Cell.fontB
                                        preferedW: list.contentW - 4 - app_icon.getW() - app_time.text.length
                                    }

                                    CellText {

                                        visible: !a.expanded

                                        text: a.expandable ? a.summary : a.body
                                        color: Colors.fgSubtle
                                        preferedW: list.contentW - 4 - app_icon.getW() - app_time.text.length
                                    }

                                    CellSeparator {

                                        visible: a.expanded

                                        w: list.contentW - 4 - app_icon.getW() - app_time.text.length

                                        type: 1
                                        color: Colors.fgSubtle
                                    }

                                }

                                CellText {

                                    Layout.alignment: Qt.AlignTop

                                    id: app_time

                                    text: a.expanded ? "" : " " + NotificationsInfo.formatTime(a.time).toString().padStart(3, " ") + " "

                                    color: Colors.fgDim

                                }

                                ColumnLayout {

                                    spacing: 0

                                    CellButton {

                                        padding: 1
                                        text: "\uea76"
                                        color: [Colors.bgOverlay, Colors.fgBase]
                                        fg: [Colors.fgBase, Colors.bgSurface]

                                        onReleased: (button) => {
                                            if (button == "L") {
                                                NotificationsInfo.dismiss(a.app)
                                            }
                                        }
                                    }

                                    CellText {
                                        text: a.expanded ? " ⏶ " : " ⏷ "
                                        color: a.expandable ? Colors.fgBase : Colors.fgSubtle
                                    }

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

            text: list.expanded_app.length > 0 ? "Collapse All" : "Expand all"

            clickable: NotificationsInfo.notifications_groups.length > 0

            color: [Colors.bgOverlay, Colors.fgBase]
            fg: clickable ? [Colors.fgBase, Colors.bgSurface] : Colors.fgSubtle

            font: buttonDown ? Cell.fontB : Cell.font

            onReleased: (button) => {
                if (button == "L") {
                    if (list.expanded_app.length > 0) list.collapse_all()
                    else if (list.expanded_app.length == 0) list.expand_all()
                }
            }

        }
    }

}

