pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {

    id: root

    property string username: "username"
    property int userid: 1
    property string avatar: ""

    Process {
        running: true
        command: ["bash", "-c", "gh api user"]

        stdout: StdioCollector {
            onStreamFinished: {
                const data = text.match(/"login":"([\s\S]+)","id":(\d+).*"avatar_url":"([\s\S]+)","gravatar_id":"",.*$/m)
                root.username = data[1]
                root.userid = data[2]
                root.avatar = data[3]
                console.log("Github Info Fetched!")
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text) console.error(text)
            }
        }
    }

}

