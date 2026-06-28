pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

ColumnLayout {

    id: root

    property bool optimizeMemory: SettingsInfo.optimizeMemory

    property bool minimal: SettingsInfo.minimal

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
        h: 26

        property var expanded_app: []

        property var expanded_notif: []

        signal collapse_all()
        signal expand_all()

        onExpand_all: {
            for (const object of NotificationsInfo.flat) {
                if (object.app) {
                    expand_app(object.app)
                }
                if (object.id) {
                    expand_group(object.id)
                }
            }
        }

        function expand_group(object: int) {
            if (!expanded_notif.includes(object)) {
                expanded_notif = [...expanded_notif, object]
            }
        }

        function collapse_group(object: int) {
            expanded_notif = expanded_notif.filter(item => item != object)
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

        Component.onCompleted: {
            NotificationsInfo.flatUpdated.connect(() => {
                for (const app of expanded_app) {
                    if (!NotificationsInfo.flat.some(item => item.app == app)) {
                        list.collapse_app(app)
                    }
                }
                for (const id of expanded_notif) {
                    if (!NotificationsInfo.flat.some(item => item.id == id)) {
                        list.collapse_group(id)
                    }
                }
            })
        }

        source: ColumnLayout {

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

                        active: root.visible || !root.optimizeMemory

                        required property var modelData

                        property Component appRow: Component {

                            Cells {

                                id: a

                                w: list.contentW
                                h: 2
                                color: "transparent"

                                property string  app        : modelData?.app ?? ""
                                property string  icon       : modelData?.icon ?? ""
                                property int     urgency    : modelData?.urgency ?? 0
                                property bool    expandable : modelData?.expandable ?? false
                                property int     object     : modelData?.object ?? 0
                                property string  summary    : modelData?.summary ?? ""
                                property string  body       : modelData?.body ?? ""
                                property int     time       : modelData?.time ?? 0
                                property string  image      : modelData?.image ?? ""

                                property bool    expanded   : list.expanded_app.includes(a.app) && expandable

                                Component.onCompleted: {
                                    if (!expandable) {
                                        list.collapse_app(a.app)
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

                                        w: 5
                                        h: 2

                                    }

                                    CellText {
                                        text: " "
                                    }

                                    ColumnLayout {

                                        Layout.alignment: Qt.AlignTop

                                        spacing: 0

                                        RowLayout {

                                            spacing: 0

                                            CellText {
                                                text: a.expandable ? a.app : a.summary
                                                font: Cell.fontB
                                                preferedW: list.contentW - 5 - app_icon.getW() - app_time.text.length
                                                color: {
                                                    if (!a.expandable) {
                                                        switch (a.urgency) {
                                                            case 0: return Colors.fgBase
                                                            case 1: return Colors.warning
                                                            case 2: return Colors.danger
                                                        }
                                                    }
                                                    return Colors.fgBase
                                                }
                                            }

                                            CellText {

                                                Layout.alignment: Qt.AlignTop

                                                id: app_time

                                                text: a.expanded ? "     " : " " + NotificationsInfo.formatTime(a.time).toString().padStart(3, " ") + " "

                                                color: Colors.fgSubtle

                                            }

                                        }

                                        CellText {

                                            visible: !a.expanded

                                            text: a.expandable ? a.summary : a.body
                                            color: Colors.fgDim
                                            preferedW: list.contentW - 5 - app_icon.getW() - app_time.text.length
                                        }

                                        CellSeparator {

                                            visible: a.expanded

                                            w: list.contentW - 5 - app_icon.getW() - 1

                                            type: 1
                                            color: Qt.darker(Colors.fgSubtle,2)
                                        }

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
                                            text: a.expanded ? " - " : " + "
                                            color: a.expandable ? Colors.fgBase : Colors.bgOverlay
                                            font: Cell.fontB
                                        }

                                    }


                                }

                                MouseControl {

                                    anchors.fill: parent

                                    acceptedButtons: mouseX > Cell.w(list.contentW-3) && mouseY <= Cell.h(1) ? Qt.NoButton : Qt.AllButtons

                                    onReleased: (button) => {
                                        if (button == "L") {
                                            if (a.expandable) {
                                                a.expanded ? list.collapse_app(a.app) : list.expand_app(a.app) 
                                            } else {
                                                NotificationsInfo.action(a.object)
                                            }
                                        }
                                    }

                                }

                            }

                        }

                        property Component groupRow: Component {

                            Cells {

                                id: g

                                w: list.contentW
                                h: list.expanded_app.includes(g.app) ? Cell.hCount(group_layout.implicitHeight) : 0

                                color: "transparent"

                                clip: true

                                property string  app        : modelData?.app ?? ""
                                property int     id         : modelData?.id ?? ""
                                property int     object     : modelData?.object ?? ""
                                property int     urgency    : modelData?.urgency ?? 0
                                property bool    expandable : modelData?.expandable ?? false
                                property string  summary    : modelData?.summary ?? ""
                                property string  body       : modelData?.body ?? ""
                                property int     time       : modelData?.time ?? 0

                                property bool    expanded   : list.expanded_notif.includes(id) && expandable


                                RowLayout {

                                    id: group_layout

                                    spacing: 0

                                    CellText {
                                        text: "       "
                                    }

                                    ColumnLayout {

                                        Layout.alignment: Qt.AlignTop

                                        spacing: 0

                                        RowLayout {

                                            spacing: 0

                                            CellText {
                                                text: g.summary
                                                font: Cell.fontB
                                                preferedW: list.contentW - 10 - group_time.text.length
                                                wrap: !root.minimal
                                                color : {
                                                    switch (g.urgency) {
                                                        case 0: return Colors.fgBase
                                                        case 1: return Colors.warning
                                                        case 2: return Colors.danger
                                                    }
                                                    return Colors.fgBase
                                                }
                                            }

                                            CellText {

                                                Layout.alignment: Qt.AlignTop

                                                id: group_time

                                                text: " " + NotificationsInfo.formatTime(g.time).toString().padStart(3, " ") + " "

                                                color: Colors.fgSubtle

                                            }

                                        }

                                        CellText {

                                            text: g.body
                                            color: Colors.fgDim
                                            preferedW: list.contentW - 10 - group_time.text.length
                                            wrap: true

                                        }

                                    }


                                    ColumnLayout {

                                        Layout.alignment: Qt.AlignTop

                                        spacing: 0

                                        CellButton {

                                            padding: 1
                                            text: "\uea76"
                                            color: ["transparent", Colors.bgOverlay]
                                            fg: Colors.fgBase

                                            onReleased: (button) => {
                                                if (button == "L") {
                                                    NotificationsInfo.dismiss(g.object)
                                                }
                                            }
                                        }

                                    }


                                }

                                MouseControl {

                                    anchors.fill: parent

                                    acceptedButtons: mouseX > Cell.w(list.contentW-3) && mouseY <= Cell.h(1) ? Qt.NoButton : Qt.AllButtons

                                    onReleased: (button) => {
                                        if (button == "L") {
                                            if (mouseX <= Cell.h(7)) {
                                                if (g.expandable) {
                                                    g.expanded ? list.collapse_group(g.id) : list.expand_group(g.id)
                                                } else {
                                                    list.collapse_app(g.app)
                                                }
                                                return
                                            } else if (mouseX > Cell.w(list.contentW) - Cell.h(9)){
                                                list.collapse_app(g.app)
                                                return
                                            }
                                            NotificationsInfo.action(g.object)
                                        }
                                    }

                                }

                            }

                        }

                        property Component subgroupRow: Component {

                            Cells {

                                id: sg

                                w: list.contentW
                                h: list.expanded_notif.includes(id) && list.expanded_app.includes(app) ? Cell.hCount(subgroup_layout.implicitHeight) + 1*!root.minimal : 0

                                color: "transparent"

                                clip: true

                                property string  app        : modelData?.app ?? ""
                                property int     id         : modelData?.id ?? ""
                                property int     object     : modelData?.object ?? ""
                                property int     urgency    : modelData?.urgency ?? 0
                                property int     time       : modelData?.time ?? 0
                                property string  summary    : modelData?.summary ?? ""
                                property string  body       : modelData?.body ?? ""


                                RowLayout {

                                    y: Cell.h(1)*!root.minimal

                                    id: subgroup_layout

                                    spacing: 0

                                    CellText {
                                        text: "       "
                                    }

                                    ColumnLayout {

                                        Layout.alignment: Qt.AlignTop

                                        spacing: 0

                                        RowLayout {

                                            spacing: 0

                                            CellText {
                                                text: sg.summary
                                                font: Cell.fontB
                                                preferedW: list.contentW - 10 - subgroup_time.text.length
                                                wrap: !root.minimal
                                                color : {
                                                    switch (sg.urgency) {
                                                        case 0: return Colors.fgBase
                                                        case 1: return Colors.warning
                                                        case 2: return Colors.danger
                                                    }
                                                    return Colors.fgBase
                                                }
                                            }

                                            CellText {

                                                Layout.alignment: Qt.AlignTop

                                                id: subgroup_time

                                                text: " " + NotificationsInfo.formatTime(sg.time).toString().padStart(3, " ") + " "

                                                color: Colors.fgSubtle

                                            }

                                        }

                                        CellText {

                                            text: sg.body
                                            color: Colors.fgDim
                                            preferedW: list.contentW - 10 - subgroup_time.text.length
                                            wrap: true

                                        }

                                    }

                                }

                                MouseControl {

                                    anchors.fill: parent

                                    onReleased: (button) => {
                                        if (button == "L") {
                                            if (mouseX <= Cell.h(7)) {
                                                list.collapse_group(sg.id)
                                                return
                                            } else if (mouseX > Cell.w(list.contentW) - Cell.h(9)){
                                                list.collapse_app(sg.app)
                                                return
                                            }
                                            NotificationsInfo.action(sg.object)
                                        }
                                    }

                                }

                            }
                        }

                        property Component expander: Component {

                            Cells {

                                id: ex

                                w: list.contentW
                                h: list.expanded_app.includes(ex.app) ? 2 : 0

                                clip: true

                                color: "transparent"

                                property string  app        : modelData?.app ?? ""
                                property int     id         : modelData?.id ?? ""

                                property bool    expanded   : list.expanded_notif.includes(id)


                                RowLayout {

                                    y: Cell.h(1)

                                    spacing: 0

                                    CellText {
                                        text: "       "
                                    }

                                    CellText {
                                        text: ex.expanded ? "[Less]" : "[More]"
                                        color: Colors.fgSubtle
                                    }

                                }

                                MouseControl {

                                    anchors.fill: parent

                                    onReleased: (button) => {
                                        if (button == "L") {
                                            ex.expanded ? list.collapse_group(id) : list.expand_group(id)
                                        }
                                    }

                                }

                            }
                        }

                        property Component groupSep: Component {

                            Cells {

                                id: g_sep

                                property string app      : modelData?.app ?? ""
                                property int    id       : modelData?.id ?? ""

                                property bool   expanded : list.expanded_notif.includes(id)

                                w: list.contentW
                                h: list.expanded_app.includes(g_sep.app) ? 1 : 0

                                color: "transparent"

                                clip: true

                                CellSeparator {

                                    x: Cell.w(7)

                                    w: parent.w - 8
                                    type: 0
                                    color: Colors.bgOverlay

                                }

                                MouseControl {

                                    anchors.fill: parent

                                    onReleased: (button) => {
                                        if (button == "L") {
                                            g_sep.expanded ? list.collapse_group(g_sep.id) : list.expand_group(g_sep.id)
                                        }
                                    }

                                }

                            }


                        }

                        property Component appSep: Component {

                            CellSeparator {
                                x: Cell.w(1)
                                padding: 0
                                type: 2
                                w: list.contentW - 1
                                color: Qt.darker(Colors.fgSubtle,2)
                            }

                        }

                        sourceComponent: {
                            switch (modelData.type) {
                                case "app": return appRow
                                case "group": return groupRow
                                case "subgroup": return subgroupRow
                                case "expander": return expander
                                case "group_sep": return groupSep
                                case "app_sep": return appSep
                            }
                            return null
                        }
                    }

                }

            }

        }

    }

    CellSeparator {
        w: root.box.contentW
        padding: 0
        color: Colors.accentDim
        type: 0
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

