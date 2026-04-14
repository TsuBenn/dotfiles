import qs.config
import qs.modules
import qs.services

import QtQuick

Cells {

    id: root

    w: 5
    h: 2

    color: "transparent"

    property string icon

    Image {

        width: Cell.h(2)
        height: Cell.h(2)

        source: IconInfo.fetch(root.icon)

        mipmap: true

        onStatusChanged: {
            console.log(`${progress} ${IconInfo.fetch(root.icon)}`)
        }

        fillMode: Image.PreserveAspectCrop

    }

}
