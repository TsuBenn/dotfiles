pragma ComponentBehavior: Bound 

import qs.config
import qs.modules
import qs.services

import QtQuick

CellPopup {

    id: root

    w: 50
    h: Cell.cellRatio*w

    onVisibleChanged: {
        if (!visible) {
            wheel.visible = false
            description.visible = false
            delay.stop()
        } else {
            HyprInfo.getCursorPos()
            delay.restart()
        }
    }

    Timer {
        id: delay

        interval: 10
        onTriggered: {
            wheel.visible = true
            description.visible = true
        }

    }


    CellBox {

        id: description

        anchors.bottom: wheel.top
        anchors.bottomMargin: Cell.h(2)

        onVisibleChanged: {
            x = Cell.centerWCell(Cell.w(Math.round(descriptor.w)), root.implicitWidth) 
        }

        onWChanged: {
            x = Cell.centerWCell(Cell.w(Math.round(descriptor.w)), root.implicitWidth) 
        }

        w: descriptor.text.length + 2
        h: 3

        border.type: 4

        CellText {

            id: descriptor

            text: "bruh"

        }
    }

    function shortcut(num: int) {
        wheel.items[(num + wheel.items.length-3)%wheel.items.length].action()
        PopupManager.close("quick_menu")
    }

    shortcuts: [
        {
            binds: ["W","1"],
            action: () => {
                root.shortcut(1)
            }
        },
        {
            binds: ["E","2"],
            action: () => {
                root.shortcut(2)
            }
        },
        {
            binds: ["D","3"],
            action: () => {
                root.shortcut(3)
            }
        },
        {
            binds: ["C","4"],
            action: () => {
                root.shortcut(4)
            }
        },
        {
            binds: ["X","S","5"],
            action: () => {
                root.shortcut(5)
            }
        },
        {
            binds: ["Z","6"],
            action: () => {
                root.shortcut(6)
            }
        },
        {
            binds: ["A","7"],
            action: () => {
                root.shortcut(7)
            }
        },
        {
            binds: ["Q","8"],
            action: () => {
                root.shortcut(8)
            }
        },
    ]

    Cells {

        id: wheel

        x: Cell.centerWCell(implicitWidth,root.implicitWidth)
        y: Cell.centerHCell(implicitHeight,root.implicitHeight)

        property var items: [
            {
                label: "D",
                description: "Calendar",
                action: () => {
                    PopupManager.open("calendar")
                },
            },
            {
                label: "C",
                description: "Audio mixer",
                action: () => {
                    PopupManager.sendSignal("control_panel", "mixer")
                    PopupManager.open("control_panel")
                },
            },
            {
                label: "X",
                description: "Notifications",
                action: () => {
                    PopupManager.sendSignal("control_panel", "notif")
                    PopupManager.open("control_panel")
                },
            },
            {
                label: "Z",
                description: "Toggle minimal",
                action: () => {
                    SettingsInfo.toggle("minimal")
                },
            },
            {
                label: "A",
                description: "System Info",
                action: () => {
                    PopupManager.open("system")
                },
            },
            {
                label: "Q",
                description: "Wallpaper",
                action: () => {
                    PopupManager.open("wallpaper")
                },
            },
            {
                label: "W",
                description: "Power",
                action: () => {
                    PopupManager.open("power")
                },
            },
            {
                label: "E",
                description: "Media player",
                action: () => {
                    PopupManager.open("media_player")
                },
            },
        ]

        w: 28
        h: Cell.cellRatio*w

        color: "transparent"

        Repeater {

            model: wheel.items

            delegate: Cells {

                id: selection

                required property int index

                required property var modelData

                property string label: modelData.label ?? ""
                property string description: modelData.description ?? ""
                property var action: modelData.action

                property bool selected: selector.index == (index + 8 -6)%8

                Component.onCompleted: {
                    selector.applied.connect(()=>{
                        if (selected) selection.action()
                    })
                }

                onSelectedChanged: {
                    if (selected) {
                        descriptor.text = " " + modelData.description + " "
                    }
                }

                w: 1
                h: 1

                x: Cell.toW(Math.cos(index*((2*Math.PI)/wheel.items.length))*(Cell.w(wheel.w-1)/2)) + Cell.w(Math.floor(wheel.w/2))
                y: Cell.toH(Math.sin(index*((2*Math.PI)/wheel.items.length))*(Cell.h(wheel.h-1)/2)) + Cell.h(Math.floor(wheel.h/2))

                color: Colors.bgSurface 

                CellBox {

                    id: box

                    border.color: selection.selected ? Colors.accentStrong : Colors.fgBase
                    border.type: selection.selected ? 2 : 1

                    x: -Cell.w(Math.round(selection_text.w/2)) + (selection.index == 7 || selection.index == 0 || selection.index == 1 || selection.index == 2 ? Cell.w(-1) : 0)
                    y: -Cell.h(1) + (selection.index == 5 || selection.index == 6 || selection.index == 7 ? Cell.h(1) : 0)

                    w: selection_text.w + 2
                    h: 3

                    CellText {

                        id: selection_text

                        text: ` ${selection.label} ` 
                        font: selection.selected ? Cell.fontBB : Cell.fontB

                    }

                }

            }

        }

    }

    MouseControl {

        visible: root.visible

        anchors.fill: parent

        id: selector

        property int index: 0

        property int posX: 0
        property int posY: 0

        Behavior on posX {NumberAnimation {duration: 200; easing.type: Easing.OutCubic}}
        Behavior on posY {NumberAnimation {duration: 200; easing.type: Easing.OutCubic}}

        signal applied(index: int)

        function getSliceIndex(mx, my, cx, cy) {
            const dx = mx - cx;
            const dy = my - cy;

            const distance = Math.sqrt(dx*dx + dy*dy)

            if (distance < 10) {
                return -1
            }

            const angle = (2*Math.PI)/8
            const offset = (2*Math.PI)/16

            const mAngle = Math.atan2(dx, -dy) - offset

            let index = Math.floor(mAngle/angle) + 1

            if (index < 0) {
                index = 8 + index
            }

            return index 
        }

        onExited: {
            root.close()
        }

        onReleased: (button) => {
            if (button == "L") {
                applied(index)
                root.close()
            } else if (button == "R") {
                root.close()
            }
        }

        onMoved: (x, y) => {
            index = getSliceIndex(x, y, root.implicitWidth/2,root.implicitHeight/2)
        }

    }

}
