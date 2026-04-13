pragma Singleton

import Quickshell.Services.Notifications
import Quickshell
import QtQuick

Singleton {

    id: root

    property list<Notification> notifications: notificationsServer.trackedNotifications.values
    property var notifications_groups: []

    signal notificationSent(notification: var)

    function dismiss(app: string, index: int) {
        const buffer = notifications_groups
        for (const i in buffer) {
            if (buffer[i].app == app) {
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

    NotificationServer {
        id: notificationsServer

        onNotification: (noti) => {
            console.log("Received Notification: " + noti.summary + " " + noti.body)

            root.notificationSent({
                "summary": noti.summary,
                "body": noti.body,
                "urgency": noti.urgency,
                "time": 0,
            })

            let notif_groups = root.notifications_groups
            root.notifications_groups = []

            if (notif_groups.length == 0) {
                notif_groups.push({
                    "app": noti.appName,
                    "icon": noti.appIcon,
                    "notifications": [
                        {
                            "summary": noti.summary,
                            "body": noti.body,
                            "urgency": noti.urgency,
                            "time": 0,
                        }
                    ]
                })
            } else {
                let new_group = true
                for (const i in notif_groups) {
                    if (notif_groups[i].app == noti.appName) {
                        notif_groups[i].notifications.push({
                            "summary": noti.summary,
                            "body": noti.body,
                            "urgency": noti.urgency,
                            "time": 0,
                        })
                        new_group = false
                        break
                    }
                }
                if (new_group) {
                    notif_groups.push({
                        "app": noti.appName,
                        "icon": noti.appIcon,
                        "notifications": [
                            {
                                "summary": noti.summary,
                                "body": noti.body,
                                "urgency": noti.urgency,
                                "time": 0,
                            }
                        ]
                    })
                }
            }

            root.notifications_groups = notif_groups

        }
    }

}
