pragma Singleton

import Quickshell.Services.Notifications
import Quickshell
import QtQuick

Singleton {

    id: root

    property list<Notification> notifications: notificationsServer.trackedNotifications.values
    property var notifications_groups: []

    signal notificationSent(notification: var)

    function clear() {
        notifications_groups = []
    }

    function dismiss(app: string, index: int) {
        const buffer = notifications_groups
        for (const i in buffer) {
            if (buffer[i].app == app) {
                if (index == -1) {
                    buffer.splice(i,1)
                    break
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

    function send(app, icon, summary, body, urgency = 0) {
        root.notificationSent({
            "app": app.trim(),
            "icon": icon.trim(),
            "summary": summary.trim(),
            "body": body.trim(),
            "urgency": urgency,
            "time": 0,
        })
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
        add(noti.app, noti.icon, noti.summary, noti.body, noti.urgency)
    }

    function add(appName, appIcon, summary, body, urgency) {
        let notif_groups = root.notifications_groups
        root.notifications_groups = []

        if (notif_groups.length == 0) {
            notif_groups.unshift({
                "app": appName,
                "icon": appIcon,
                "notifications": [
                    {
                        "summary": summary.trim(),
                        "body": [body.trim()],
                        "urgency": urgency,
                        "time": 0,
                    }
                ]
            })
        } else {
            let new_group = true
            for (const i in notif_groups) {
                if (notif_groups[i].app == appName) {
                    for (const j in notif_groups[i].notifications) {
                        if (notif_groups[i].notifications[j].summary == summary) {
                            if (notif_groups[i].notifications[j].time > 7) {
                                notif_groups[i].notifications.unshift(
                                    {
                                        "summary": summary.trim(),
                                        "body": [body.trim()],
                                        "urgency": urgency,
                                        "time": 0,
                                    }
                                )
                            } else {
                                notif_groups[i].notifications[j].body.unshift(body)
                                notif_groups[i].notifications[j].time = 0
                            }
                            break
                        }
                        notif_groups[i].notifications.unshift(
                            {
                                "summary": summary.trim(),
                                "body": [body.trim()],
                                "urgency": urgency,
                                "time": 0,
                            }
                        )
                    }
                    new_group = false
                    break
                }
            }
            if (new_group) {
                notif_groups.unshift({
                    "app": appName,
                    "icon": appIcon,
                    "notifications": [
                        {
                            "summary": summary.trim(),
                            "body": [body.trim()],
                            "urgency": urgency,
                            "time": 0,
                        }
                    ]
                })
            }
        }

        root.notifications_groups = notif_groups
    }

    NotificationServer {
        id: notificationsServer

        onNotification: (noti) => {
            console.log("Received Notification: " + noti.summary + " " + noti.body)

            let summary = noti.summary
            let body = noti.body

            noti.keepOnReload = false

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
                "time": 0,
            })

        }
    }

}
