pragma ComponentBehavior: Bound
import qs.config
import qs.modules
import qs.services
import QtQuick

Item {

    property bool optimizeMemory: SettingsInfo.optimizeMemory

    visible: !SettingsInfo.minimal
    id: root

    property var icon: []
    property string image: ""
    property bool hideOnFail: true
    property int w: 5
    property int h: 2

    property string ze_icon: IconInfo.fetch(icon)

    // success is determined at root level
    property bool imageVisible: image != ""
    property bool iconVisible: ze_icon != ""
    property bool success: (imageVisible || iconVisible || !hideOnFail) && !SettingsInfo.minimal

    implicitWidth: Cell.w(success ? w : 0)
    implicitHeight: Cell.h(h)

    function getW(): int {
        return success ? w : 0
    }

    Loader {
        active: root.visible || !root.optimizeMemory

        sourceComponent: Cells {
            w: root.success ? root.w : 0
            h: root.h
            color: "transparent"

            Image {
                id: base
                visible: root.iconVisible && !root.imageVisible
                width: Cell.h(root.h)
                sourceSize: Qt.size(width * 2, height * 2)
                height: Cell.h(root.h)
                source: root.ze_icon
                mipmap: true
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            Image {
                id: img
                visible: root.imageVisible
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
