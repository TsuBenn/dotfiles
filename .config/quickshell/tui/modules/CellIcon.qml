pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick

Item {

    visible: !SettingsInfo.minimal

    id: root

    property var icon: []
    property string image: ""

    property bool hideOnFail: true

    property bool success: false

    property int w: 5
    property int h: 2

    implicitWidth: Cell.w(success ? w : 0)
    implicitHeight: Cell.h(h)

    function getW() {
        return success ? w : 0
    }

    Loader {

        active: root.visible || !SettingsInfo.optimizeMemory

        sourceComponent: Cells {

        property bool success: (base.visible || image.visible || !root.hideOnFail ) && !SettingsInfo.minimal

        onSuccessChanged: {
            root.success = success
        }

        w: root.hideOnFail && base.source == "" ? 0 : root.w
        h: root.h

        color: "transparent"


        Image {

            id: base

            visible: source != "" && !image.visible

            width: Cell.h(root.h)
            height: Cell.h(root.h)

            source: IconInfo.fetch(root.icon)

            mipmap: true

            fillMode: Image.PreserveAspectCrop

            asynchronous: true

        }

        Image {

            id: image

            visible: root.image != ""

            width: Cell.h(root.h)
            height: Cell.h(root.h)

            source: root.image

            mipmap: true

            fillMode: Image.PreserveAspectCrop

            asynchronous: true

        }

    }

    }

}
