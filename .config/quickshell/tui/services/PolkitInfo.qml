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

    property bool active: flows.length > 0

    property AuthFlow flow: flows[flows.length - 1] ?? null

    property string prompt: flow?.inputPrompt.trim() ?? ""
    property string cleanPrompt: prompt.endsWith(":") ? prompt.slice(0, prompt.length - 1) : prompt
    property string message: flow?.message.trim() ?? ""
    property string extra: flow?.supplementaryMessage.trim() ?? ""
    property bool error: flow?.supplementaryIsError ?? false

    Connections {
        target: root.flow
        function onAuthenticationFailed() {
            console.log("Authentication failed!");
            root.checking = false;
            root.failed();
        }
        function onAuthenticationSucceeded() {
            console.log("Authentication succeed!");
            root.checking = false;
            root.succeed();
            root.completed();
        }
        // function onAuthenticationRequestCancelled() {
        //     console.log("cancelled");
        //     root.flows.pop();
        //     root.checking = false;
        //     root.canceled();
        // }
    }

    property bool checking: false

    property list<AuthFlow> flows: []

    signal request
    signal succeed
    signal failed
    signal canceled

    function completed() {
        root.flows.pop();
        // console.log(root.flows.length);
        if (flows.length > 0) {
            request();
        }
    }

    function cancel() {
        console.log("Authentication canceled!");
        root.flow.cancelAuthenticationRequest();
        root.canceled();
        root.completed();
    }

    function submit(value: string) {
        root.checking = true;
        root.flow.submit(value);
    }

    PolkitAgent {
        id: pk
        onFlowChanged: {
            if (flow) {
                root.flows.push(flow);
            }
        }
        onAuthenticationRequestStarted: {
            console.log("Authentication needed!");
            root.request();
        }
    }
}
