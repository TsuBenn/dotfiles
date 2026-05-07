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
        debounce.restart()
    }

    Timer {

        id: debounce

        property var raw_data: NotificationsInfo.notifications_groups
        property var data: []

        onRaw_dataChanged: {
            if (visible) {
                restart()
            }
        }

        interval: 200
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

            Repeater {

                model: debounce.data

                delegate: Loader {

                    id: apps

                    required property var modelData

                    active: root.visible

                    sourceComponent: Cells {

                        // Grouping Apps

                        id: app

                        w: list.contentW
                        h: Cell.hCount(layout.implicitHeight)  

                        color: "transparent"

                        property var modelData: apps.modelData

                        property string app: modelData.app ?? ""
                        property string icon: modelData.icon ?? ""

                        property bool expanded: list.expanded.includes(app.app)

                        property bool expandable: notifications.length > 1 || notifications[0].group.length > 1

                        property var notifications: modelData.notifications // App's notifications groups

                        function toggleExpand() {
                            expanded ? collapse() : expand()
                        }
                        function expand() {
                            if (!list.expanded.includes(app)) {
                                list.expanded = [...list.expanded, app.app]
                            }
                        }
                        function collapse() {
                            list.expanded = list.expanded.filter(item => item != app.app)
                        }

                        ColumnLayout {

                            id: layout

                            spacing: 0

                            Cells {

                                w: list.contentW
                                h: Cell.hCount(content_layout.implicitHeight)

                                color: "transparent"

                                MouseControl {

                                    anchors.fill: parent

                                    onReleased: (button) => {
                                        if (button == "L" && app.expandable) {
                                            app.toggleExpand()
                                        }
                                    }

                                }

                                ColumnLayout {

                                    id: content_layout

                                    spacing: 0

                                    RowLayout {

                                        // Notification Content

                                        spacing: 0

                                        CellText {

                                            Layout.alignment: Qt.AlignTop

                                            text: " "
                                        }

                                        CellIcon {

                                            id: app_icon

                                            Layout.alignment: Qt.AlignTop

                                            w: 6

                                            image: {
                                                if (app.expandable) {
                                                    return ""
                                                }
                                                return app.notifications[0].group[0]?.image ?? ""
                                            }
                                            icon: [app.icon, app.app]

                                            // Show the image of the first message if availble. If there are more than 1 message then show the app's icon instead

                                        }

                                        ColumnLayout {

                                            Layout.alignment: Qt.AlignTop

                                            spacing: 0

                                            RowLayout {

                                                spacing: 0

                                                CellText {

                                                    text: {
                                                        if (app.expandable) {
                                                            return app.app
                                                        }
                                                        return app.notifications[0].group[0]?.summary ?? ""
                                                    }

                                                    // If there's only one notification of the app, show the newest summary

                                                    font: Cell.fontB

                                                    preferedW: list.contentW - 4 - app_time.text.length - app_icon.getW()

                                                }

                                                CellText {

                                                    // Time

                                                    Layout.alignment: Qt.AlignTop

                                                    id: app_time

                                                    text: {
                                                        app.expanded ? "     " : " " + NotificationsInfo.formatTime(app.notifications[0].group[0].time).toString().padStart(3," ") + " "
                                                    }
                                                    color: Colors.fgSubtle

                                                }

                                            }

                                            CellSeparator {

                                                visible: app.expanded

                                                w: list.contentW - 5 - app_icon.getW()
                                                type: 1
                                                color: Colors.bgOverlay

                                            }

                                            CellText {

                                                visible: !app.expanded

                                                text: {
                                                    if (app.expandable) {
                                                        return app.notifications[0].group[0]?.summary ?? ""
                                                    }
                                                    return app.notifications[0].group[0]?.body ?? ""
                                                }

                                                // Show summary if collapse, show body if there's only 1 notification, show a separator if expanded

                                                color: Colors.fgDim

                                                wrap: true

                                                preferedW: list.contentW - 4 - app_time.text.length - app_icon.getW()

                                            }

                                        }


                                        ColumnLayout {

                                            Layout.alignment: Qt.AlignTop

                                            spacing: 0

                                            CellButton {

                                                // App Dismiss

                                                Layout.alignment: Qt.AlignTop

                                                padding: 1
                                                text: "\uea76"

                                                color: [Colors.bgOverlay, Colors.fgBase]
                                                fg: [Colors.fgBase, Colors.bgSurface]

                                                onReleased: (button) => {
                                                    if (button == "L") {
                                                        NotificationsInfo.dismiss(app.app)
                                                    }
                                                }

                                            }

                                            CellText {

                                                // Expander

                                                Layout.alignment: Qt.AlignTop

                                                text: app.expanded ? " ⏷ " : " ⏴ "

                                                color: app.expandable ? Colors.fgBase : Colors.bgOverlay

                                            }

                                        }



                                    }

                                    // Expanded messages
                                    ColumnLayout {

                                        visible: app.expanded

                                        spacing: 0

                                        Repeater {

                                            model: app.notifications

                                            delegate: Loader {

                                                id: notif_groups

                                                required property int index
                                                required property var modelData

                                                active: app.expanded

                                                sourceComponent: Cells {

                                                    // Notification groups

                                                    id: notif

                                                    property int index: notif_groups.index
                                                    property var modelData: notif_groups.modelData

                                                    property int object: modelData.object
                                                    property int urgency: modelData.urgency 
                                                    property var group: modelData.group

                                                    property bool expanded: list.expanded_notif.includes(app.app+notif.index)
                                                    property bool expandable: group.length > 1

                                                    w: list.contentW
                                                    h: Cell.hCount(group_layout.implicitHeight)

                                                    color: "transparent"

                                                    function toggleExpand() {
                                                        expanded ? collapse() : expand()
                                                    }

                                                    function expand() {
                                                        if (!list.expanded_notif.includes(app.app+notif.index)) {
                                                            list.expanded_notif = [...list.expanded_notif, app.app+notif.index]
                                                        }
                                                    }

                                                    function collapse() {
                                                        if (list.expanded_notif.includes(app.app+notif.index)) {
                                                            list.expanded_notif = list.expanded_notif.filter(item => item != app.app+notif.index)
                                                        }
                                                    }

                                                    MouseControl {

                                                        anchors.fill: parent

                                                        anchors.leftMargin: Cell.w(7)
                                                        anchors.rightMargin: Cell.w(4)
                                                        anchors.bottomMargin: Cell.h(2)

                                                        implicitHeight: Cell.h(2)

                                                        onReleased: (button) => {
                                                            if (button == "L") {
                                                                NotificationsInfo.action(notif.object)
                                                            }
                                                        }

                                                    }

                                                    MouseControl {

                                                        anchors.left: parent.left
                                                        anchors.right: parent.right
                                                        anchors.bottom: parent.bottom

                                                        anchors.leftMargin: Cell.w(7)
                                                        anchors.rightMargin: Cell.w(4)

                                                        implicitHeight: Cell.h(2)

                                                        onReleased: (button) => {
                                                            if (button == "L" & notif.expandable) {
                                                                notif.toggleExpand()
                                                            }
                                                        }

                                                    }

                                                    RowLayout {

                                                        id: group_layout

                                                        spacing: 0

                                                        ColumnLayout {

                                                            spacing: 0

                                                            ColumnLayout {

                                                                spacing: Cell.h(1)

                                                                Repeater {

                                                                    model: notif.expanded ? notif.group : [notif.group[0]]

                                                                    delegate: Loader {

                                                                        id: subgroups

                                                                        required property int index
                                                                        required property var modelData

                                                                        active: app.expanded

                                                                        sourceComponent: RowLayout {

                                                                            id: subgroup

                                                                            property var modelData: subgroups.modelData

                                                                            property string summary: modelData.summary ?? ""
                                                                            property string body: modelData.body ?? ""
                                                                            property string image: modelData.image ?? ""
                                                                            property int time: modelData.time ?? 0

                                                                            spacing: 0

                                                                            CellText {
                                                                                text: "       "
                                                                            }

                                                                            ColumnLayout {

                                                                                Layout.alignment: Qt.AlignTop

                                                                                spacing: 0

                                                                                RowLayout {

                                                                                    Layout.alignment: Qt.AlignTop

                                                                                    spacing: 0

                                                                                    CellText {

                                                                                        text: subgroup.summary

                                                                                        font: Cell.fontB

                                                                                        preferedW: list.contentW - 10 - noti_time.text.length
                                                                                        color: {
                                                                                            if (notif.urgency == 2) {
                                                                                                return Colors.danger
                                                                                            } else if (notif.urgency == 1) {
                                                                                                return Colors.warning
                                                                                            }
                                                                                            return Colors.fgBase
                                                                                        }

                                                                                    }

                                                                                    CellText {


                                                                                        id: noti_time

                                                                                        text: " " + NotificationsInfo.formatTime(subgroup.time).toString().padStart(3," ") + " "


                                                                                        color: Colors.fgSubtle

                                                                                    }

                                                                                }

                                                                                CellText {

                                                                                    text: subgroup.body

                                                                                    preferedW: list.contentW - 10 - noti_time.text.length
                                                                                    color: Colors.fgDim

                                                                                    wrap: notif.expanded

                                                                                }

                                                                            }

                                                                        }

                                                                    }


                                                                }

                                                            }

                                                            CellText {

                                                                visible: notif.expandable

                                                                text: " "

                                                            }

                                                            CellText {

                                                                visible: notif.expandable

                                                                text: notif.expanded ? "       [Less]" : "       [More]"

                                                                font: Cell.fontB
                                                                color: Qt.lighter(Colors.bgOverlay,2)
                                                            }

                                                            RowLayout {

                                                                spacing: 0

                                                                CellText {
                                                                    text: "       "
                                                                }

                                                                CellSeparator {
                                                                    type: 0
                                                                    padding: 0
                                                                    w: list.contentW - 11
                                                                    color: Colors.bgOverlay
                                                                }

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
                                type: 2
                                w: list.contentW
                                color: Colors.bgOverlay
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

