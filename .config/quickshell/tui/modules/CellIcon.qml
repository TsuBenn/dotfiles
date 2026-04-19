import qs.config
import qs.modules
import qs.services

import QtQuick

Item {

    id: root

    property var icon: []
    property string image: ""

    property bool hideOnFail: true

    property bool success: base.visible

    property int w: 5
    property int h: 2

    implicitWidth: Cell.w(the_icon.w)
    implicitHeight: Cell.h(h)

    Cells {

        id: the_icon

        w: root.hideOnFail && base.source == "" ? 0 : root.w
        h: root.h

        color: "transparent"


        Image {

            id: base

            visible: source != ""

            width: Cell.h(root.h)
            height: Cell.h(root.h)

            source: IconInfo.fetch(root.icon)

            mipmap: true

            fillMode: Image.PreserveAspectCrop

        }

        Image {

            id: image

            visible: root.image != ""

            width: Cell.h(root.h)
            height: Cell.h(root.h)

            source: root.image

            mipmap: true

            fillMode: Image.PreserveAspectCrop

        }

    }
}
