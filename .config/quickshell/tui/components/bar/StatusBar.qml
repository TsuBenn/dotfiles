import qs.components.bar
import qs.config
import qs.services
import qs.modules

import QtQuick.Layouts
import QtQuick

Rectangle {
    id: root

    required property bool hideBar
    required property bool forceBar
    property bool peekBar: false

    property real unfocus: (!root.hideBar || root.forceBar || root.peekBar)

    Behavior on unfocus {
        NumberAnimation {
            duration: 200
        }
    }

    color: Colors.bgSurface

    opacity: unfocus > 0

    anchors.fill: parent
    anchors.bottomMargin: 1
    //anchors.leftMargin: Cell.w(1)
    //anchors.rightMargin: Cell.w(1)

    MouseArea {

        visible: PopupManager.active_popups.length > 0

        anchors.fill: parent

        onPressed: {
            PopupManager.close();
        }
    }

    RowLayout {

        spacing: 0

        Workspaces {
            id: workspaces
        }

        CellText {
            visible: window_title.text
            text: "│ "
            color: Colors.fgSubtle
        }

        MarqueeCellText {
            id: window_title

            property string wTitle: HyprInfo.focusedClient?.title ?? ""
            property string wClass: HyprInfo.objClient(HyprInfo.focusedClient)?.class ?? ""

            cellw: Cell.wCount(root.width / 2 - clock.implicitWidth / 2 - system.implicitWidth - workspaces.implicitWidth) - 7

            text: `<b>${wTitle}</b> - <i>${wClass}</i>`
            font: Cell.font
            color: Colors.fgBase
        }
    }

    System {
        id: system
        anchors.right: clock.left
        anchors.rightMargin: Cell.w(2)
    }

    Clock {
        id: clock
        x: Cell.centerWCell(implicitWidth, root.width)
    }

    BarMediaPlayer {
        id: media_player
        anchors.left: clock.right
        anchors.leftMargin: Cell.w(2)
    }

    RowLayout {

        x: Cell.alignRightWCell(implicitWidth, root.width)

        spacing: Cell.w(0)

        OBS {}

        CellText {
            text: " "
        }

        Volume {}

        CellText {
            text: " "
        }

        CellText {
            text: "*" + NotificationsInfo.totalMessagesCount()
            color: Colors.danger
        }

        CellText {
            text: " "
        }

        ControlPanel {}

        CellText {
            text: " "
        }

        Search {
            id: search
        }
    }

    MouseArea {

        visible: ContextMenuManager.visible || ContextMenuManager.visible

        anchors.fill: parent

        onPressed: {
            ContextMenuManager.hide();
            DropdownManager.hide();
        }
    }

    MouseArea {

        visible: root.hideBar

        anchors.fill: parent

        hoverEnabled: true
        acceptedButtons: Qt.NoButton

        onEntered: {
            root.peekBar = true;
            unpeek_timer.stop();
        }

        onExited: {
            unpeek_timer.restart();
        }
    }

    Timer {
        id: unpeek_timer
        interval: 500
        onTriggered: {
            root.peekBar = false;
        }
    }
}
