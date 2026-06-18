pragma ComponentBehavior: Bound

import qs.components.bar
import qs.components.popups
import qs.config
import qs.services
import qs.modules

import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtMultimedia
import Qt5Compat.GraphicalEffects

WlSessionLockSurface {

    id: root

    property bool processing: AuthInfo.authenticating

    property bool focused: monitor.name == HyprInfo.focusedMonitor.name

    property bool onlyFocusedMonitorLockScreen: SettingsInfo.onlyFocusedMonitorLockScreen

    property var monitor: {
        "width": 1920,
        "height": 1080,
    }

    onVisibleChanged: {
        password_field.focus = true
        lock_screen_anim.restart()
    }

    function unlock(password: string) {
        AuthInfo.verify(password)
    }

    MediaPlayer {
        id: lock_screen_music
        source: SystemInfo.configdir + "/assets/lock_screen_music.mp3"
        audioOutput: AudioOutput {
            id: lock_screen_music_output
            muted: root.monitor.name != HyprInfo.monitors[0].name
        }
    }

    WallpaperEngine {
        anchors.fill: parent
        layer.enabled: true
        layer.effect: GaussianBlur {

            Behavior on radius {NumberAnimation {duration: 500; easing.type: Easing.OutCubic}}

            cached: true
            radius: root.focused ? 10 : 0
            samples: 10
            transparentBorder: false
        }
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
            anchors.fill: parent
            color: Qt.darker(Colors.bgBase,2)
            opacity: root.focused ? 0.5 : 0
            Behavior on opacity {NumberAnimation {duration: 500; easing.type: Easing.OutCubic}}
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

    Rectangle {

        visible: opacity

        opacity: SettingsInfo.bgCavaLock && !root.focused

        Behavior on opacity {NumberAnimation {
            duration: 500
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

    component BgCava: CellAudioVisual {

        visible: opacity > 0

        opacity: SettingsInfo.bgCavaLock*0.2

        property real interval: 3

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

        w: Cell.wCount(parent.width,"floor")
        h: Cell.hCount(parent.height/interval,"floor")

        spacing: 2
        barW: 2

        color: [Colors.secondary, Colors.warning, Colors.danger]

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: cava_mask
        }

    }

    BgCava {rotation: 180}

    BgCava {y: parent.height - parent.height/interval}

    Rectangle {

        id: util_bar

        property bool peek: false && root.focused

        Behavior on anchors.topMargin {NumberAnimation {duration: 200; easing.type: Easing.OutCubic}}

        anchors.topMargin: -Cell.h(1)*!peek

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        implicitHeight: Cell.h(1)

        color: Colors.bgSurface


        Item {

            RowLayout {

                spacing: Cell.w(1)

                x: Cell.toW(root.width,"floor") - width - Cell.w(1)

                System {
                    visible: false
                    interactive: false
                }

                CellText {
                    text: ""
                }

                OBS {
                    interactive: false
                }

                Volume {}

                CellText {
                    text: "*" + NotificationsInfo.totalMessagesCount()
                    color: Colors.danger
                }

                ControlPanel {
                    interactive: false
                }

            }

        }

    }

    MouseArea {

        acceptedButtons: Qt.NoButton
        hoverEnabled: true

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        implicitHeight: util_bar.peek ? Cell.h(3) : 1

        onEntered: {
            util_bar.peek = true
            unpeek_util.stop()
        }

        onExited: {
            unpeek_util.restart()
        }

    }

    Timer {

        id: unpeek_util
        interval: 500
        onTriggered: {
            util_bar.peek = false
        }

    }

    ColumnLayout {

        opacity: root.focused ? 1 : 0

        layer.enabled: true
        Behavior on opacity {NumberAnimation {duration: 500*SettingsInfo.hyprAnim; easing.type: Easing.OutCubic}}

        id: layout

        x: Cell.centerWCell(implicitWidth, root.monitor.width)
        y: Cell.centerHCell(implicitHeight, root.monitor.height)

        spacing: 0

        CellText {
            Layout.leftMargin: Cell.centerWCell(width, parent.width)
            text: ANSI.render(DateTime.hour12 + ":" + DateTime.minute)
            pure: false
            lockPure: true
        }

        CellText {
            Layout.leftMargin: Cell.centerWCell(width, parent.width)
            text: `--${DateTime.dayofweek_long.toUpperCase()}--`
            font: Cell.fontBB
        }
        CellText {
            Layout.leftMargin: Cell.centerWCell(width, parent.width)
            text: `${DateTime.date}th ${DateTime.month_numeral}, ${DateTime.year}`
            font: Cell.fontBB
        }

        CellText {
            text: "\n\n\n"
        }

        CellText {
            id: user
            Layout.leftMargin: Cell.centerWCell(width, parent.width)
            text: SystemInfo.username + (`${SystemInfo.username}@${SystemInfo.hostname}`.length%2!=0 ? " " : "") + "@" + SystemInfo.hostname
            color: Colors.secondary
            font: Cell.fontB
        }

        CellText {
            id: lock_status
            property string status: "unlocked"
            Layout.leftMargin: Cell.centerWCell(width, parent.width)
            text: `--${status}--`
            color: Colors.warning
        }

        CellText {
            text: ""
        }

        Cells {

            w: 30
            h: 3

            color: "transparent"

            CellBox {

                w: parent.w
                h: parent.h

                CellTextField {

                    id: password_field

                    x: Cell.w(1)

                    w: 26
                    h: 1

                    hidden: true

                    disabled: root.processing   

                    escapeToUnFocus: false

                    placeholder: "Password"

                    onTextInput: (input) => {
                        LockInfo.password = input
                    }

                    Component.onCompleted: {
                        LockInfo.passwordChanged.connect(()=> {
                            if (!password_field?.focus) {
                                password_field.set(LockInfo.password)
                            }
                        })
                    }

                    onEntered: (input) => {
                        root.processing = true
                        pwd_status.text = " Info: Processing password... "
                        pwd_status.color = Colors.info
                        root.unlock(input)
                    }

                }

            }

        }

        CellText {
            text: ""
        }

        RowLayout {

            Layout.leftMargin: Cell.centerWCell(width, parent.width)

            spacing: Cell.w(2)

            CellButton {

                text: "Music"

                color: SettingsInfo.lockScreenMusic ? Colors.accentStrong : Colors.bgOverlay
                fg: SettingsInfo.lockScreenMusic ? Colors.onAccent : Colors.fgBase

                onReleased: (button) => {
                    if (button == "L") {
                        SettingsInfo.toggle("lockScreenMusic")
                        if (SettingsInfo.lockScreenMusic) {
                            if (MediaPlayerInfo.status == "playing") {
                                MediaPlayerInfo.pauseMedia()
                            }
                            lock_screen_music.play()
                        } else {
                            MediaPlayerInfo.pauseMedia()
                            lock_screen_music.stop()
                        }
                    }
                }

            }

            CellButton {

                text: "Cava"

                color: SettingsInfo.bgCavaLock ? Colors.accentStrong : Colors.bgOverlay
                fg: SettingsInfo.bgCavaLock ? Colors.onAccent : Colors.fgBase

                onReleased: (button) => {
                    if (button == "L") {
                        SettingsInfo.toggle("bgCavaLock")
                    }
                }

            }

            CellButton {

                text: "Power"

                color: [Colors.accentStrong, Colors.bgOverlay]
                fg: [Colors.onAccent, Colors.fgBase]

                onReleased: (button) => {
                    if (button == "L") {
                        PopupManager.open("power")
                    }
                }

            }

        }

        CellText {
            text: ""
        }

        CellText {
            Layout.leftMargin: Cell.centerWCell(width, parent.width)
            id: pwd_status
            text: ""
            bg: Colors.bgSurface
        }


    }

    MouseControl {

        id: mouse

        x: layout.x - 200
        y: layout.y - 200
        height: layout.height + 400
        width: layout.width + 400

        acceptedButtons: Qt.NoButton

    }

    Timer {
        id: reset_pwd_status
        interval: 5000
        onTriggered: {
            pwd_status.text = ""
        }
    }

    SequentialAnimation {
        id: lock_screen_anim
        ParallelAnimation {
            NumberAnimation {
                target: lock_status_buffer
                property: "opacity"
                from: 0
                to: 1
                duration: 500
                easing.type: Easing.OutCubic
            }
        }
        ScriptAction {
            script: {
                lock_status.status = "locked"
                lock_screen_music_output.volume = AudioInfo.volume/100
                if (SettingsInfo.lockScreenMusic && MediaPlayerInfo.status != "playing") {
                    lock_screen_music.play()
                } else {
                    lock_screen_music.stop()
                }

            }
        }
        PauseAnimation {
            duration: 500
        }
        NumberAnimation {
            target: black_lock_screen
            property: "opacity"
            to: 0
            duration: 1000
            easing.type: Easing.OutCubic
        }

    }

    Rectangle {
        id: black_lock_screen
        anchors.fill: parent
        color: "black"
        opacity: 1
    }

    ShaderEffectSource {
        id: lock_status_buffer
        width: Cell.w(lock_status.w)
        height: Cell.h(lock_status.h)
        x: lock_status.x + layout.x
        y: lock_status.y + layout.y
        opacity: layout.opacity
        live: true
        hideSource: true
        sourceItem: lock_status
    }

    PowerPopup {

        opacity: root.focused

        monitor: root.monitor

        name: "power"

        lock: true

    }

    SequentialAnimation {
        id: unlock_anim
        ParallelAnimation {
            NumberAnimation {
                target: black_lock_screen
                property: "opacity"
                to: 1
                duration: 500
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: lock_screen_music_output
                property: "volume"
                to: 0
                duration: 1000
                easing.type: Easing.InCubic
            }
        }
        ParallelAnimation {
            ScriptAction {
                script: {
                    lock_status.status = "unlocked"
                }
            }
            NumberAnimation {
                target: lock_status_buffer
                property: "opacity"
                to: 0
                duration: 700
                easing.type: Easing.InCubic
            }
        }
        ScriptAction {
            script: {
                SystemInfo.unlockRequest()
            }
        }
    }

    Connections {
        target: AuthInfo
        function onVerified() {
            unlock_anim.restart()
        }
        function onFailed() {
            pwd_status.text = " Error: Wrong password! "
            pwd_status.color = Colors.danger
            reset_pwd_status.running = true
            password_field.set("")
            root.processing = false
        }
    }

}
