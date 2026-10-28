local Dropdown = {}
local TweenService = game:GetService("TweenService")
local activeTweens = setmetatable({}, { __mode = "k" })

function Dropdown.toggle(header, content, title)
    local expanded = not content:GetAttribute("Expanded")
    content:SetAttribute("Expanded", expanded)
    header.Text = (expanded and "-   " or "+   ") .. title

    local previous = activeTweens[content]
    activeTweens[content] = nil
    if previous then
        previous:Cancel()
    end

    local height = content.Visible and content.AbsoluteSize.Y or 0
    content.AutomaticSize = Enum.AutomaticSize.None
    content.Size = UDim2.new(1, 0, 0, height)
    content.ClipsDescendants = true
    content.Visible = true

    local layout = content:FindFirstChildOfClass("UIListLayout")
    local targetHeight = expanded and layout.AbsoluteContentSize.Y or 0
    local tween = TweenService:Create(content,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = UDim2.new(1, 0, 0, targetHeight) }
    )
    activeTweens[content] = tween
    tween.Completed:Once(function()
        if activeTweens[content] ~= tween or not content.Parent then
            return
        end
        activeTweens[content] = nil
        content.Visible = expanded
        -- Let expanded sections respond to wrapped text and window resizing.
        if expanded then
            content.Size = UDim2.new(1, 0, 0, 0)
            content.AutomaticSize = Enum.AutomaticSize.Y
            content.ClipsDescendants = false
        end
    end)
    tween:Play()
end

return Dropdown