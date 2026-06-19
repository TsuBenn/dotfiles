pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick
import Qt5Compat.GraphicalEffects

Item {

    id: root

    property var monitor

    visible: PopupManager.isOpen(name)

    property int w: 3
    property int h: 3

    property int cellX
    property int cellY

    property string name

    property var shortcuts: []

    property int safeMargin: 2

    signal marginsPressed()

    signal promoted()

    readonly property bool isTop: PopupManager.isTop(name)

    Connections {
        target: PopupManager
        function onSigClose(name) {
            if (root.name == name) {
                root.onSigClose()
                PopupManager.close(root.name)
            }
        }
    }

    function onSigClose() {}

    onIsTopChanged: {
        if (isTop) {
            root.promoted()
            ShortcutInfo.shortcuts = [
                {
                    binds: "Escape",
                    active: root.escapeToClose,
                    action: () => PopupManager.sigClose(root.name)
                },
                ...shortcuts
            ] 
        }
    }

    property bool escapeToClose: true

    x: {
        if (!monitor) return Cell.w(cellX)
        if (cellX <= 0) {
            return 0
        }
        if (cellX + w <= Cell.wCount(monitor.width,"floor")) {
            return Cell.w(cellX)
        }
        return Cell.w(Cell.wCount(monitor.width,"floor") - w)
    }
    y: {
        if (!monitor) return Cell.h(cellY)
        if (cellY <= -1) {
            return Cell.h(-1)
        }
        if (cellY + h <= Cell.hCount(monitor.height,"floor")) {
            return Cell.h(cellY)
        }
        return Cell.h(Cell.hCount(monitor.height,"floor") - h)
    }

    focus: true

    function close() {
        PopupManager.sigClose(root.name)
    }

    implicitWidth: Cell.w(w)
    implicitHeight: Cell.h(h)

    MouseControl {

        anchors.fill: parent

        anchors.leftMargin: -root.monitor?.width ?? 0
        anchors.rightMargin: -root.monitor?.width ?? 0
        anchors.topMargin: -root.monitor?.height ?? 0
        anchors.bottomMargin: -root.monitor?.height ?? 0

        onReleased: {
            PopupManager.sigClose(PopupManager.getTop())
        }
    }

    MouseControl {
        anchors.fill: parent
        anchors.leftMargin: -Cell.w(root.safeMargin)*2
        anchors.rightMargin: -Cell.w(root.safeMargin)*2
        anchors.topMargin: -Cell.h(root.safeMargin)
        anchors.bottomMargin: -Cell.h(root.safeMargin)
        onReleased: {
            root.marginsPressed()
        }
    }

}
