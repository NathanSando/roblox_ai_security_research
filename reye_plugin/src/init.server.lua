local UI = require(script.UI)

local toolbar = plugin:CreateToolbar("Reye")
local button = toolbar:CreateButton("OpenReye", "Open Reye", "", "Reye")
local panel = UI.create(plugin)

-- Clicking the toolbar button opens or closes the panel.
button.Click:Connect(function()
    panel.Enabled = not panel.Enabled
end)

-- Keep the toolbar button in sync when the panel is closed with its X.
local function updateButton()
    button:SetActive(panel.Enabled)
end
panel:GetPropertyChangedSignal("Enabled"):Connect(updateButton)
updateButton()
