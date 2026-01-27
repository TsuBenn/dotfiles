pragma ComponentBehavior:Bound 

import qs.services

import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import Qt5Compat.GraphicalEffects


Item {
    PanelWindow {

        implicitWidth: SystemInfo.monitorwidth

        anchors {
            top: true
            left: true
            right: true
        }

        margins {
            top: 40 * !Hyprland.focusedWorkspace.hasFullscreen
        }

        implicitHeight: bar.screenRadius*2

        Rectangle {

            id: bgCorner

            anchors.fill: parent

            color: Color.bgSurface

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: topCornerMask
                invert: true
            }

        }

        Rectangle {

            id: topCornerMask

            visible: false

            anchors.fill: parent
            color: "white"

            topLeftRadius: bar.screenRadius
            topRightRadius: bar.screenRadius
        }

        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "screenCorners"
        mask: Region {
            item: null
        }

    }
    PanelWindow {

        implicitWidth: SystemInfo.monitorwidth

        anchors {
            bottom: true
            left: true
            right: true
        }
        implicitHeight: bar.screenRadius*2

        Rectangle {
            anchors.fill: parent

            color: Color.bgSurface

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: bottomCornerMask
                invert: true
            }

        }

        Rectangle {

            id: bottomCornerMask

            visible: false

            anchors.fill: parent
            color: "white"

            bottomLeftRadius: bar.screenRadius
            bottomRightRadius: bar.screenRadius
        }

        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "screenCorners"
        mask: Region {
            item: null
        }

    }
}

