pragma Singleton

import qs.services

import Quickshell.Services.Notifications
import Quickshell
import QtQuick

Singleton {

    id: root

    property list<Notification> notifications: notificationsServer.trackedNotifications.values

    property int startTimer: 0
    property int timer: 0

    Component.onCompleted: {
        root.startTimer = Math.floor(Date.now()/1000)
    }

    property var notifications_groups: []
    property var flat: []

    /*

     notifications_groups = [
         {
             app: string,
             icon: string,
             notifications: [
                 {
                     object: int (Notification's id), // Keeping track of the current notification's lifetime
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

     flattened = [ // For performance
         { // For apps headers
             type: "app",
             app: string,
             icon: string,
             urgency: int,
             expandable: bool,
             firstSummary: string,
             firstBody: string,
             firstTime: int,
             firstImage: string,
         },
         { // For notifications group
             type: "group",
             app: string, // To track expand state
             object: object, // To dismiss
             expandable: bool,
             time: int,
             urgency: int,
             summary: string,
             body: string,
         },
         { // For notifications subgroup
             type: "subgroup",
             app: string, // To track expand state
             object: object, // To track expand state
             time: int,
             urgency: int,
             summary: string,
             body: string,
         },
         { // Used to expand groups
             type: "expander",
             app: app, // To track expand state
             object: object, // To track expand state
         },
         { // Separator
             type: "app_sep",
         },
         { // Separator
             type: "group_sep",
         },
     ]

     */

    function updateTime() {
        root.timer = Math.floor(Date.now()/1000) - root.startTimer
    }

    function flatten() {

        const buffer = notifications_groups
        let results = []

        for (const app of buffer) {
            results.push({
                "type"         : "app",
                "app"          : app.app ?? "",
                "icon"         : app.icon ?? "",
                "urgency"      : app.notifications[0]?.urgency ?? 0,
                "expandable"   : app.notifications[0]?.group.length > 1 || app.notifications.length > 1,
                "summary" : app.notifications[0]?.group[0]?.summary ?? "",
                "body"    : app.notifications[0]?.group[0]?.body ?? "",
                "time"    : app.notifications[0]?.group[0]?.time ?? 0,
                "image"   : app.notifications[0]?.group[0]?.image ?? "",
            }) 
            if (app.notifications[0]?.group.length > 1 || app.notifications.length > 1) {
                for (const group of app.notifications) {
                    results.push({
                        "type"       : "group",
                        "app"        : app.app,
                        "id"         : group.id,
                        "object"     : group.object,
                        "expandable" : group.group.length > 1,
                        "time"       : group.group[0]?.time ?? 0,
                        "urgency"    : group.urgency ?? 0,
                        "summary"    : group.group[0]?.summary ?? 0,
                        "body"       : group.group[0]?.body ?? 0,
                    })

                    if (group.group.length > 1) {
                        for (let i = 1; i < group.group.length; i++){
                            results.push({
                                'type'    : "subgroup",
                                "app"     : app.app,
                                "id"      : group.id,
                                "object"  : group.object,
                                "urgency" : group.urgency,
                                "time"    : group.group[i]?.time ?? 0,
                                "summary" : group.group[i]?.summary ?? 0,
                                "body"    : group.group[i]?.body ?? 0,
                            })
                        }
                        results.push({
                            "type": "expander",
                            "app"  : app.app,
                            "id"      : group.id,
                        })
                    }

                    results.push({
                        "type": "group_sep",
                        "app"  : app.app,
                        "id"      : group.id,
                    })

                }
            }
            results.push({
                "type": "app_sep"
            })
        }

        return results

    }

    onNotifications_groupsChanged: {
        root.flat = flatten()
        //console.log(JSON.stringify(root.flat,null,2))
    }

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
        refresh()
    }

    function clear() {

        let ids = [] 

        for (const noti of notifications) {
            ids.push(noti.id)
        }

        for (const id of ids) {
            notifications[notifications.findIndex(item => item.id == id)].tracked = false
        }

        refresh()

    }

    function dismiss(object: var) {

        // Dimiss App
        if (typeof object == "string") {

            let buffer = notifications_groups.find(item => item.app == object)

            for (const noti of buffer.notifications) {
                dismiss(noti.object)
            }

            return
        }

        // Dismiss specific object
        if (exists(object)) {
            notifications[notifications.findIndex(item => item.id == object)].tracked = false
        } else {
            console.log("NotificationInfo: Dismissing: No object found!")
        }
        refresh()
    }

    function refresh() {

        updateTime()

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

        seconds = root.timer - seconds

        if (seconds < 10) {
            return "Now"
        }

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

    function exists(id) {
        return notifications.some(item => item.id == id) || id < 0
    }

    property int groupID: 0

    function getGroupID() {
        return groupID++
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
                         object: int (Notification's id), // Keeping track of the current notification's lifetime
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
            "time": root.timer,
            toJSON() {
                return formatTime(this.time)
            }
        }

        const notif = {
            "id": getGroupID(),
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

        keepOnReload: false

        onNotification: (noti) => {
            //console.log("Received Notification: " + noti.summary + " " + noti.body + " " + noti.id)

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
