pragma ComponentBehavior: Bound

import qs.components
import qs.components.bar
import qs.components.popups
import qs.components.floats
import qs.modules
import qs.config
import qs.services

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick.Layouts
import QtQuick
import QtMultimedia
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

            property var monitor: Hyprland.monitorFor(screen)

            Component.onCompleted: {
                PopupManager.opened.connect(name => {
                    HintManager.hide();
                    DropdownManager.hide();
                    ContextMenuManager.hide();
                    root.shield = true;
                });
                PopupManager.closed.connect(name => {
                    HintManager.hide();
                    DropdownManager.hide();
                    ContextMenuManager.hide();
                    if (name == "" || PopupManager.active_popups.length == 0)
                        root.shield = false;
                });
                DropdownManager.opened.connect(name => {
                    HintManager.hide();
                    ContextMenuManager.hide();
                    root.shield = true;
                });
                DropdownManager.closed.connect(name => {
                    if (PopupManager.active_popups.length > 0)
                        return;
                    root.shield = false;
                });
                ContextMenuManager.opened.connect(name => {
                    HintManager.hide();
                    root.shield = true;
                });
                ContextMenuManager.closed.connect(name => {
                    if (PopupManager.active_popups.length > 0)
                        return;
                    root.shield = false;
                });
                HintManager.opened.connect(name => {
                    root.shield = true;
                });
                HintManager.closed.connect(name => {
                    if (PopupManager.active_popups.length > 0)
                        return;
                    root.shield = false;
                });
                HyprInfo.hyprEvent.connect(event => {
                    switch (event) {
                    //case "activewindow":
                    case "activespecial":
                    case "closewindow":
                    case "openwindow":
                    case "focusedmon":
                    case "workspace":
                    case "movewindow":
                        {
                            if (event == "movewindow") {
                                showBar.restart();
                            }
                            PopupManager.close();
                            DropdownManager.hide();
                            HintManager.hide();
                            ContextMenuManager.hide();
                            break;
                        }
                    case "configreloaded":
                        {
                            SystemInfo.runDetached(["bash", SystemInfo.configdir + "/scripts/revive.sh"]);
                            break;
                        }
                    }
                });
            }

            SequentialAnimation {
                id: showBar

                ScriptAction {
                    script: {
                        bar.peekBar = true;
                    }
                }
                PauseAnimation {
                    duration: 1000
                }
                ScriptAction {
                    script: {
                        bar.peekBar = false;
                    }
                }
            }

            anchors {
                top: true
                left: true
                right: true
            }

            property bool peekBar: bar.peekBar
            property bool forceBar: (PopupManager.active_popups.length > 0 && !PopupManager.isOpen("quick_menu") && !PopupManager.isOpen("power") && !PopupManager.isOpen("emoji") && !PopupManager.isOpen("wallpaper") && !PopupManager.isOpen("launcher") && !PopupManager.isOpen("screenshot"))
            property bool hideBar: (((Hyprland.focusedWorkspace.hasFullscreen ?? false) && HyprInfo.isFocusedMonitor(root.monitor)) || SettingsInfo.hideBar)

            margins {
                top: -(Cell.h(1) - 1) * (root.hideBar && !root.peekBar && !root.forceBar)

                Behavior on top {
                    NumberAnimation {
                        duration: 200 * !SettingsInfo.hyprAnim
                        easing.type: Easing.OutCubic
                    }
                }
            }

            exclusiveZone: root.implicitHeight * !root.hideBar

            implicitHeight: Cell.h(1) + 1
            color: "transparent"

            Floats {}

            StatusBar {
                id: bar

                hideBar: root.hideBar
                forceBar: root.forceBar
            }

            PanelWindow {

                WlrLayershell.layer: WlrLayer.Bottom
                WlrLayershell.namespace: "qs_background"

                screen: root.screen

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
                        id: bg

                        y: Cell.h()

                        w: Cell.wCount(root.monitor.width, "ceil")
                        h: Cell.hCount(root.monitor.height, "ceil")

                        color: "transparent"

                        Rectangle {
                            id: bar_shadow

                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right

                            implicitHeight: (Cell.h(1)) * !(root.hideBar && !root.peekBar && !root.forceBar)

                            opacity: !(root.hideBar && !root.peekBar && !root.forceBar)

                            Behavior on opacity {
                                SequentialAnimation {
                                    PauseAnimation {
                                        duration: 200
                                    }
                                    NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            color: "black"

                            layer.enabled: true
                            layer.effect: DropShadow {

                                cached: true
                                color: Colors.transparent(Colors.blend("black", Colors.bgBase, 0.2), 0.5 * SettingsInfo.shadow)
                                radius: 10
                                samples: 20

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 500
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }

                        Rectangle {

                            visible: opacity

                            opacity: SettingsInfo.bgCava

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 1000
                                    easing.type: Easing.OutCubic
                                }
                            }

                            anchors.fill: parent

                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop {
                                    position: 0.0
                                    color: Colors.transparent(Qt.darker(Colors.bgBase, 5), 0.5)
                                }
                                GradientStop {
                                    position: 0.4
                                    color: Colors.transparent(Qt.darker(Colors.bgBase, 5), 0.0)
                                }
                                GradientStop {
                                    position: 0.6
                                    color: Colors.transparent(Qt.darker(Colors.bgBase, 5), 0.0)
                                }
                                GradientStop {
                                    position: 1.0
                                    color: Colors.transparent(Qt.darker(Colors.bgBase, 5), 0.5)
                                }
                            }
                        }

                        Rectangle {
                            id: cava_mask

                            visible: false

                            anchors.fill: parent

                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop {
                                    position: 0.0
                                    color: "transparent"
                                }
                                GradientStop {
                                    position: 0.3
                                    color: "white"
                                }
                                GradientStop {
                                    position: 0.7
                                    color: "white"
                                }
                                GradientStop {
                                    position: 1.0
                                    color: "transparent"
                                }
                            }
                        }

                        BgCava {
                            rotation: 180
                        }

                        BgCava {
                            y: background.height - background.height / interval
                        }
                    }
                }
            }

            PanelWindow {
                id: notifcations

                screen: root.screen

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
                id: pacman_progress

                screen: root.screen

                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }

                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "notifcations"

                exclusionMode: ExclusionMode.Ignore

                implicitWidth: Cell.toW(root.monitor.width, "floor")
                implicitHeight: Cell.toH(root.monitor.height, "floor")

                focusable: true

                color: "transparent"

                mask: Region {
                    item: pacman
                }

                PacmanProgress {
                    id: pacman

                    monitor: root.monitor

                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: -Cell.h(1) * (1 - threshold)
                }
            }

            PanelWindow {
                id: popups_screen

                visible: HyprInfo.isFocusedMonitor(root.monitor)

                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }

                WlrLayershell.layer: PopupManager.active_popups.length > 0 ? WlrLayer.Overlay : WlrLayer.Top
                WlrLayershell.namespace: "popups"

                exclusionMode: ExclusionMode.Ignore

                implicitWidth: root.monitor.width
                implicitHeight: root.monitor.height

                focusable: false

                HyprlandFocusGrab {
                    active: root.shield && popups_screen.visible
                    onCleared: {
                        console.log("Grab");
                    }
                    windows: [root, popups_screen]
                }

                color: "transparent"

                mask: Region {
                    item: shield
                }

                Item {
                    id: shield

                    property bool mouse_check: false

                    anchors.topMargin: (root.implicitHeight - 1) * (!PopupManager.isOpen("power") && !PopupManager.isOpen("screenshot"))
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.left: parent.left

                    implicitHeight: root.shield ? root.monitor.height : 0

                    MouseControl {

                        anchors.fill: parent

                        onPressed: {
                            PopupManager.close();
                        }
                    }

                    Item {
                        id: popups_wrapper

                        anchors.fill: parent

                        layer.enabled: true
                        layer.effect: DropShadow {

                            cached: true
                            color: Colors.transparent(Colors.blend("black", Colors.bgBase, 0.2), 0.5 * SettingsInfo.shadow)
                            radius: 10
                            samples: 20

                            Behavior on color {
                                ColorAnimation {
                                    duration: 500
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        Popups {
                            id: popups
                            monitor: root.monitor
                        }
                    }

                    MouseControl {

                        visible: context_menu.visible || dropdown.visible || hint.visible

                        anchors.fill: parent

                        onMoved: {
                            if (HintManager.visible && HintManager.timer == 0)
                                HintManager.hide();
                        }

                        onPressed: {
                            if (!HintManager.visible || HintManager.timer != 0)
                                HintManager.hide();
                            ContextMenuManager.hide();
                            DropdownManager.hide();
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

                    CellHint {
                        id: hint
                        monitor: root.monitor
                    }

                    Cells {
                        id: grid

                        Component.onCompleted: {
                            SettingsInfo.showGrid.connect(() => grid.visible = !grid.visible);
                        }

                        visible: false

                        y: Cell.h(-1)
                        h: 100
                        w: 400
                        grid: true
                        opacity: 0.2

                        color: "black"
                        color2: "transparent"
                    }
                }
            }

            IpcHandler {
                target: "launcher"
                function toggle(): void {
                    PopupManager.toggle("launcher");
                }
            }

            PanelWindow {
                id: lock_screen_background

                screen: root.screen
                visible: opacity > 0

                WlrLayershell.layer: opacity > 0 ? WlrLayer.Overlay : WlrLayer.Top

                WlrLayershell.namespace: "lock_screen_background"

                exclusionMode: ExclusionMode.Ignore

                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }

                focusable: false

                color: Qt.rgba(0, 0, 0, opacity)

                property real opacity: 0

                mask: Region {
                    item: null
                }

                Component.onCompleted: {
                    SystemInfo.lockRequest.connect(() => {
                        lockAnimStart.restart();
                    });
                    SystemInfo.unlockRequest.connect(() => {
                        lockAnimEnd.restart();
                        LockInfo.unlock();
                    });
                }
            }

            SequentialAnimation {
                id: lockAnimStart
                NumberAnimation {
                    target: lock_screen_background
                    property: "opacity"
                    to: 1
                    duration: 200
                    easing.type: Easing.InCubic
                }
                ScriptAction {
                    script: {
                        LockInfo.lock();
                    }
                }
            }

            SequentialAnimation {
                id: lockAnimEnd
                NumberAnimation {
                    target: lock_screen_background
                    property: "opacity"
                    to: 0
                    duration: 500
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    component BgCava: CellAudioVisual {

        visible: opacity > 0

        opacity: SettingsInfo.bgCava * 0.5

        property real interval: 4

        Behavior on opacity {
            NumberAnimation {
                duration: 1000
                easing.type: Easing.OutCubic
            }
        }

        Component.onCompleted: {
            if (visible) {
                Cava.requestStart();
            }
        }
        onVisibleChanged: {
            if (visible) {
                Cava.requestStart();
            } else {
                Cava.release();
            }
        }

        w: Cell.wCount(background.width, "ceil")
        h: Cell.hCount(background.height / interval, "ceil")

        spacing: 2
        barW: 2

        color: [Colors.secondary, Colors.warning, Colors.danger]

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: cava_mask
        }
    }
}
