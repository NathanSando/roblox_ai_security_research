local Dropdown = require(script.Parent.Dropdown)
local ResultsUI = {}
local ReportText = require(script.Parent.ReportText)
local ConnectionGraph = require(script.Parent.ConnectionGraph)

local colors = {
    background = Color3.fromRGB(26, 27, 29),
    card = Color3.fromRGB(36, 38, 41),
    selected = Color3.fromRGB(57, 60, 64),
    text = Color3.fromRGB(212, 233, 232),
    muted = Color3.fromRGB(212, 233, 232),
    accent = Color3.fromRGB(151, 172, 223),
    outline = Color3.fromRGB(151, 157, 166),
    high = Color3.fromRGB(255, 110, 110),
    medium = Color3.fromRGB(255, 170, 65),
    low = Color3.fromRGB(255, 225, 80),
}

local reactionImages = {
    high = "rbxassetid://80005288697256",
    medium = "rbxassetid://128499006237226",
    low = "rbxassetid://132770158230638",
    empty = "rbxassetid://106471974498044",
}

local function reactionImage(parent, asset)
    if not asset then
        return
    end
    local image = Instance.new("ImageLabel")
    image.Name = "ReactionImage"
    image.Size = UDim2.new(1, 0, 0, 120)
    image.BackgroundTransparency = 1
    image.Image = asset
    image.ScaleType = Enum.ScaleType.Fit
    image.LayoutOrder = #parent:GetChildren()
    image.Parent = parent
end
-- Each column scrolls independently, including long reports and code excerpts.
local function column(parent, position, size)
    local frame = Instance.new("ScrollingFrame")
    frame.Position = position
    frame.Size = size
    frame.BackgroundColor3 = colors.background
    frame.BorderSizePixel = 0
    frame.ScrollBarThickness = 6
    frame.ScrollBarImageColor3 = colors.accent
    frame.CanvasSize = UDim2.fromOffset(0, 0)
    frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    frame.Parent = parent

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 16)
    padding.PaddingBottom = UDim.new(0, 16)
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 12)
    layout.Parent = frame
    return frame
end

