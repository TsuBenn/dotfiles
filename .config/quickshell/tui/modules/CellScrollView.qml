pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

Cells {

    optimizeMemory: SettingsInfo.optimizeMemory

    id: root

    w: 10
    h: 5

    property int contentW: w - scrollbar.enabled

    property int padding: 0
    property int spacing: 0

    property int offset: 0

    onOffsetChanged: {
        if ((offset > Cell.hCount(content.implicitHeight)-root.h || offset < 0) && Cell.hCount(content.implicitHeight)-root.h > 0) {
            offset = Math.max(Math.min(root.offset,Cell.hCount(content.implicitHeight)-root.h),0)
        }
    }

    property bool keyNav: true

    component Type: Item {
        override property bool enabled: true
        property bool toScale: true
        property int thumbH: 0
        property int bg: 0
        property int fg: 0
        property color color: Colors.fgDim
        property color bg_color: Colors.bgOverlay
        property int arrow: 0
    }

    property Type scrollbar: Type {
        enabled: true
        toScale: true
        thumbH: 1
        bg: 1
        fg: 1
        arrow: 0
    }

    color: "transparent"

    function reset() {
        offset = 0
    }

    onChildrenChanged: {
        for (let i = 4; i < children.length; i++) {
            children[i].parent = content
        }
    }

    Cells {

        w: root.w - root.padding*2
        h: root.h

        clip: true
        color: "transparent"

        ColumnLayout {

            spacing: 0

            id: content

            y: -Cell.h(1)*root.offset


            onImplicitHeightChanged: {
                root.offset = Math.max(Math.min(root.offset,Cell.hCount(content.implicitHeight)-root.h),0)
            }

        }


    }

    Loader {

        active: root.visible || !root.optimizeMemory

        sourceComponent: CellScrollBar {

            z: 2

            visible: root.scrollbar.enabled

            x: Cell.alignRightWCell(implicitWidth, root.implicitWidth)

            onAdjusted: (percent) => {
                root.offset = (Cell.hCount(content.implicitHeight)-root.h)*percent
            }

            type {
                bg: root.scrollbar.bg
                fg: root.scrollbar.fg
                arrow: root.scrollbar.arrow
            }

            toScale: root.scrollbar.toScale
            thumbH: root.scrollbar.thumbH

            h: root.h
            progress: root.offset/(Cell.hCount(content.implicitHeight)-root.h)
            contentH: Cell.hCount(content.implicitHeight)

            bg: root.scrollbar.bg_color
            color: root.scrollbar.color

        }
    }

    MouseControl {

        anchors.fill: parent

        acceptedButtons: Qt.NoButton

        hoverEnabled: false

        onWheel: (delta) => {
            root.offset = Math.max(Math.min(root.offset - delta,Cell.hCount(content.implicitHeight)-root.h),0)
        }

    }


}
