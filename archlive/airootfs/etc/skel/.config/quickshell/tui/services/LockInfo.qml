pragma Singleton

import Quickshell

Singleton {

    id: root

    signal lock()
    signal unlock()

    signal lockCall()
    signal unlockCall()

    property string password: ""

}
