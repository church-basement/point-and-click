local old_newCanvas = love.graphics.newCanvas
function love.graphics.newCanvas(width, height, settings)
    settings = settings or {}

    if not settings.format then
        -- Fallback chain for supported Canvas formats
        local supportedCanvasFormats = love.graphics.getCanvasFormats()
        local fallbackChain = {
            -- It's possible to include other formats if necessary, as long as they have 4 components: 
            -- https://love2d.org/wiki/PixelFormat
            -- I don't know much about the specifics of these formats, please adapt to what works best for you.  
            -- Note that this does not take into account if `t.gammacorrect = true` is set in `love.conf`, please implement it yourself if needed.
            "rgba8",
            "srgba8",
            "rgb10a2",
            "rgb5a1",
            "rgba4",
            "normal"
        }
        local format = fallbackChain[1]
        local i = 1
        while i <= #fallbackChain and not supportedCanvasFormats[format] do
            i = i + 1
            format = fallbackChain[i]
        end
        if i == #fallbackChain + 1 then
            error("No valid canvas format is supported by the system")
        end

        settings.format = format
    end

    return old_newCanvas(width, height, settings)
end
