pragma Singleton

import qs.services

import Quickshell.Services.Notifications
import Quickshell
import QtQuick

Singleton {

    id: root

    property list<Notification> notifications: notificationsServer.trackedNotifications.values

    property var notifications_groups: []

    /*

     notifications_groups = [
         {
             app: string,
             icon: string,
             notifications: [
                 {
                     object: {Notification}, // Keeping track of the current notification's lifetime
                     urgency: int, // 0: low, 1: normal, 2: critical
                     group: [
                         {
                             summary: string,
                             body: string,
                             image: string, // Users icon probably
                             time: int, // Computer uptime at that point, preventing running a timer
                         }
                     ]
                 }
                 // Only append new subgroup if the object of the previous is still alive
             ]
         }
     ] 

     */

    signal notificationSent(notification: var)

    Timer {
        id: refresh_delay

        interval: 100
        onTriggered: {
            refresh()
        }

    }

    onNotificationsChanged: {

        refresh_delay.restart()

    }

    function debug() {
        console.log(JSON.stringify(notifications_groups, null, 2))
    }

    function action(id: int) {
        const buffer = notifications.findIndex(item => item.id == id)
        notifications[buffer].actions.find(item => item.identifier == "default").invoke()
    }

    function clear() {

        let ids = [] 

        for (const noti of notifications) {
            ids.push(noti.id)
        }

        for (const id of ids) {
            notifications[notifications.findIndex(item => item.id == id)].tracked = false
        }

        refresh_delay.restart()

    }

    function dismiss(object: var) {
        // Dimiss App
        if (typeof object == "string") {

            let buffer = notifications_groups.slice()

            buffer = buffer.filter(item => item.app != object)

            notifications_groups = buffer

            refresh_delay.restart()

            return
        }

        // Dismiss specific group
        if (object.tracked) {
            object.tracked = false
        } else {
            console.log("NotificationInfo: Dismissing: No object found!")
        }
        refresh_delay.restart()
    }

    function refresh() {
        let buffer = notifications_groups.slice() // Create a real copy

        for (const i in buffer) {
            buffer[i].notifications = buffer[i].notifications.filter(item => {
                return exists(item.object) 
            })
        }

        // Capture the filtered array!
        //root.notifications_groups = []
        root.notifications_groups = buffer.filter(app => app.notifications.length > 0)

    }

    function formatTime(seconds) {

        seconds = toSeconds() - seconds

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

    onNotificationSent: (noti) => {
        add(noti.summary, noti.body, noti.app, noti.icon, noti.image, noti.urgency, noti.object)
    }

    function toSeconds() {

        const now = Date.now()

        return Math.floor(now/1000)

    }

    function exists(id) {
        return notifications.some(item => item.id == id) || id < 0
    }

    function add(summary, body, app, icon, image, urgency, object) {

        const buffer = [...notifications_groups]

        /*

         notifications_groups = [
             *groups* {
                 app: string,
                 icon: string,
                 notifications: [
                     {
                         object: {Notification}, // Keeping track of the current notification's lifetime
                         urgency: int, // 0: low, 1: normal, 2: critical
                         group: [
                             {
                                 summary: string,
                                 body: string,
                                 image: string, // Users icon probably
                                 time: int, // Computer uptime at that point, preventing running a timer
                             }
                         ]
                     }
                     // Only append new subgroup if the object of the previous is still alive
                 ]
             }
         ] 

         */

        const subgroup = {
            "summary": summary,
            "body": body,
            "image": image,
            "time": toSeconds(),
            toJSON() {
                return formatTime(this.time)
            }
        }

        const notif = {
            "object": object.id,
            "actions": object.actions ?? [],
            "urgency": urgency,
            "group": [
                subgroup
            ],
            toJSON() {
                return { 
                    object: this.object,
                    group: this.group,
                }
            }
        }

        const new_app = {
            "app": app,
            "icon": icon,
            "notifications": [notif],
        }

        // Check if app already existed. Returns the app if available, else return nothing
        const index = buffer.findIndex(item => item.app == app)

        if (index != -1) { // App exists -> append new notifications group, or does it?

            const group = buffer.splice(index, 1)[0] // Remove and captures the group to later put it on top of the notification list

            // Check if the newest notification group's object is still alive, if yes then append new notification group
            if (exists(group.notifications[0].object)) {
                group.notifications.unshift(notif)
            } 
            // If the newest notifications group's object is dead then merge it with the new group
            else {
                group.notifications[0].object = object.id // replacing the object with the available one
                group.notifications[0].urgency = urgency
                group.notifications[0].group.unshift(subgroup) // append new subgroup into the existing group
            }

            buffer.unshift(group) // Put the new app group on top of the notification list

        } else {
            // App doesn't exist yet -> append new app group
            buffer.unshift(new_app)
        }

        root.notifications_groups = buffer

        //debug()

        exists(0)

        //root.refresh() // Let this function handles the clean up

    }

    function toRawUnicode(str) {
        return str.split('').map(char => {
            const hex = char.charCodeAt(0).toString(16).padStart(4, '0');
            return `\\u${hex}`;
        }).join('');
    }

    function strip(str) {
        return str
        .replace(/[\u2068\u2069]/g, '') // Kill the ghosts we found earlier
        .replace(/\n/g, ' ')            // Turn newlines into spaces
        .replace(/\s+/g, ' ')           // Collapse multiple spaces into one
        .trim();
    }

    NotificationServer {

        id: notificationsServer

        actionsSupported: true

        keepOnReload: true

        onNotification: (noti) => {
            console.log("Received Notification: " + noti.summary + " " + noti.body + " " + noti.id)

            noti.tracked = true

            // Data clean up
            const summary = strip(noti.summary)
            const body = strip(noti.body)
            const app = noti.appName
            const icon = noti.appIcon
            const image = noti.image
            const urgency = parseInt(noti.urgency.toString())
            const lastGen = noti.lastGeneration

            const sendObject = {
                "lastGen": lastGen,
                "summary": summary,
                "body": body,
                "app": app,
                "icon": icon,
                "image": image,
                "urgency": urgency,
                "object": noti
            }

            // Notify the system
            root.notificationSent(sendObject)

        }
    }

}
