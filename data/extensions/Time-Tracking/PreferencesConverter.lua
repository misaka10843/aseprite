local PreferencesConverter = {supportedVersion = 2}

function PreferencesConverter:Convert(storedData)
    -- If there's no version - assume v1
    local version = storedData.version or 1

    if version > self.supportedVersion then
        print("存储的数据来自于更新的扩展版本...")
        -- TODO: Ask the user if they'd like to reset 
    end

    if version == 1 then
        self:_ConvertToV2(storedData)
        version = storedData.version
    end

    -- In the future, add more versions here as needed
    return storedData
end

function PreferencesConverter:_ShallowCopy(original)
    local copy = {}

    for k, v in pairs(original) do copy[k] = v end

    return copy
end

function PreferencesConverter:_ConvertToV2(storedData)
    -- V2 introduces work session and counting the number of saves

    for _, data in pairs(storedData) do
        for _, yearData in pairs(data.details) do
            for _, monthData in pairs(yearData) do
                for day, dayData in pairs(monthData) do
                    -- Move the day entry into an array - treating it as a single work session
                    local copy = self:_ShallowCopy(dayData)

                    -- Add the saves counter
                    copy.saves = 0

                    monthData[day] = {copy}
                end
            end
        end
    end

    storedData.version = 2
end

return PreferencesConverter
