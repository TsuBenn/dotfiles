pragma ComponentBehavior: Bound

import qs.config
import qs.modules

import QtQuick
import Quickshell

Item {

    id: root

    property var monitor

    visible: PopupManager.isOpen(name)

    property int w: 3
    property int h: 3

    property int cellX
    property int cellY

    property string name

    property int safeMargin: 2

    property bool escapeToClose: true

    x: {
        if (!monitor) return Cell.w(cellX)
        if (cellX + w <= Cell.wCount(monitor.width)) {
            return Cell.w(cellX)
        }
        return Cell.w(cellX - w)
    }
    y: {
        if (!monitor) return Cell.h(cellY)
        if (cellY + h <= Cell.hCount(monitor.height)) {
            return Cell.h(cellY)
        }
        return Cell.h(cellY - h)
    }

    focus: true

    Repeater {
        model: root.escapeToClose ? 1 : 0

        delegate: ShortcutHandler {
            shortcuts: [
                {
                    binds: "Escape",
                    action: () => PopupManager.close(root.name)
                }
            ]
        }
    }

    implicitWidth: Cell.w(w)
    implicitHeight: Cell.h(h)

    MouseControl {
        anchors.fill: parent
        anchors.leftMargin: -Cell.w(root.safeMargin)
        anchors.rightMargin: -Cell.w(root.safeMargin)
        anchors.topMargin: -Cell.h(root.safeMargin)
        anchors.bottomMargin: -Cell.h(root.safeMargin)
    }

}
