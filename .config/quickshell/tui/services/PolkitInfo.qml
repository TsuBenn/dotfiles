pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Polkit

Singleton {
    id: root

    property bool active: pk.isActive

    readonly property AuthFlow flow: pk.flow

    property string actionId: flow?.actionId ?? ""

    property string icon: flow?.iconName ?? ""
    property string prompt: flow?.inputPrompt ?? ""
    property string message: flow?.message ?? ""
    property string description: flow?.supplementaryMessage ?? ""
    property string cookie: flow?.cookie ?? ""
    property string selectedId: flow?.selectedIdentity?.string ?? ""
    property bool error: flow?.supplementaryIsError ?? false
    property bool hidden: !flow?.responseVisible ?? true

    property bool required: flow?.isResponseRequired ?? true
    property bool completed: flow?.isCompleted ?? false
    property bool successful: flow?.isSuccessful ?? false
    property bool failed: flow?.failed ?? false
    property bool cancelled: flow?.isCancelled ?? false

    signal request(prompt: string, message: string, description: string, identity: string)
    signal success()
    signal failure()

    onFlowChanged: {
        if (flow) {
            request(prompt, message, description, selectedId);
        }
    }

    function submit(value: string) {
        if (active)
            flow.submit(value);
    }

    function cancel() {
        if (active)
            flow.cancelAuthenticationRequest();
    }

    Timer {
        running: root.flow
        repeat: true
        interval: 1000
        onTriggered: {
            console.log(JSON.stringify(root.flow, null, 2));
        }
    }

    PolkitAgent {
        id: pk

        onIsActiveChanged: {
            if (isActive) {
                console.log("Polkit activated");
            }
        }
    }
}
