local ScriptScanner = {}

function ScriptScanner.Scan()

    -- Create the table to store scripts.
    local scripts = {}

    local reye = game:GetService("ServerStorage"):FindFirstChild("Reye")

    -- Find scripts that exist in the workspace.
    for _, object in ipairs(game:GetDescendants()) do

        -- Check if the object is a script and make sure it doesn't include the plugin code.
        local isReye = reye and (
            object == reye or object:IsDescendantOf(reye)
        )

        if object:IsA("LuaSourceContainer") and not isReye then
            -- If it is a script then add it to the table.
            table.insert(scripts, {
                -- Get the object's name.
                name = object.Name,
                -- Get the object's path.
                path = object:GetFullName(),
                -- Get the object's class.
                class = object.ClassName,
                -- Get all code.
                source = object.Source
            })
        end

    end

    -- Return all scripts collected.
    return scripts

end

return ScriptScanner