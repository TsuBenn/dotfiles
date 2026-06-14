pragma ComponentBehavior: Bound

import qs.config
import qs.modules

import QtQuick.Layouts
import QtQuick

CellPopup {

    id: root

    visible: HintManager.visible

    w: box.w
    h: box.h

    cellX: HintManager.x - Math.round(box.w/2)
    cellY: HintManager.y

    safeMargin: HintManager.margins

    property Component hint: HintManager.hint
    property string header: HintManager.header

    name: "hint"

    onMarginsPressed: {
        close()
    }

    CellBox {

        id: box

        w: Cell.wCount(wrapper.implicitWidth)+2
        h: Cell.hCount(wrapper.implicitHeight)+2

        header {
            text: root.header ? ` ${root.header} ` : ""
        }

        ColumnLayout {

            id: wrapper

            spacing: 0

            Loader {

                sourceComponent: root.hint

            }
        }

    }

}
