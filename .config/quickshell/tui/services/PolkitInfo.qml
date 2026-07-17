pragma Singleton
pragma ComponentBehavior: Bound

import qs.config
import qs.components.popups
import qs.modules
import qs.services

import QtQuick
import Quickshell
import Quickshell.Services.Polkit

Singleton {
    id: root

    property bool active: pk.isActive

    property AuthFlow flow: pk.flow

    property string prompt: flow?.inputPrompt ?? ""
    property string message: flow?.message.trim() ?? ""
    property string extra: flow?.supplementaryMessage.trim() ?? ""
    property bool error: flow?.supplementaryIsError ?? false

    Connections {
        target: root.flow
        function onAuthenticationFailed() {
            root.checking = false;
            root.failed();
        }
    }

    property bool checking: false

    signal request
    signal succeed
    signal failed
    signal canceled

    function cancel() {
        if (active) {
            root.flow.cancelAuthenticationRequest();
            canceled();
        }
    }

    function submit(value: string) {
        root.checking = true;
        root.flow.submit(value);
    }

    Connections {
        target: SettingsInfo
        function onDebugSig() {
            console.log(pk.flow);
            root.cancel();
        }
    }

    PolkitAgent {
        id: pk
        onIsActiveChanged: {
            if (!isActive) {
                root.checking = false;
                root.succeed();
            }
        }
        onAuthenticationRequestStarted: {
            console.log("Authentication needed!");
            root.request();
        }
    }
}
