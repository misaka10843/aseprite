ScaleDialog = dofile("./scale/ScaleDialog.lua");
TweenDialog = dofile("./tween/TweenDialog.lua");
ColorAnalyzerDialog = dofile("./color-analyzer/ColorAnalyzerDialog.lua");

function init(plugin)
    -- Check is UI available
    if not app.isUIAvailable then return end

    plugin:newCommand{
        id = "AdvancedScaling",
        title = "高级缩放...",
        group = "sprite_size",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            local dialog = ScaleDialog("Advanced Scaling")
            dialog:show()
        end
    }

    plugin:newCommand{
        id = "AddInbetweenFrames",
        title = "中间帧",
        group = "frame_popup_reverse",
        onenabled = function()
            return app.activeSprite ~= nil and #app.range.frames > 1
        end,
        onclick = function()
            local dialog = TweenDialog("Add Inbetween Frames")
            dialog:show()
        end
    }

    plugin:newCommand{
        id = "ColorAnalyzer",
        title = "分析颜色...",
        group = "sprite_color",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            local dialog = ColorAnalyzerDialog("Analyze Colors")
            dialog:show()
        end
    }
end

function exit(plugin) end

