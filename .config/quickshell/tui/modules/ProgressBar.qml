import qs.config
import qs.services
import qs.modules

import QtQuick

Cells {

    id: root

    w: 1
    h: 1

    color: Colors.bgOverlay

    property color fg: Colors.fgBase 
    property int percent: SystemInfo.cpuusage
    
    property bool vertical: true

    Cells {

        anchors.bottom: parent.bottom

        whole: false

        w: root.vertical ? root.w : (root.percent/100)*root.w
        h: root.vertical ? (root.percent/100)*root.h : root.h

        color: root.fg

    }

}
