import qs.config
import qs.modules
import qs.services

import QtQuick
import QtQuick.Layouts

Item {

    property var monitor

    visible: threshold > 0

    property bool show: (PacmanInfo.pacmanState == "running" || PacmanInfo.pacmanState == "success") && /* !PopupManager.isOpen("pacman") && */ !FloatsManager.isOpen("pacman") && !root.hidden

    property real threshold: show ? 1 : 0

    Behavior on threshold {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    x: root.expanded ? 0 : Cell.centerWCell(implicitWidth, monitor.width)

    implicitWidth: root.expanded ? Cell.toW(monitor.width, "floor") : Cell.w(root.w)
    implicitHeight: root.expanded ? Cell.toH(monitor.height, "floor") : Cell.h(root.h)

    MouseControl {

        anchors.fill: parent

        onReleased: button => {
            if (button == "L")
                root.expanded = false;
        }
    }

    Cells {
        id: root

        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)
        anchors.right: parent.right

        property bool expanded: false
        property bool hidden: false

        Connections {
            target: FloatsManager
            function onOpened(name) {
                if (name == "pacman") {
                    root.hidden = false;
                }
            }
            function onClosed() {
                root.expanded = false;
            }
        }

        onVisibleChanged: {
            expanded = false;
        }

        w: 104
        h: expanded && PacmanInfo.pacmanState != "success" ? Cell.hCount(layout.implicitHeight) + 2 : 1

        color: Colors.bgSurface

        RowLayout {

            visible: !root.expanded && PacmanInfo.pacmanState != "success" && PacmanInfo.pacmanState != "idle" && PacmanInfo.pacmanState != "cancel"

            spacing: Cell.w(1)

            CellText {
                text: "["
                color: Colors.accentStrong
                font: Cell.fontBB
            }

            CellText {

                text: {
                    switch (PacmanInfo.installState.currentPhase) {
                    case "START":
                        return "Starting    ";
                    case "DOWNLOAD":
                        return "Downloading ";
                    case "INSTALL":
                        return "Installing  ";
                    case "HOOKS":
                        return "Hookings    ";
                    }
                }

                font: Cell.fontB
            }

            CellProgressSquare {
                w: root.w - 53
                h: 1
                percent: PacmanInfo.installState?.overallProgress ?? 0
                cellInterval: 5
                type: 2
                fg: Colors.accentStrong
            }

            CellText {
                property int percent: PacmanInfo.installState?.overallProgress ?? 0
                Behavior on percent {
                    NumberAnimation {
                        duration: 500
                        easing.type: Easing.OutCubic
                    }
                }
                text: percent.toString().padStart(3, " ") + "%"
            }

            CellText {
                text: ""
            }

            CellButton {
                text: "[More]"
                padding: 0
                fg: Colors.info
                color: "transparent"
                font: hovered ? Cell.fontB : Cell.font
                onReleased: button => {
                    if (button == "L") {
                        root.expanded = !root.expanded;
                    }
                }
            }

            CellButton {
                text: "[Show]"
                padding: 0
                fg: Colors.info
                color: "transparent"
                font: hovered ? Cell.fontB : Cell.font
                onReleased: button => {
                    if (button == "L") {
                        FloatsManager.open("pacman");
                    }
                }
            }

            CellButton {
                text: "[Hide]"
                padding: 0
                fg: Colors.info
                color: "transparent"
                font: hovered ? Cell.fontB : Cell.font
                onReleased: button => {
                    if (button == "L") {
                        root.hidden = true;
                    }
                }
            }

            CellButton {
                text: "[Cancel]"
                padding: 0
                fg: Colors.info
                color: "transparent"
                font: hovered ? Cell.fontB : Cell.font
                onReleased: button => {
                    if (button == "L") {
                        PacmanInfo.cancel();
                    }
                }
            }

            CellText {
                text: "]"
                color: Colors.accentStrong
                font: Cell.fontBB
            }
        }

        CellBox {
            id: box

            visible: root.expanded && PacmanInfo.pacmanState != "success" && PacmanInfo.pacmanState != "idle" && PacmanInfo.pacmanState != "cancel"

            w: root.w
            h: root.h

            ColumnLayout {
                id: layout

                spacing: 0

                RowLayout {

                    Layout.leftMargin: Cell.centerWCell(implicitWidth, root.implicitWidth)

                    spacing: 0

                    CellText {

                        text: {
                            let header;
                            switch (PacmanInfo.installState.currentPhase) {
                            case "START":
                                header = "Initializing installation for";
                                break;
                            case "DOWNLOAD":
                                header = "Retrieving packages for";
                                break;
                            case "INSTALL":
                                header = "Processing package changes for";
                                break;
                            case "HOOKS":
                                header = "Running post-transaction hooks for";
                                break;
                            }
                            return " " + header + " <b>" + PacmanInfo.installTarget.join(", ") + "</b>";
                        }
                        color: Colors.info
                        preferedW: Math.min(purify(text).length, box.contentW - 4)
                    }

                    CellLoading {
                        style: 2
                    }
                }

                CellSeparator {
                    visible: (PacmanInfo.installState.currentPhase != "HOOKS" && PacmanInfo.installState.currentPhase != "START")
                    w: box.contentW
                    color: Colors.bgOverlay
                }

                ColumnLayout {

                    Layout.leftMargin: Cell.w(1)

                    visible: PacmanInfo.installState.currentPhase == "DOWNLOAD"

                    spacing: 0

                    RowLayout {

                        spacing: 0

                        CellText {

                            text: "Downloaded size : "
                            color: Colors.fgSubtle
                        }
                        CellText {

                            text: PacmanInfo.installState.progressData.downloadedSize ?? ""
                        }
                        CellText {

                            text: "/" + PacmanInfo.installPlan.totalDownload
                            color: Colors.fgDim
                        }
                    }

                    RowLayout {

                        spacing: 0

                        CellText {

                            text: "Download speed  : "
                            color: Colors.fgSubtle
                        }
                        CellText {

                            text: PacmanInfo.installState.progressData.downloadSpeed ?? ""
                        }
                    }

                    RowLayout {

                        spacing: 0

                        CellText {

                            text: "Time remaining  : "
                            color: Colors.fgSubtle
                        }
                        CellText {

                            text: PacmanInfo.installState.progressData.estimateTime ?? ""
                        }
                    }
                }

                ColumnLayout {

                    Layout.leftMargin: Cell.w(1)

                    visible: PacmanInfo.installState.currentPhase == "INSTALL"

                    spacing: 0

                    RowLayout {

                        spacing: 0

                        CellText {

                            text: "Processing package : "
                            color: Colors.fgSubtle
                        }
                        CellText {

                            text: PacmanInfo.installState.progressData.currentPkg ?? ""
                        }
                        CellText {

                            text: "/" + PacmanInfo.installState.progressData.totalPkg
                            color: Colors.fgDim
                        }
                    }
                }

                CellSeparator {
                    w: box.contentW
                    color: Colors.bgOverlay
                }

                RowLayout {

                    Layout.leftMargin: Cell.w(1)

                    spacing: 0

                    CellText {
                        text: "["
                        color: Colors.fgDim
                    }

                    CellProgressSquare {
                        w: box.contentW - 9
                        h: 1
                        percent: PacmanInfo.installState?.overallProgress ?? 0
                        cellInterval: 5
                        fg: Colors.accentStrong
                    }

                    CellText {
                        text: "] "
                        color: Colors.fgDim
                    }

                    CellText {
                        property int percent: PacmanInfo.installState?.overallProgress ?? 0
                        Behavior on percent {
                            NumberAnimation {
                                duration: 500
                                easing.type: Easing.OutCubic
                            }
                        }
                        text: percent.toString().padStart(3, " ") + "%"
                    }
                }

                CellSeparator {
                    w: box.contentW
                    color: Colors.accentStrong
                }

                RowLayout {

                    Layout.alignment: Qt.AlignRight
                    Layout.rightMargin: Cell.w(1)

                    spacing: Cell.w(1)

                    CellButton {
                        text: "[Less]"
                        padding: 0
                        fg: Colors.info
                        color: "transparent"
                        font: hovered ? Cell.fontB : Cell.font
                        onReleased: button => {
                            if (button == "L") {
                                root.expanded = !root.expanded;
                            }
                        }
                    }

                    CellButton {
                        text: "[Show]"
                        padding: 0
                        fg: Colors.info
                        color: "transparent"
                        font: hovered ? Cell.fontB : Cell.font
                        onReleased: button => {
                            if (button == "L") {
                                FloatsManager.open("pacman");
                            }
                        }
                    }

                    CellButton {
                        text: "[Hide]"
                        padding: 0
                        fg: Colors.info
                        color: "transparent"
                        font: hovered ? Cell.fontB : Cell.font
                        onReleased: button => {
                            if (button == "L") {
                                root.hidden = true;
                            }
                        }
                    }

                    CellButton {
                        text: "[Cancel]"
                        padding: 0
                        fg: Colors.info
                        color: "transparent"
                        font: hovered ? Cell.fontB : Cell.font
                        onReleased: button => {
                            if (button == "L") {
                                PacmanInfo.cancel();
                            }
                        }
                    }
                }
            }
        }

        RowLayout {

            visible: (PacmanInfo.pacmanState == "success" || PacmanInfo.pacmanState == "idle" || PacmanInfo.pacmanState == "cancel")

            spacing: Cell.w(1)

            CellText {
                text: "["
                color: Colors.accentStrong
                font: Cell.fontBB
            }

            CellText {
                text: PacmanInfo.pacmanMode == "install" ? "Pacman successfully installed " + PacmanInfo.installTarget.join(", ") : "Pacman successfully removed " + PacmanInfo.removeTarget.join(", ")
                color: Colors.success
                preferedW: root.w - 21
                font: Cell.fontB
            }

            CellButton {
                text: "[Show]"
                padding: 0
                fg: Colors.info
                color: "transparent"
                font: hovered ? Cell.fontB : Cell.font
                onReleased: button => {
                    if (button == "L") {
                        root.hidden = true;
                        // PopupManager.open("pacman")
                        FloatsManager.open("pacman");
                    }
                }
            }

            CellButton {
                text: "[Dismiss]"
                padding: 0
                fg: Colors.info
                color: "transparent"
                font: hovered ? Cell.fontB : Cell.font
                onReleased: button => {
                    if (button == "L") {
                        PacmanInfo.cancel();
                    }
                }
            }

            CellText {
                text: "]"
                color: Colors.accentStrong
                font: Cell.fontBB
            }
        }
    }
}
