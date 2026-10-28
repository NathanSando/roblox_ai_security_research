local ConnectionGraph = {}
local ReportText = require(script.Parent.ReportText)
local ScriptEditorService = game:GetService("ScriptEditorService")

function ConnectionGraph.create(parent, finding, colors)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.BackgroundTransparency = 1
    frame.LayoutOrder = #parent:GetChildren()
    frame.Parent = parent
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 12)
    layout.Parent = frame
    local order = 0

    local function label(container, value, color, width)
        local item = Instance.new("TextLabel")
        item.Size = UDim2.new(width or 1, 0, 0, 0)
        item.AutomaticSize = Enum.AutomaticSize.Y
        item.BackgroundTransparency = 1
        item.Text = value
        item.TextSize = 16
        item.Font = Enum.Font.Gotham
        item.TextColor3 = color or colors.text
        item.TextWrapped = true
        item.TextXAlignment = Enum.TextXAlignment.Left
        item.TextYAlignment = Enum.TextYAlignment.Top
        order = order + 1
        item.LayoutOrder = order
        item.Parent = container
        return item
    end

    local feedback = label(frame, "", colors.muted)
    feedback.Visible = false

    local function openScript(path)
        local matches = {}
        for _, object in ipairs(game:GetDescendants()) do
            if object:IsA("LuaSourceContainer") and object:GetFullName() == path then
                table.insert(matches, object)
            end
        end
        feedback.Visible = true
        if #matches ~= 1 then
            feedback.Text = #matches == 0 and ("Script not found: " .. path)
                or ("More than one script has this path: " .. path)
            return
        end
        local ok, opened, message = pcall(function()
            return ScriptEditorService:OpenScriptDocumentAsync(matches[1])
        end)
        if feedback.Parent then
            if ok and opened then
                feedback.Text = "Opened: " .. path
            else
                feedback.Text = "Could not open script: " .. tostring(ok and message or opened)
            end
        end
    end

    local flow = finding.flow or {}
    for index, step in ipairs(flow) do
        if index > 1 then
            local arrow = label(frame, "↓", colors.accent)
            arrow.TextXAlignment = Enum.TextXAlignment.Center
            arrow.TextSize = 28
            arrow.Font = Enum.Font.GothamBold
        end
        local description = type(step) == "table" and step.description or tostring(step)
        local paths = type(step) == "table" and step.scripts or {}

        local stepHeading = label(frame, "STEP " .. index, colors.accent)
        stepHeading.Font = Enum.Font.GothamBold

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 0)
        row.AutomaticSize = Enum.AutomaticSize.Y
        row.BackgroundColor3 = colors.card
        row.BorderSizePixel = 0
        order = order + 1
        row.LayoutOrder = order
        row.Parent = frame
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = row
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 14)
        padding.PaddingBottom = UDim.new(0, 14)
        padding.PaddingLeft = UDim.new(0, 12)
        padding.PaddingRight = UDim.new(0, 12)
        padding.Parent = row
        local columns = Instance.new("UIListLayout")
        columns.FillDirection = Enum.FillDirection.Horizontal
        columns.SortOrder = Enum.SortOrder.LayoutOrder
        columns.Padding = UDim.new(0, 12)
        columns.Parent = row

        local body = label(row, tostring(description), colors.text, 0.58)
        body.RichText = true
        body.Text = ReportText.highlight(description)
        body.Size = UDim2.new(0.58, -6, 0, 0)
        body.LayoutOrder = 1
        local links = Instance.new("Frame")
        links.Size = UDim2.new(0.42, -6, 0, 0)
        links.AutomaticSize = Enum.AutomaticSize.Y
        links.BackgroundTransparency = 1
        links.LayoutOrder = 2
        links.Parent = row
        local stack = Instance.new("UIListLayout")
        stack.SortOrder = Enum.SortOrder.LayoutOrder
        stack.Padding = UDim.new(0, 10)
        stack.Parent = links

        for linkIndex, path in ipairs(paths) do
            local link = Instance.new("TextButton")
            link.Size = UDim2.new(1, 0, 0, 0)
            link.AutomaticSize = Enum.AutomaticSize.Y
            link.BackgroundColor3 = colors.selected
            link.BorderSizePixel = 0
            link.RichText = true
            link.Text = '<b><font color="#97ACDF">OPEN SCRIPT</font></b>\n' .. ReportText.escape(path)
            link.TextSize = 16
            link.Font = Enum.Font.GothamMedium
            link.TextColor3 = colors.text
            link.TextWrapped = true
            link.LayoutOrder = linkIndex
            link.Parent = links
            local linkCorner = Instance.new("UICorner")
            linkCorner.CornerRadius = UDim.new(0, 8)
            linkCorner.Parent = link
            local inset = Instance.new("UIPadding")
            inset.PaddingTop = UDim.new(0, 10)
            inset.PaddingBottom = UDim.new(0, 10)
            inset.PaddingLeft = UDim.new(0, 8)
            inset.PaddingRight = UDim.new(0, 8)
            inset.Parent = link
            link.Activated:Connect(function()
                openScript(path)
            end)
        end
        if #paths == 0 then
            label(links, "No script linked to this step.", colors.muted)
        end
    end
    if #flow == 0 then
        label(frame, "No flow steps were supplied.", colors.muted)
    end
    return frame
end

return ConnectionGraph
