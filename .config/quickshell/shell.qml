pragma ComponentBehavior: Bound 

import qs.services
import qs.modules.common

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ShellRoot {
    Scope {

        Bar {}

        Item {
            Component.onCompleted: {
                execOnce.exec(["bash", ".config/quickshell/execOnce.sh"])
            }
        }

        FloatingWindow {

            visible: false

            color: Color.bgSurface

            ListModel {
                id: list
                ListElement {
                    name: "Item"
                }
            }

            ColumnLayout {

                RowLayout {

                    PillButton {
                        text: "Append"

                        bg_color: [Color.bgSurface,Color.bgSurface,Color.accentStrong]
                        fg_color: [Color.textPrimary,Color.textPrimary,Color.bgBase]
                        border_width: [0,2,0]

                        onReleased: {
                            list.append({name: "Hello"})
                            list.append({name: "Hello"})
                            list.append({name: "Hello"})
                            list.append({name: "Hello"})
                            list.append({name: "Hello"})
                            list.append({name: "Hello"})
                            list.append({name: "Hello"})
                            list.append({name: "Hello"})
                            list.append({name: "Hello"})
                        }

                    }
                    PillButton {
                        text: "Insert"

                        bg_color: [Color.bgSurface,Color.bgSurface,Color.accentStrong]
                        fg_color: [Color.textPrimary,Color.textPrimary,Color.bgBase]
                        border_width: [0,2,0]

                        onReleased: {
                            list.insert(0,{name: "Hello"})
                        }

                    }
                    PillButton {
                        text: "Pop back"

                        bg_color: [Color.bgSurface,Color.bgSurface,Color.accentStrong]
                        fg_color: [Color.textPrimary,Color.textPrimary,Color.bgBase]
                        border_width: [0,2,0]

                        onReleased: {
                            list.remove(list.count - 1, 1)
                        }
                    }
                    PillButton {
                        text: "Pop front"

                        bg_color: [Color.bgSurface,Color.bgSurface,Color.accentStrong]
                        fg_color: [Color.textPrimary,Color.textPrimary,Color.bgBase]
                        border_width: [0,2,0]

                        onReleased: {
                            list.remove(0, 1)
                        }
                    }
                    PillButton {
                        text: "Pop all then add one"

                        bg_color: [Color.bgSurface,Color.bgSurface,Color.accentStrong]
                        fg_color: [Color.textPrimary,Color.textPrimary,Color.bgBase]
                        border_width: [0,2,0]

                        onReleased: {
                            list.remove(10,10)
                            for (var i = 1; i < 10; i++) {
                                list.insert(i,{"name": "Hello"})
                            }
                        }
                    }

                }

                ListView {


                    id: theview

                    implicitWidth: 500
                    implicitHeight: 600

                    model: list

                    delegate: delegateModel

                    Component {
                        id: delegateModel
                        PillButton {

                            id: button

                            required property int index

                            text: "List's item " + index

                            bg_color: [Color.bgSurface,Color.bgSurface,Color.accentStrong]
                            fg_color: [Color.textPrimary,Color.textPrimary,Color.bgBase]
                            border_width: [0,2,0]

                            SequentialAnimation {
                                id: addAnimation
                                ParallelAnimation {
                                    PropertyAction {
                                        target: button
                                        property: "x"
                                        value: 100
                                    }
                                    PropertyAction {
                                        target: button
                                        property: "opacity"
                                        value: 0
                                    }
                                }
                                PauseAnimation {
                                    duration: 50 * button.index
                                }
                                ParallelAnimation {
                                    NumberAnimation {
                                        target: button
                                        property: "x"
                                        duration: 200
                                        from: 100
                                        to: 0
                                        easing.type: Easing.InOutQuad
                                    }
                                    NumberAnimation {
                                        target: button
                                        property: "opacity"
                                        duration: 200
                                        from: 0
                                        to: 1
                                        easing.type: Easing.InOutQuad
                                    }
                                }
                            }

                            SequentialAnimation {
                                id: removeAnimation
                                PropertyAction {
                                    target: button
                                    property: "ListView.delayRemove"
                                    value: true
                                }
                                PauseAnimation {
                                    duration: 50 * button.index
                                }
                                ParallelAnimation {
                                    NumberAnimation {
                                        target: button
                                        property: "x"
                                        duration: 200
                                        from: 0
                                        to: 100
                                        easing.type: Easing.InOutQuad
                                    }
                                    NumberAnimation {
                                        target: button
                                        property: "opacity"
                                        duration: 200
                                        from: 1
                                        to: 0
                                        easing.type: Easing.InOutQuad
                                    }
                                }
                                PropertyAction {
                                    target: button
                                    property: "ListView.delayRemove"
                                    value: false
                                }
                            }

                            ListView.onAdd: addAnimation.start()
                            ListView.onRemove: removeAnimation.start()

                        }
                    }

                    displaced: Transition {
                        NumberAnimation {
                            property: "y"
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

        }

    }

    Process {
        id: execOnce

        stdout: StdioCollector {
            onStreamFinished: {
                console.log(text)
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text) console.error(text)
            }
        }
    }
}
