function init (args)
    local needs = {}
    needs["type"] = "streaming"
    needs["filter"] = "tcp"
    return needs
end

function setup (args)
    filename = SCLogPath() .. "/" .. name
    file = assert(io.open(filename, "a"))
    SCLogInfo("TCP Log Filename " .. filename)
    http = 0
end

function log(args)
    -- sb_ts and sb_tc are bools indicating the direction of the data
    data, sb_open, sb_close, sb_ts, sb_tc = SCStreamingBuffer()
    if sb_ts then
      print("->")
    else
      print("<-")
    end
    hex_dump(data)
end