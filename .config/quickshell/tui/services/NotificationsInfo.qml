pragma Singleton

import qs.services

import Quickshell.Services.Notifications
import Quickshell
import QtQuick

Singleton {

    id: root

    property list<Notification> notifications: notificationsServer.trackedNotifications.values
    property var notifications_groups: []

    signal notificationSent(notification: var)

    onNotificationsChanged: {
        refresh()
    }

    function clear() {
        notifications_groups = []
    }

    function dismiss(app: string, index: int) {
        const buffer = notifications_groups
        for (const i in buffer) {
            if (buffer[i].app == app) {
                if (index == -1) {
                    for (const noti of buffer[i].notifications) {
                        if (noti.object) {
                            noti.object.tracked = false
                        }
                    }
                    buffer.splice(i,1)
                    break
                }
                if (buffer[i].notifications[index].object) {
                    buffer[i].notifications[index].object.tracked = false
                }
                buffer[i].notifications.splice(index, 1)
            }
            if (buffer[i].notifications.length == 0) {
                buffer.splice(i, 1)
            }
        }
        notifications_groups = buffer
    }

    function refresh() {
        const buffer = notifications_groups
        console.log(JSON.stringify(buffer,null,2))
        let to_be_dismissed = []
        for (const notif of buffer) {
            for (const i in notif.notifications) {
                if (notif.notifications[i].object.tracked) {

                } else {
                    to_be_dismissed.push({
                        app: notif.app, 
                        index: i,
                    })
                }
            }
        }
        for (const notif of to_be_dismissed) {
            dismiss(notif.app, notif.index)
        }
        notifications_groups = []
        notifications_groups = buffer
    }

    function formatTime(seconds) {
        const h = Math.floor(seconds / 3600);
        const m = Math.floor((seconds % 3600) / 60);
        const s = seconds % 60;

        if (h > 0) {
            return `${h}h${m > 0 ? m + 'm' : ''}`;
        } else if (m > 0) {
            return `${m}m`;
        } else {
            return `${s}s`;
        }
    }

    function send(app, icon, summary, body, urgency = 0, track = false, action = "") {
        SystemInfo.runDetached(["bash", "-c", `[ "$(notify-send "${summary}" "${body}" --app-name="${app}" --app-icon="${icon}" --urgency="${urgency == 2 ? "critical" : ( urgency == 1 ? "normal" : "low")}" --action="default=Action")" = "default" ] && ${action}`])
    }

    Timer {
        id: counter
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            for (const i in root.notifications_groups) {
                for (const j in root.notifications_groups[i].notifications) {
                    root.notifications_groups[i].notifications[j].time += 1
                }
            }
        }
    }

    onNotificationSent: (noti) => {
        add(noti.app, noti.icon, noti.summary, noti.body, noti.urgency, noti.object)
    }

    function add(appName, appIcon, summary, body, urgency, object, action) {
        // 1. Prepare data
        let groups = root.notifications_groups || [];
        const cleanSummary = summary.trim();
        const cleanBody = body.trim();

        // 2. Helper to create a new notification object
        const createNotif = () => ({
            "summary": cleanSummary,
            "body": [cleanBody],
            "urgency": urgency,
            "object": object,
            "time": 0,
        });

        // 3. Find if the app group already exists
        let group = groups.find(g => g.app === appName);

        if (!group) {
            // Create new group if it doesn't exist
            groups.unshift({
                "app": appName,
                "icon": appIcon,
                "notifications": [createNotif()]
            });
        } else {
            // 4. Look for an existing notification with the same summary
            let existingNotif = group.notifications.find(n => n.summary === cleanSummary);

            if (existingNotif) {
                if (existingNotif.time > 7) {
                    // If it's "old", add a fresh one to the top
                    group.notifications.unshift(createNotif());
                } else {
                    // If it's "new", append the text to the existing body
                    existingNotif.body.unshift(cleanBody);
                    existingNotif.time = 0;
                    if (existingNotif.object) {
                        existingNotif.object.tracked = false;
                    }
                    existingNotif.object = object;
                }
            } else {
                // Summary not found, add new notification to existing group
                group.notifications.unshift(createNotif());
            }
        }

        // 5. Update the root property once
        root.notifications_groups = groups;
    }

    function toRawUnicode(str) {
        return str.split('').map(char => {
            const hex = char.charCodeAt(0).toString(16).padStart(4, '0');
            return `\\u${hex}`;
        }).join('');
    }

    function formatForRice(str) {
        return str
        .replace(/[\u2068\u2069]/g, '') // Kill the ghosts we found earlier
        .replace(/\n/g, ' ')            // Turn newlines into spaces
        .replace(/\s+/g, ' ')           // Collapse multiple spaces into one
        .trim();
    }

    NotificationServer {
        id: notificationsServer

        actionsSupported: true

        onNotification: (noti) => {
            console.log("Received Notification: " + noti.summary + " " + noti.body)

            //console.log(JSON.stringify(noti,null,2))

            //console.log(noti.body)
            //console.log(toRawUnicode(noti.body))

            let summary = formatForRice(noti.summary);
            let body = formatForRice(noti.body)

            //noti.keepOnReload = false
            noti.tracked = true

            let urgency = 0
            if (NotificationUrgency.toString(noti.urgency) == "Critical") {
                urgency = 2
            } else if (NotificationUrgency.toString(noti.urgency) == "Normal") {
                urgency = 1
            }

            let appName = noti.appName
            let appIcon = noti.appIcon

            root.notificationSent({
                "app": appName,
                "icon": appIcon,
                "summary": summary.trim(),
                "body": body.trim(),
                "urgency": urgency,
                "object": noti,
                "time": 0,
            })

        }
    }

}
