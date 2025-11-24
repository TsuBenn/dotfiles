import qs.services

import QtQuick

Canvas {

    id: root

    property list<int> points: Cava.points
    property list<int> smoothPoints: []
    property int smoothing: 2
    property string color: "white"

    anchors.fill: parent
    anchors.centerIn: parent

    onPointsChanged: {
        root.requestPaint()
    }

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)

        var points = root.points
        var h = height
        var w = width
        var n = Cava.bars

        if (n < 2) return

        var smoothWindow = root.smoothing; // adjust for more/less smoothing
        root.smoothPoints = [];
        for (var i = 0; i < n; ++i) {
            var sum = 0, count = 0;
            for (var j = -smoothWindow; j <= smoothWindow; ++j) {
                var idx = Math.max(0, Math.min(n - 1, i + j));
                sum += points[idx];
                count++;
            }
            root.smoothPoints.push(sum / count);
        }

        ctx.beginPath() 
        ctx.moveTo(0, h)
        for (var i = 0; i < n; i++) {
            var x = (i/(n-1))*w
            var y = h - (smoothPoints[i]/100)*h
            ctx.lineTo(x, y)
        }
        ctx.lineTo(w, h)
        ctx.closePath() 

        ctx.fillStyle = root.color
        ctx.fill()

    }
}

