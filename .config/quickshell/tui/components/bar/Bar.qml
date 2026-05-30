pragma ComponentBehavior: Bound

import qs.components.bar
import qs.components.popups
import qs.modules
import qs.config
import qs.services

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick.Layouts
import QtQuick
import Qt5Compat.GraphicalEffects

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {

            id: root

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "bar"

            required property var modelData

            property bool shield: false

            screen: modelData

            property string screen_name: screen.name
            property var monitor: HyprInfo.monitors[screen_name] != undefined ? HyprInfo.monitors[screen_name] : {"width": 1920, "height": 1080}

            property HyprlandMonitor monitorObject

            Component.onCompleted: {
                PopupManager.opened.connect((name) => {
                    root.shield = true
                })
                PopupManager.closed.connect((name) => {
                    if (name == "" || PopupManager.active_popups.length == 0) root.shield = false
                })
                DropdownManager.opened.connect((name) => {
                    ContextMenuManager.hide()
                    root.shield = true
                })
                DropdownManager.closed.connect((name) => {
                    if (PopupManager.active_popups.length > 0) return
                    root.shield = false
                })
                ContextMenuManager.opened.connect((name) => {
                    root.shield = true
                })
                ContextMenuManager.closed.connect((name) => {
                    if (PopupManager.active_popups.length > 0) return
                    root.shield = false
                })
                HyprInfo.hyprEvent.connect((event)=> {
                    switch (event) {
                        //case "activewindow":
                        case "activespecial":
                        case "closewindow":
                        case "openwindow":
                        case "focusedmon": 
                        case "workspace": 
                        case "movewindow": {
                            if (event == "movewindow") {
                                showBar.restart()
                            }
                            PopupManager.close()
                            DropdownManager.hide()
                            ContextMenuManager.hide()
                            break;
                        }
                        case "configreloaded": {
                            SystemInfo.runDetached(["bash", SystemInfo.configdir + "/scripts/revive.sh"])
                            break;
                        }
                    }
                })
                for (const m of Hyprland.monitors.values) {
                    if (m.name == screen.name) {
                        monitorObject = m
                    }
                }
            }

            SequentialAnimation {

                id: showBar

                ScriptAction {
                    script: {
                        root.peekBar = true
                    }
                }
                PauseAnimation {
                    duration: 1000
                }
                ScriptAction {
                    script: {
                        root.peekBar = false
                    }
                }
            }

            anchors {
                top: true
                left: true
                right: true
            }

            property bool peekBar: false
            property bool forceBar: (
                PopupManager.active_popups.length > 0 
                && !PopupManager.isOpen("quick_menu") 
                && !PopupManager.isOpen("power") 
                && !PopupManager.isOpen("emoji") 
                && !PopupManager.isOpen("wallpaper")
                && !PopupManager.isOpen("launcher")
            )
            property bool hideBar: (
                ((Hyprland.focusedWorkspace.hasFullscreen ?? false) 
                && Hyprland.focusedMonitor.name == root.monitor.name) 
                || SettingsInfo.hideBar
            )

            margins {
                top: -(Cell.h(1)-1)*(root.hideBar && !root.peekBar && !root.forceBar)

                Behavior on top {
                    NumberAnimation {
                        duration: 200*!SettingsInfo.hyprAnim
                        easing.type: Easing.OutCubic
                    }
                }
            }

            exclusiveZone: root.implicitHeight*!root.hideBar

            implicitHeight: Cell.h(1)

            color: Colors.bgSurface

            Item {

                opacity: (!root.hideBar || root.forceBar || root.peekBar)

                id: bar

                anchors.fill: parent
                //anchors.leftMargin: Cell.w(1)
                //anchors.rightMargin: Cell.w(1)

                MouseArea {

                    visible: PopupManager.active_popups.length > 0

                    anchors.fill: parent

                    onPressed: {
                        PopupManager.close()
                    }
                }

                RowLayout {

                    spacing: 0

                    Workspaces {
                        id: workspaces
                    }

                    CellText {
                        visible: window_title.text
                        text: "│ "
                        color: Colors.fgSubtle
                    }

                    CellText {

                        id: window_title

                        property string wTitle: HyprInfo.focusedwindow.title
                        property string wClass: HyprInfo.focusedwindow.class

                        preferedW: Cell.wCount(bar.width/2-clock.implicitWidth/2-system.implicitWidth-workspaces.implicitWidth) - 10

                        text: `${wClass}`
                        font: Cell.font
                        color: Colors.fgBase

                    }

                }

                System {
                    id: system
                    anchors.right: clock.left
                    anchors.rightMargin: Cell.w(2)
                }

                Clock {
                    id: clock
                    x: Cell.centerWCell(implicitWidth,bar.width)
                }

                BarMediaPlayer {
                    id: media_player
                    anchors.left: clock.right
                    anchors.leftMargin: Cell.w(2)
                }

                RowLayout {

                    x: Cell.alignRightWCell(implicitWidth, bar.width)

                    spacing: Cell.w(0)

                    Volume {}

                    CellText {
                        text: " "
                    }

                    ControlPanel {}

                    CellText {
                        text: " "
                    }

                    Search {
                        id: search
                    }

                }

                MouseArea {

                    visible: ContextMenuManager.visible || ContextMenuManager.visible

                    anchors.fill: parent

                    onPressed: {
                        ContextMenuManager.hide()
                        DropdownManager.hide()
                    }
                }

                MouseArea {

                    visible: root.hideBar

                    anchors.fill: parent

                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton

                    onEntered: {
                        root.peekBar = true
                    }

                    onExited: {
                        root.peekBar = false
                    }
                }

            }

            PanelWindow {

                WlrLayershell.layer: WlrLayer.Bottom
                WlrLayershell.namespace: "qs_background"

                mask: Region {
                    item: background
                }

                focusable: false

                visible: true

                color: "transparent"

                exclusionMode: ExclusionMode.Ignore

                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }

                Item {

                    id: background

                    anchors.fill: parent

                    WallpaperEngine {

                        monitor: root.monitor
                        anchors.fill: parent

                    }

                    Cells {

                        y: Cell.h()

                        id: bg

                        w: Cell.wCount(root.monitor.width)
                        h: Cell.hCount(root.monitor.height, "ceil")

                        color: "transparent"


                        Rectangle {

                            visible: opacity

                            opacity: SettingsInfo.bgCava

                            Behavior on opacity {NumberAnimation {
                                duration: 1000
                                easing.type: Easing.OutCubic
                            }}

                            anchors.fill: parent

                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop { position: 0.0; color: Colors.transparent(Qt.darker(Colors.bgBase, 5), 0.5) }
                                GradientStop { position: 0.4; color: Colors.transparent(Qt.darker(Colors.bgBase, 5), 0.0) }
                                GradientStop { position: 0.6; color: Colors.transparent(Qt.darker(Colors.bgBase, 5), 0.0) }
                                GradientStop { position: 1.0; color: Colors.transparent(Qt.darker(Colors.bgBase, 5), 0.5) }
                            }

                        }

                        Rectangle {

                            id: cava_mask

                            visible: false

                            anchors.fill: parent

                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 0.3; color: "white"}
                                GradientStop { position: 0.7; color: "white"}
                                GradientStop { position: 1.0; color: "transparent" }
                            }

                        }

                        component BgCava: CellAudioVisual {

                            visible: opacity > 0

                            opacity: SettingsInfo.bgCava*0.5

                            Behavior on opacity {NumberAnimation {
                                duration: 1000
                                easing.type: Easing.OutCubic
                            }}

                            Component.onCompleted: {
                                if (visible) {
                                    Cava.requestStart()
                                }
                            }
                            onVisibleChanged: {
                                if (visible) {
                                    Cava.requestStart()
                                } else {
                                    Cava.release()
                                }
                            }

                            w: bg.w
                            h: ((bg.h+1)/2)*(opacity/0.5)

                            spacing: 2
                            barW: 2

                            color: [Colors.secondary, Colors.warning, Colors.danger]

                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: cava_mask
                            }

                        }

                        BgCava {
                            anchors.topMargin: -Cell.h((bg.h+2)/2)*(1-opacity/0.5)
                            anchors.top: parent.top
                            rotation: 180
                        }

                        BgCava {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: -Cell.h((bg.h+2)/2)*(1-opacity/0.5)
                        }


                    }

                }

            }

            PanelWindow {

                id: notifcations

                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }

                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "notifcations"

                exclusionMode: ExclusionMode.Ignore

                implicitWidth: root.monitor.width
                implicitHeight: root.monitor.height

                visible: true

                focusable: true

                color: "transparent"

                mask: Region {
                    item: notif
                }

                NotificationsPopup {

                    id: notif

                    cellX: Cell.wCount(Cell.alignRightWCell(implicitWidth, root.monitor.width)) + 1
                    cellY: 2

                }

            }

            PanelWindow {

                id: popups_screen

                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }

                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "popups"

                exclusionMode: ExclusionMode.Ignore

                implicitWidth: root.monitor.width
                implicitHeight: root.monitor.height

                visible: true

                focusable: false

                HyprlandFocusGrab {
                    active: root.shield
                    windows: [root, popups_screen]
                }

                color: "transparent"

                mask: Region {
                    item: shield
                }

                Item {

                    id: shield

                    property bool mouse_check: false

                    anchors.topMargin: root.implicitHeight*(!PopupManager.isOpen("power")&&!PopupManager.isOpen("screenshot"))
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.left: parent.left

                    implicitHeight: root.shield ? root.monitor.height : 0

                    MouseControl {

                        anchors.fill: parent

                        onPressed: {
                            PopupManager.close()
                        }
                    }

                    Popups {
                        id: popups
                        monitor: root.monitor
                    }

                    MouseControl {

                        visible: context_menu.visible || dropdown.visible

                        anchors.fill: parent

                        onPressed: {
                            ContextMenuManager.hide()
                            DropdownManager.hide()
                        }
                    }

                    CellDropdownMenu {
                        id: dropdown
                        monitor: root.monitor
                    }

                    CellContextMenu {
                        id: context_menu
                        monitor: root.monitor
                    }

                    Cells {

                        Component.onCompleted: {
                            SettingsInfo.showGrid.connect(() => grid.visible = !grid.visible)
                        }

                        id: grid

                        visible: false

                        y: Cell.h(-1)
                        h: 100
                        w: 400
                        grid: true
                        opacity: 0.02

                        color2: "transparent"

                    }

                }

            }

            IpcHandler {
                target: "launcher"
                function toggle(): void {
                    PopupManager.toggle("launcher")
                }
            }

            PanelWindow {

                visible: !BrightnessInfo.available

                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "brightness"

                exclusionMode: ExclusionMode.Ignore

                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }

                focusable: false

                color: Qt.rgba(
                    0,
                    0,
                    0,
                    Math.max(Math.min(1-(BrightnessInfo.brightness/100),0.99),0)
                )

                mask: Region {
                    item: null
                }

            }

        }

    }
}
