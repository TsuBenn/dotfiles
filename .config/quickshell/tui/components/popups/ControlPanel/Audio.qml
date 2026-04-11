import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

ColumnLayout {

    id: root

    property var box

    spacing: 0

    CellScrollView {

        w: root.box.contentW
        h: 20

        model: AudioInfo.streams

    }

}