local function clear(frame)
    for _, child in ipairs(frame:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
    frame.CanvasPosition = Vector2.zero
end

local function text(parent, value, color)
    local item = Instance.new("TextLabel")
    item.Size = UDim2.new(1, 0, 0, 0)
    item.AutomaticSize = Enum.AutomaticSize.Y
    item.BackgroundTransparency = 1
    item.RichText = true
    item.Text = ReportText.highlight(value)
    item.TextColor3 = color or colors.text
    item.TextSize = 16
    item.Font = Enum.Font.Gotham
    item.TextWrapped = true
    item.TextXAlignment = Enum.TextXAlignment.Left
    item.TextYAlignment = Enum.TextYAlignment.Top
    item.LayoutOrder = #parent:GetChildren()
    item.Parent = parent
    return item
end

local function textBlock(item)
    item.BackgroundTransparency = 0
    item.BackgroundColor3 = colors.card
    item.BorderSizePixel = 0
    local inset = Instance.new("UIPadding")
    inset.PaddingTop = UDim.new(0, 10)
    inset.PaddingBottom = UDim.new(0, 10)
    inset.PaddingLeft = UDim.new(0, 12)
    inset.PaddingRight = UDim.new(0, 12)
    inset.Parent = item
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = item
end
function ResultsUI.create(plugin)
    local settings = DockWidgetPluginGuiInfo.new(
        Enum.InitialDockState.Float, false, true, 850, 600, 600, 360
    )
    local panel = plugin:CreateDockWidgetPluginGuiAsync("ReyeResults", settings)
    panel.Title = "Reye Results"

    local list = column(panel, UDim2.fromScale(0, 0), UDim2.new(0.35, 0, 1, 0))
    local details = column(panel, UDim2.fromScale(0.35, 0), UDim2.new(0.65, 0, 1, 0))
    local selectedButton

    local function showResultsPrompt(message)
        clear(details)
        local heading = text(details, "RESULTS", colors.accent)
        heading.Font = Enum.Font.GothamBold
        text(details, message or "Open a category and select an issue to view its details.")
    end
    local function section(parent, title, value)
        local heading = text(parent, title, colors.accent)
        heading.Font = Enum.Font.GothamBold
        textBlock(text(parent, value))
    end

    local function selectButton(button)
        if selectedButton then
            selectedButton.BackgroundColor3 = colors.card
        end
        selectedButton = button
        if selectedButton then
            selectedButton.BackgroundColor3 = colors.selected
        end
    end

    local function detailDropdown(title)
        local header = Instance.new("TextButton")
        header.Size = UDim2.new(1, 0, 0, 0)
        header.AutomaticSize = Enum.AutomaticSize.Y
        header.Text = "+   " .. title
        header.TextColor3 = colors.accent
        header.TextSize = 16
        header.Font = Enum.Font.GothamBold
        header.TextWrapped = true
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.LayoutOrder = #details:GetChildren()
        header.Parent = details
        textBlock(header)
        header.BackgroundColor3 = colors.selected

        local content = Instance.new("Frame")
        content.Size = UDim2.new(1, 0, 0, 0)
        content.AutomaticSize = Enum.AutomaticSize.Y
        content.BackgroundTransparency = 1
        content.LayoutOrder = #details:GetChildren()
        content.Visible = false
        content.Parent = details
        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 12)
        layout.Parent = content
        header.Activated:Connect(function()
            Dropdown.toggle(header, content, title)
        end)
        return content
    end

    local function findingDetails(finding)
        clear(details)
        local confidence = string.lower(tostring(finding.confidence or "unknown"))
        local badge = text(details, string.upper(confidence) .. " CONFIDENCE / POTENTIAL ISSUE", colors[confidence] or colors.text)
        badge.Font = Enum.Font.GothamBold
        badge.TextXAlignment = Enum.TextXAlignment.Center
        textBlock(badge)
        badge.UIPadding.PaddingTop = UDim.new(0, 14)
        badge.UIPadding.PaddingBottom = UDim.new(0, 14)
        badge.UIPadding.PaddingLeft = UDim.new(0, 16)
        badge.UIPadding.PaddingRight = UDim.new(0, 16)

        local explanation = detailDropdown("EXPLANATION")
        textBlock(text(explanation, finding.explanation))

        local flow = detailDropdown("REPORTED FLOW")
        ConnectionGraph.create(flow, finding, colors)

        local evidence = detailDropdown("EVIDENCE")
        section(evidence, "AFFECTED SCRIPTS", table.concat(finding.scripts or {}, "\n"))
        section(evidence, "SUGGESTED FIX", finding.recommendation)
        section(evidence, "VALIDATION TEST - NOT YET EXECUTED", finding.validation_test)
        local evidenceHeading = text(evidence, "SOURCE EVIDENCE", colors.accent)
        evidenceHeading.Font = Enum.Font.GothamBold
        for _, source in ipairs(finding.evidence or {}) do
            text(evidence, source.path, colors.muted)
            local excerpt = text(evidence, source.excerpt)
            excerpt.RichText = false
            excerpt.Text = tostring(source.excerpt or "Not provided.")
            excerpt.Font = Enum.Font.Code
            textBlock(excerpt)
        end
    end
    local function choice(parent, title, color, callback)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 0)
        button.AutomaticSize = Enum.AutomaticSize.Y
        button.BackgroundColor3 = color
        button.BorderSizePixel = 0
        button.Text = title
        button.TextColor3 = colors.text
        button.TextSize = 16
        button.Font = Enum.Font.GothamMedium
        button.TextWrapped = true
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.LayoutOrder = #parent:GetChildren()
        button.Parent = parent
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 14)
        padding.PaddingBottom = UDim.new(0, 14)
        padding.PaddingLeft = UDim.new(0, 12)
        padding.PaddingRight = UDim.new(0, 12)
        padding.Parent = button
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = button
        button.Activated:Connect(function()
            callback()
        end)
        return button
    end

    local results = {}

    function results.show(report)
        clear(list)
        clear(details)
        selectedButton = nil

        local groups = { high = {}, medium = {}, low = {}, unknown = {} }
        for _, finding in ipairs(report.findings) do
            local confidence = string.lower(tostring(finding.confidence or "unknown"))
            table.insert(groups[confidence] or groups.unknown, finding)
        end

        local function category(name, key)
            local findings = groups[key]
            local caption = name .. " Issues (" .. #findings .. ")"
            local content
            local header
            header = choice(list, "+   " .. caption, colors.card, function()
                Dropdown.toggle(header, content, caption)
            end)
            header.Font = Enum.Font.GothamBold
            header.UIPadding.PaddingLeft = UDim.new(0, 22)
            local stripe = Instance.new("Frame")
            stripe.Name = "ConfidenceStripe"
            stripe.AnchorPoint = Vector2.new(0, 0.5)
            stripe.Position = UDim2.new(0, -14, 0.5, 0)
            stripe.Size = UDim2.fromOffset(4, 24)
            stripe.BackgroundColor3 = colors[key] or colors.outline
            header.TextColor3 = stripe.BackgroundColor3
            stripe.BorderSizePixel = 0
            stripe.Parent = header
            local stripeCorner = Instance.new("UICorner")
            stripeCorner.CornerRadius = UDim.new(0, 2)
            stripeCorner.Parent = stripe

            content = Instance.new("Frame")
            content.Size = UDim2.new(1, 0, 0, 0)
            content.AutomaticSize = Enum.AutomaticSize.Y
            content.BackgroundTransparency = 1
            content.LayoutOrder = #list:GetChildren()
            content.Visible = false
            content.Parent = list
            local layout = Instance.new("UIListLayout")
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.Padding = UDim.new(0, 10)
            layout.Parent = content

            for _, finding in ipairs(findings) do
                local button
                button = choice(content, tostring(finding.title), colors.card, function()
                    if selectedButton == button then
                        selectButton(nil)
                        showResultsPrompt()
                    else
                        selectButton(button)
                        findingDetails(finding)
                    end
                end)
            end
            if #findings == 0 then
                text(content, "No issues reported, good job!")
                reactionImage(content, reactionImages.empty)
            else
                reactionImage(content, reactionImages[key])
            end
        end

        category("High", "high")
        category("Medium", "medium")
        category("Low", "low")
        -- Keep findings visible if a report has no recognized confidence value.
        if #groups.unknown > 0 then
            category("Unrated", "unknown")
        end
        if #report.findings == 0 then
            showResultsPrompt("No issues reported.")
        else
            showResultsPrompt()
        end
        panel.Enabled = true
    end
    function results.open()
        panel.Enabled = true
    end

    return results
end

return ResultsUI
