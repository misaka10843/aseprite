function CanCenterImage()
    -- If there's no active sprite
    if app.activeSprite == nil then return false end

    -- If there's no cels in range
    if #app.range.cels == 0 then return false end

    return true
end

function CenterImageInActiveSprite(options)
    if options == nil or (not options.xAxis and not options.yAxis) then
        return
    end

    app.transaction(function()
        local sprite = app.activeSprite
        local center = not sprite.selection.isEmpty and CenterSelection or
                           CenterCel

        for _, cel in ipairs(app.range.cels) do
            if cel.layer.isEditable then center(cel, options, sprite) end
        end
    end)

    app.refresh()
end

function CenterSelection(cel, options, sprite)
    local selection = sprite.selection.bounds

    local outerImage, centeredImage, centertedImageBounds = CutImagePart(cel,
                                                                         selection)
    local imageCenter = GetImageCenter(centeredImage, options)

    local x = centertedImageBounds.x
    local y = centertedImageBounds.y

    if options.xAxis then
        x = selection.x + math.floor(selection.width / 2) - imageCenter.x
    end

    if options.yAxis then
        y = selection.y + math.floor(selection.height / 2) - imageCenter.y
    end

    local contentNewBounds = Rectangle(x, y, centeredImage.width,
                                       centeredImage.height)

    local newImageBounds = contentNewBounds:union(cel.bounds)
    local newImage = Image(newImageBounds.width, newImageBounds.height,
                           sprite.colorMode)

    newImage:drawImage(outerImage, Point(cel.position.x - newImageBounds.x,
                                         cel.position.y - newImageBounds.y))
    newImage:drawImage(centeredImage,
                       Point(x - newImageBounds.x, y - newImageBounds.y))

    local trimmedImage, trimmedPosition =
        TrimImage(newImage, Point(newImageBounds.x, newImageBounds.y))

    sprite:newCel(cel.layer, cel.frameNumber, trimmedImage, trimmedPosition)
end

function CenterCel(cel, options, sprite)
    local x = cel.bounds.x
    local y = cel.bounds.y

    if options.weighted then
        local imageCenter = GetImageCenter(cel.image, options)

        if options.xAxis then
            x = math.floor(sprite.width / 2) - imageCenter.x
        end

        if options.yAxis then
            y = math.floor(sprite.height / 2) - imageCenter.y
        end
    else
        if options.xAxis then
            x = math.floor(sprite.width / 2) - math.floor(cel.bounds.width / 2)
        end

        if options.yAxis then
            y = math.floor(sprite.height / 2) -
                    math.floor(cel.bounds.height / 2)
        end
    end

    cel.position = Point(x, y)
end

function GetImageCenter(image, options)
    local getPixel = image.getPixel
    local centerX = 0

    if options.weighted then
        local total = 0
        local rows = {}

        for x = 0, image.width do
            for y = 0, image.height do
                if getPixel(image, x, y) > 0 then
                    total = total + 1
                end
            end

            table.insert(rows, total)
        end

        local centerValue = total / 2
        centerX = 0

        for i = 1, #rows do
            if rows[i] >= centerValue then
                centerX = i - 1
                break
            end
        end
    else
        centerX = math.floor(image.width / 2)
    end

    local centerY = 0

    if options.weighted then
        local total = 0
        local columns = {}

        for y = 0, image.height do
            for x = 0, image.width do
                if getPixel(image, x, y) > 0 then
                    total = total + 1
                end
            end

            table.insert(columns, total)
        end

        local centerValue = total / 2
        centerY = 0

        for i = 1, #columns do
            if columns[i] >= centerValue then
                centerY = i - 1
                break
            end
        end
    else
        centerY = math.floor(image.height / 2)
    end

    return Point(centerX, centerY)
end

function GetContentBounds(cel, selection)
    local imageSelection = Rectangle(selection.x - cel.bounds.x,
                                     selection.y - cel.bounds.y,
                                     selection.width, selection.height)

    -- Calculate selection content bounds
    local minX, maxX, minY, maxY = math.maxinteger, math.mininteger,
                                   math.maxinteger, math.mininteger

    for pixel in cel.image:pixels(imageSelection) do
        if pixel() > 0 then
            minX = math.min(minX, pixel.x)
            maxX = math.max(maxX, pixel.x)

            minY = math.min(minY, pixel.y)
            maxY = math.max(maxY, pixel.y)
        end
    end

    return Rectangle(minX, minY, maxX - minX + 1, maxY - minY + 1)
