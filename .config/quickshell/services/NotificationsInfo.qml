pragma Singleton

import Quickshell.Services.Notifications
import Quickshell
import QtQuick

Singleton {

    id: root

    property int noti_count: 10

    property list<Notification> notifications: notificationsServer.trackedNotifications.values

    signal notificationSent(notification: Notification)

    NotificationServer {
        id: notificationsServer

        onNotification: (noti) => {
            console.log("Received Notification: " + noti.summary + " " + noti.body)

            root.notificationSent(noti)
            noti.tracked = true
        }
    }

}
