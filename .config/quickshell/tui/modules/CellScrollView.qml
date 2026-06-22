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
    property int contentH: content.contentHeight

    property int padding: 0
    property int spacing: 0

    property int offset: 0
    property int contentY: Cell.h(1)*root.offset

    property bool virtualH: false

    readonly property int maxOffset: Math.floor(root.contentH/Cell.cellHeight)-root.h

    property bool snapToMax: false

    property bool snappingToMax: false

    onOffsetChanged: {
        if (offset == maxOffset) {
            snappingToMax = true
        } else {
            snappingToMax = false
        }
        if ((offset > maxOffset || offset < 0) && maxOffset > 0) {
            snapBack()
        }
    }

    function snapBack() {
        offset = Math.max(Math.min(root.offset,maxOffset),0)
    }

    function maximizeScroll() {
        offset = maxOffset
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

    property Component source

    color: "transparent"

    function reset() {
        offset = 0
    }

    ListView {

        implicitWidth: Cell.w(root.w - root.padding*2)
        implicitHeight: Cell.h(root.h)

        clip: true

        contentY: Cell.h(1)*root.offset*!root.virtualH

        interactive: false

        id: content

        spacing: 0

        onContentHeightChanged: {
            if (root.snapToMax && root.snappingToMax) {
                root.offset = root.maxOffset
            }
            root.snapBack()
        }

        model: 1

        delegate: root.source

    }

    Loader {

        active: root.visible || !root.optimizeMemory

        sourceComponent: CellScrollBar {

            z: 2

            visible: root.scrollbar.enabled

            x: Cell.alignRightWCell(implicitWidth, root.implicitWidth)

            onAdjusted: (percent) => {
                root.offset = (root.maxOffset)*percent
            }

            type {
                bg: root.scrollbar.bg
                fg: root.scrollbar.fg
                arrow: root.scrollbar.arrow
            }

            toScale: root.scrollbar.toScale
            thumbH: root.scrollbar.thumbH

            h: root.h
            progress: root.offset/(root.maxOffset)
            contentH: Math.floor(root.contentH/Cell.cellHeight)

            bg: root.scrollbar.bg_color
            color: root.scrollbar.color

        }
    }

    MouseControl {

        anchors.fill: parent

        acceptedButtons: Qt.NoButton

        hoverEnabled: false

        onWheel: (delta) => {
            root.offset = Math.max(Math.min(root.offset - delta,root.maxOffset),0)
        }

    }


}
