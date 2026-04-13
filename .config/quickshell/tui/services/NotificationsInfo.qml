pragma Singleton

import Quickshell.Services.Notifications
import Quickshell
import QtQuick

Singleton {

    id: root

    property int noti_count: 10

    property list<Notification> notifications: notificationsServer.trackedNotifications.values
    property var notifications_groups: []

    signal notificationSent(notification: Notification)

    NotificationServer {
        id: notificationsServer

        onNotification: (noti) => {
            console.log("Received Notification: " + noti.summary + " " + noti.body)

            const notif_groups = root.notifications_groups

            noti.tracked = true

            const appName = noti.appName 
            const appIcon = noti.appIcon 

            if (root.notifications_groups) {
                for (const groups of notif_groups) {
                    if (appName == groups.app) {
                        groups.notifications.push(noti)
                        console.log("Same group")
                        console.log(root.notifications_groups)
                        console.log(root.notifications_groups[0].notifications.length)
                        const index = notif_groups.indexOf(groups)
                        notif_groups.push(notif_groups.splice(index,1)[0])
                        root.notifications_groupsChanged()
                        root.notificationSent(noti)
                        return
                    }
                }
            }

            notif_groups.push({
                "app": appName,
                "icon": appIcon,
                "notifications": [
                    noti
                ]
            })

            root.notifications_groups = notif_groups
            console.log("New group")
            console.log(root.notifications_groups[0].notifications.length)

            root.notifications_groupsChanged()
            root.notificationSent(noti)
        }
    }

}
