hl.monitor({
    output = "eDP-1", -- e.g DP-1 
    mode = "prefered", -- e.g 1920x1080@60
    position = "0x0",
    scale = 1,
})

hl.monitor({
    output = "HDMI-A-1", -- e.g DP-1 
    mode = "1280x800@60", -- e.g 1920x1080@60
    position = "-1280x800",
    scale = 1,
})

for i = 1, 5 do
    hl.workspace_rule({
        workspace = i,
        monitor = "eDP-1"
    })
end

for i = 6, 10 do
    hl.workspace_rule({
        workspace = i,
        monitor = "HDMI-A-1"
    })
end