end

function CutImagePart(cel, selection)
    local contentBounds = GetContentBounds(cel, selection)

    local oldImage = Image(cel.image)
    local imagePart = Image(cel.image, contentBounds)

    -- Draw an empty image to erase the part
    oldImage:drawImage(Image(contentBounds.width, contentBounds.height),
                       Point(contentBounds.x, contentBounds.y), 255,
                       BlendMode.SRC)

    return oldImage, imagePart,
           Rectangle(cel.bounds.x + contentBounds.x,
                     cel.bounds.y + contentBounds.y, contentBounds.width,
                     contentBounds.height)
end

function TrimImage(image, position)
    -- From API v21, we can use Image:shrinkBounds() for this
    if app.apiVersion >= 21 then
        local trimmedBounds = image:shrinkBounds()
        local trimmedImage = Image(image, trimmedBounds)

        return trimmedImage, Point(position.x + trimmedBounds.x,
                                   position.y + trimmedBounds.y)
    end

    local found, left, top, right, bottom

    -- Left
    found = false

    for x = 0, image.width - 1 do
        for y = 0, image.height - 1 do
            if image:getPixel(x, y) > 0 then
                left = x
                found = true
                break
            end
        end

        if found then break end
    end

    -- Top
    found = false

    for y = 0, image.height - 1 do
        for x = 0, image.width - 1 do
            if image:getPixel(x, y) > 0 then
                top = y
                found = true
                break
            end
        end

        if found then break end
    end

    -- Right
    found = false

    for x = image.width - 1, 0, -1 do
        for y = 0, image.height - 1 do
            if image:getPixel(x, y) > 0 then
                right = x
                found = true
                break
            end
        end

        if found then break end
    end

    -- Bottom
    found = false

    for y = image.height - 1, 0, -1 do
        for x = 0, image.width - 1 do
            if image:getPixel(x, y) > 0 then
                bottom = y
                found = true
                break
            end
        end

        if found then break end
    end

    -- Trim image
    local trimmedBounds = Rectangle(left, top, right - left + 1,
                                    bottom - top + 1)
    local trimmedImage = Image(image, trimmedBounds)

    return trimmedImage,
           Point(position.x + trimmedBounds.x, position.y + trimmedBounds.y)
end

function init(plugin)
    local parentGroup = "edit_transform"

    if app.apiVersion >= 22 then
        parentGroup = "edit_center"

        plugin:newMenuGroup{
            id = parentGroup,
            title = "Center (居中)",
            group = "edit_transform"
        }
    end

    plugin:newCommand{
        id = "Center",
        title = "Center (居中)",
        group = parentGroup,
        onenabled = CanCenterImage,
        onclick = function()
            CenterImageInActiveSprite {xAxis = true, yAxis = true}
        end
    }

    plugin:newCommand{
        id = "CenterX",
        title = "Center X（横向居中）",
        group = app.apiVersion >= 22 and parentGroup or nil,
        onenabled = CanCenterImage,
        onclick = function()
            CenterImageInActiveSprite {xAxis = true, yAxis = false}
        end
    }

    plugin:newCommand{
        id = "CenterY",
        title = "Center Y（纵向居中）",
        group = app.apiVersion >= 22 and parentGroup or nil,
        onenabled = CanCenterImage,
        onclick = function()
            CenterImageInActiveSprite {xAxis = false, yAxis = true}
        end
    }

    if app.apiVersion >= 22 then plugin:newMenuSeparator{group = parentGroup} end

    plugin:newCommand{
        id = "CenterWeighted",
        title = "Center（居中）",
        group = parentGroup,
        onenabled = CanCenterImage,
        onclick = function()
            CenterImageInActiveSprite {
                xAxis = true,
                yAxis = true,
                weighted = true
            }
        end
    }

    plugin:newCommand{
        id = "CenterXWeighted",
        title = "Center X（加权横向居中）",
        group = app.apiVersion >= 22 and parentGroup or nil,
        onenabled = CanCenterImage,
        onclick = function()
            CenterImageInActiveSprite {xAxis = true, weighted = true}
        end
    }

    plugin:newCommand{
        id = "CenterYWeighted",
        title = "Center Y（加权纵向居中）",
        group = app.apiVersion >= 22 and parentGroup or nil,
        onenabled = CanCenterImage,
        onclick = function()
            CenterImageInActiveSprite {yAxis = true, weighted = true}
        end
    }
end

function exit(plugin) end
