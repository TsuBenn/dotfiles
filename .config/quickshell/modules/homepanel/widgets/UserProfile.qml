import qs.services
import qs.assets
import qs.modules.common

import Quickshell
import Quickshell.Widgets
import QtQuick.Layouts
import QtQuick

ColumnLayout {
    id: userprofile

    property string font: Fonts.zzz_vn_font

    property int font_weight: 700

    ClippingRectangle {

        implicitWidth: 170
        implicitHeight: implicitWidth

        radius: implicitWidth/2

        id: pfp

        border {
            width: 0
            color: "black"
        }

        color: "#555555"

        clip: true

        Text {

            anchors.centerIn: parent

            text: "LOADING..."
            font.family: Fonts.zzz_vn_font
            font.pointSize: 16
            color: "gray"

        }

        Image {

            id: image

            anchors.fill: parent
            //scale: 1.2
            //transform: [Translate {y: 10}]
            fillMode: Image.PreserveAspectCrop
            cache: true
            source: GithubInfo.avatar

        }

        focus: true

        property bool stuck: false

        property real globalScale: SystemInfo.monitorheight < 1080 ? SystemInfo.monitorheight/1080*(1/SystemInfo.monitorscale) : 1
        property real ceiling: (SystemInfo.monitorheight*0.5*(1/SystemInfo.monitorscale))/globalScale-40

        MouseControl {

            id: pfpMouse

            anchors.fill: parent

            property real lastY

            onPressed: {
                lastY = mouseY
                pfpDrag.stop()
            }
            onPositionChanged: {
                let dx = mouseY - pfpMouse.lastY 
                dx = Math.min(Math.max(dx, 0)*0.003, 0.12)
                if (pfp.stuck) {
                    scale.yScale = 1 + dx
                    scale.xScale = 1 - dx*1.1
                    translate.x = dx*1.1 * image.width/2
                    translate.y = dx * image.width - 0.12 * image.width/2 - pfp.ceiling
                    dx >= 0.12 ? pfpDrag.start() : pfpDrag.stop()
                }
            }
            onReleased: {
                if (!pfp.stuck) return
                if (pfpDrag.dragForce >= 100) {
                    pfpDrag.stop()
                    pfpDragSucceed.stop()
                    pfpDragSucceed.start()
                } else {
                    pfpDrag.stop()
                    pfpDragFailed.stop()
                    pfpDragFailed.start()
                }
            }

        }


        Component.onCompleted: {
            KeyHandlers.pressed.connect((key) => {
            if (key == Qt.Key_Tab) {
                if (!pfp.stuck) {
                    pfpPressed.stop()
                    pfpReleased.stop()
                    pfpPressed.start()
                }
            }
            })
            KeyHandlers.released.connect((key) => {
            if (key == Qt.Key_Tab) {
                if (!pfp.stuck) {
                    pfpDrag.stop()
                    pfpPressed.stop()
                    pfpReleased.stop()
                    pfpReleased.start()
                }
            }
            })
        }

        transform: [
            Scale {
                id: scale
            },
            Translate {
                id: translate
            }
        ]


        SequentialAnimation {
            id: pfpDrag
            property int dragForce: 0

            property real shakeInt: 0

            ScriptAction {
                script: {
                    pfpDrag.dragForce = 0
                    pfpDrag.shakeInt = 0.01
                }
            }
            ParallelAnimation {
                NumberAnimation {
                    target: scale
                    property: "yScale"
                    duration: pfpPressed.chargeDur
                    to: 1 + pfpPressed.chargeInt
                    easing.type: Easing.OutExpo
                }
                NumberAnimation {
                    target: scale
                    property: "xScale"
                    duration: pfpPressed.chargeDur
                    to: 1 - pfpPressed.chargeInt*1.1
                    easing.type: Easing.OutExpo
                }
                NumberAnimation {
                    target: translate
                    property: "x"
                    duration: pfpPressed.chargeDur
                    to: pfpPressed.chargeInt*1.1 * image.width/2
                    easing.type: Easing.OutExpo
                }
                NumberAnimation {
                    target: translate
                    property: "y"
                    duration: pfpPressed.chargeDur
                    to: pfpPressed.chargeInt * image.width -pfpPressed.chargeInt * image.width/2 - pfp.ceiling 
                    easing.type: Easing.OutExpo
                }
            }
            ParallelAnimation {
                PauseAnimation {duration: 10}
                ScriptAction {
                    script: {
                        translate.y = pfpPressed.chargeInt * image.width -pfpPressed.chargeInt * image.width/2 - pfp.ceiling + (Math.random() * ((pfpDrag.shakeInt) - (-pfpDrag.shakeInt) + 1)) + (-pfpDrag.shakeInt)
                        translate.x = pfpPressed.chargeInt*1.1 * image.width/2 + (Math.random() * ((pfpDrag.shakeInt) - (-pfpDrag.shakeInt) + 1)) + (-pfpDrag.shakeInt)
                        pfpDrag.dragForce += 1
                        pfpDrag.shakeInt += 0.05
                    }
                }
                loops: Animation.Infinite
            }

        }
        SequentialAnimation {
            id: pfpPressed
            property int chargeDur: 500
            property real chargeInt: 0.12

            property real shakeInt: 0

            ScriptAction {
                script: {
                    pfpReleased.jumpInt = 30
                    pfpPressed.shakeInt = 0.1
                }
            }
            ParallelAnimation {
                NumberAnimation {
                    target: scale
                    property: "yScale"
                    duration: 0
                    to: 1
                }
                NumberAnimation {
                    target: scale
                    property: "xScale"
                    duration: 0
                    to: 1
                }
                NumberAnimation {
                    target: translate
                    property: "x"
                    duration: 0
                    to: 0
                }
                NumberAnimation {
                    target: translate
                    property: "y"
                    duration: pfpReleased.jumpInt**0.9
                    to: 0
                    easing.type: Easing.InCubic
                }
            }
            ParallelAnimation {
                NumberAnimation {
                    target: scale
                    property: "yScale"
                    duration: pfpPressed.chargeDur
                    to: 1 - pfpPressed.chargeInt
                    easing.type: Easing.OutExpo
                }
                NumberAnimation {
                    target: scale
                    property: "xScale"
                    duration: pfpPressed.chargeDur
                    to: 1 + pfpPressed.chargeInt
                    easing.type: Easing.OutExpo
                }
                NumberAnimation {
                    target: translate
                    property: "x"
                    duration: pfpPressed.chargeDur
                    to: -pfpPressed.chargeInt * image.width/2
                    easing.type: Easing.OutExpo
                }
                NumberAnimation {
                    target: translate
                    property: "y"
                    duration: pfpPressed.chargeDur
                    to: pfpPressed.chargeInt * image.width + 5
                    easing.type: Easing.OutExpo
                }
            }
            ParallelAnimation {
                PauseAnimation {duration: 10}
                ScriptAction {
                    script: {
                        translate.y = pfpPressed.chargeInt * image.width + 5 + (Math.random() * ((pfpPressed.shakeInt) - (-pfpPressed.shakeInt) + 1)) + (-pfpPressed.shakeInt)
                        translate.x = -pfpPressed.chargeInt * image.width/2 + (Math.random() * ((pfpPressed.shakeInt) - (-pfpPressed.shakeInt) + 1)) + (-pfpPressed.shakeInt)
                        pfpReleased.jumpInt += 2
                        pfpPressed.shakeInt += 0.08
                    }
                }
                loops: Animation.Infinite
            }
        }
        SequentialAnimation {
            id: pfpStuck

            ParallelAnimation {
                NumberAnimation {
                    target: scale
                    property: "yScale"
                    duration: pfpReleased.jumpDur*(4/20)
                    to: 1 + pfpPressed.chargeInt
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: scale
                    property: "xScale"
                    duration: pfpReleased.jumpDur*(4/20)
                    to: 1 - pfpPressed.chargeInt
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: translate
                    property: "x"
                    duration: pfpReleased.jumpDur*(4/20)
                    to: pfpPressed.chargeInt * image.width/2
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: translate
                    property: "y"
                    duration: pfpReleased.jumpDur*(4/20)
                    to: -pfpPressed.chargeInt * image.width
                    easing.type: Easing.InCubic
                }
            }
            ParallelAnimation{
                NumberAnimation {
                    target: scale
                    property: "yScale"
                    duration: pfpReleased.jumpDur*(7/20)
                    to: 1
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: scale
                    property: "xScale"
                    duration: pfpReleased.jumpDur*(7/20)
                    to: 1
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: translate
                    property: "x"
                    duration: pfpReleased.jumpDur*(7/20)
                    to: 0
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: translate
                    property: "y"
                    duration: pfpReleased.jumpDur*(7/20) - pfpReleased.jumpInt**0.2
                    to: -pfpPressed.chargeInt * image.width/2 - pfp.ceiling - 10
                    easing.type: Easing.OutCubic
                }

            }
            ParallelAnimation{
                NumberAnimation {
                    target: translate
                    property: "y"
                    duration: pfpReleased.jumpDur*(3/20)
                    to: -pfpPressed.chargeInt * image.width/2 - pfp.ceiling
                    easing.type: Easing.OutBack
                }

            }

        }
        SequentialAnimation {
            id: pfpDragSucceed

            ScriptAction {
                script: {
                    pfp.stuck = false
                }
            }
            ParallelAnimation{
                NumberAnimation {
                    target: scale
                    property: "yScale"
                    duration: pfpReleased.jumpDur*(3/20)
                    to: 1
                }
                NumberAnimation {
                    target: scale
                    property: "xScale"
                    duration: pfpReleased.jumpDur*(3/20)
                    to: 1
                }
                NumberAnimation {
                    target: translate
                    property: "x"
                    duration: pfpReleased.jumpDur*(3/20)
                    to: 0
                }
                NumberAnimation {
                    target: translate
                    property: "y"
                    duration: pfpReleased.jumpDur*(3/20)
                    to: 0
                }

            }
            ParallelAnimation {
                NumberAnimation {
                    target: translate
                    property: "y"
                    duration: pfpReleased.jumpDur*(6/20)
                    to: pfpPressed.chargeInt*1.2 * image.width + 2
                    easing.type: Easing.OutCubic
                }
            }
            ParallelAnimation {
                NumberAnimation {
                    target: scale
                    property: "yScale"
                    duration: pfpReleased.jumpDur*(4/20)
                    to: 1
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: scale
                    property: "xScale"
                    duration: pfpReleased.jumpDur*(4/20)
                    to: 1
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: translate
                    property: "x"
                    duration: pfpReleased.jumpDur*(4/20)
                    to: 0
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: translate
                    property: "y"
                    duration: pfpReleased.jumpDur*(4/20)
                    to: 0
                    easing.type: Easing.OutCubic
                }
            }

        }
        SequentialAnimation {
            id: pfpDragFailed

            ParallelAnimation{
                NumberAnimation {
                    target: scale
                    property: "yScale"
                    duration: 100
                    to: 1
                    easing.type: Easing.OutBack
                }
                NumberAnimation {
                    target: scale
                    property: "xScale"
                    duration: 100
                    to: 1
                    easing.type: Easing.OutBack
                }
                NumberAnimation {
                    target: translate
                    property: "x"
                    duration: 100
                    to: 0
                    easing.type: Easing.OutBack
                }
                NumberAnimation {
                    target: translate
                    property: "y"
                    duration: 100
                    to: -pfpPressed.chargeInt * image.width/2 - pfp.ceiling
                    easing.type: Easing.OutBack
                }

            }

        }
        SequentialAnimation {
            id: pfpReleased
            property int jumpDur: 250
            property real jumpInt: 50

            ScriptAction {
                script: {
                    if (pfpReleased.jumpInt >= pfp.ceiling-100) {
                        pfpReleased.stop()
                        pfp.stuck = true
                        pfpStuck.start()
                    }
                }
            }
            ParallelAnimation {
                NumberAnimation {
                    target: scale
                    property: "yScale"
                    duration: pfpReleased.jumpDur*(6/20)+pfpReleased.jumpInt**0.2
                    to: 1 + pfpPressed.chargeInt*2
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: scale
                    property: "xScale"
                    duration: pfpReleased.jumpDur*(6/20)+pfpReleased.jumpInt**0.2
                    to: 1 - pfpPressed.chargeInt*1.1
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: translate
                    property: "x"
                    duration: pfpReleased.jumpDur*(6/20)+pfpReleased.jumpInt**0.2
                    to: pfpPressed.chargeInt*1.1 * image.width/2
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: translate
                    property: "y"
                    duration: pfpReleased.jumpDur*(6/20)+pfpReleased.jumpInt**0.2
                    to: -pfpPressed.chargeInt*2 * image.width
                    easing.type: Easing.InCubic
                }
            }
            ParallelAnimation{
                NumberAnimation {
                    target: scale
                    property: "yScale"
                    duration: pfpReleased.jumpDur*(7/20)
                    to: 1
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: scale
                    property: "xScale"
                    duration: pfpReleased.jumpDur*(7/20)
                    to: 1
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: translate
                    property: "x"
                    duration: pfpReleased.jumpDur*(7/20)
                    to: 0
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: translate
                    property: "y"
                    duration: pfpReleased.jumpDur*(7/20) + pfpReleased.jumpInt**0.86
                    to: -pfpPressed.chargeInt * image.width/2 - pfpReleased.jumpInt*1.1
                    easing.type: Easing.OutCubic
                }

            }
            ParallelAnimation{
                NumberAnimation {
                    target: scale
                    property: "yScale"
                    duration: pfpReleased.jumpDur*(9/20)
                    to: 1
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: scale
                    property: "xScale"
                    duration: pfpReleased.jumpDur*(9/20)
                    to: 1
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: translate
                    property: "x"
                    duration: pfpReleased.jumpDur*(9/20)
                    to: 0
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: translate
                    property: "y"
                    duration: pfpReleased.jumpDur*(9/20) + pfpReleased.jumpInt**0.9
                    to: 0
                    easing.type: Easing.InQuad
                }

            }
            ParallelAnimation {
                NumberAnimation {
                    target: translate
                    property: "y"
                    duration: pfpReleased.jumpDur*(6/20)
                    to: 5
                    easing.type: Easing.OutCubic
                }
            }
            ParallelAnimation {
                NumberAnimation {
                    target: scale
                    property: "yScale"
                    duration: pfpReleased.jumpDur*(6/20)
                    to: 1
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: scale
                    property: "xScale"
                    duration: pfpReleased.jumpDur*(6/20)
                    to: 1
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: translate
                    property: "x"
                    duration: pfpReleased.jumpDur*(6/20)
                    to: 0
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: translate
                    property: "y"
                    duration: pfpReleased.jumpDur*(6/20)
                    to: 0
                    easing.type: Easing.OutCubic
                }
            }

        }

    }

    Text {
        Layout.alignment: Qt.AlignCenter

        Layout.topMargin: 18
        Layout.bottomMargin: -12

        text: "- " + SystemInfo.hostname + " -"
        font.family: userprofile.font
        font.pointSize: 14
        font.weight: userprofile.font_weight
        font.wordSpacing: 0
    }

    Text {
        Layout.alignment: Qt.AlignCenter

        Layout.bottomMargin: -12

        text: SystemInfo.username
        font.family: userprofile.font
        font.pointSize: 26
        font.weight: userprofile.font_weight
    }

}

