local UI = {}

local ScriptScanner = require(script.Parent.ScriptScanner)
local AnalysisClient = require(script.Parent.AnalysisClient)

function UI.create(plugin)
    local settings = DockWidgetPluginGuiInfo.new(
        Enum.InitialDockState.Right,
        false, false,
        360, 460,
        280, 300
    )
    local panel = plugin:CreateDockWidgetPluginGuiAsync("ReyePanel", settings)
    panel.Title = "Reye"

    local background = Instance.new("ScrollingFrame")
    background.Size = UDim2.fromScale(1, 1)
    background.BackgroundColor3 = Color3.fromRGB(24, 18, 36)
    background.BorderSizePixel = 0
    background.CanvasSize = UDim2.fromOffset(0, 0)
    background.AutomaticCanvasSize = Enum.AutomaticSize.Y
    background.ScrollBarThickness = 4
    background.Parent = panel

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 24)
    padding.PaddingBottom = UDim.new(0, 24)
    padding.PaddingLeft = UDim.new(0, 20)
    padding.PaddingRight = UDim.new(0, 20)
    padding.Parent = background

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 14)
    layout.Parent = background

    local function label(text, size, color, order)
        local item = Instance.new("TextLabel")
        item.Size = UDim2.new(1, 0, 0, 0)
        item.AutomaticSize = Enum.AutomaticSize.Y
        item.BackgroundTransparency = 1
        item.Font = Enum.Font.Gotham
        item.Text = text
        item.TextSize = size
        item.TextColor3 = color
        item.TextWrapped = true
        item.TextXAlignment = Enum.TextXAlignment.Left
        item.TextYAlignment = Enum.TextYAlignment.Top
        item.LayoutOrder = order
        item.Parent = background
        return item
    end

    local title = label("REYE", 30, Color3.fromRGB(192, 155, 255), 1)
    title.Font = Enum.Font.GothamBold
    label("A closer look at your game.", 16, Color3.fromRGB(246, 240, 255), 2)
    label("SCRIPT REVIEW", 12, Color3.fromRGB(192, 155, 255), 3)
    label("Review your scripts for potential security issues and understand what to check next.", 14, Color3.fromRGB(190, 177, 208), 4)

    local scan = Instance.new("TextButton")
    scan.Size = UDim2.new(1, 0, 0, 44)
    scan.BackgroundColor3 = Color3.fromRGB(192, 155, 255)
    scan.BorderSizePixel = 0
    scan.Text = "Scan Scripts"
    scan.Font = Enum.Font.GothamBold
    scan.TextSize = 15
    scan.TextColor3 = Color3.fromRGB(24, 18, 36)
    scan.LayoutOrder = 5
    scan.Parent = background

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = scan

    local status = label("Scanning is not connected yet. No scripts have been read or changed.", 13, Color3.fromRGB(190, 177, 208), 6)

    local isScanning = false

    scan.Activated:Connect(function()

        if isScanning == true then
            return
        end

        isScanning = true
        scan.Text = "Scanning in process..."
        status.Text = "Collecting scripts..."

        -- Monitor the function that sends and retrieves.
        local success, errorMessage = pcall(function()
            local scripts = ScriptScanner.Scan()

            -- If no scripts are returned then return.
            if #scripts == 0 then
                status.Text = "No scripts found."
                return
            end

            -- Convert the script table to JSON.
            local json = AnalysisClient.toJSON(scripts)
            status.Text = "Reviewing scripts..."

            -- Send the JSON to the AI and get the report.
            local report = AnalysisClient.getFindings(json)
            status.Text = report.summary

            for _, finding in ipairs(report.findings) do
                print(finding.title, finding.severity)
                print(finding.explanation)
            end

        end)

        -- Allow another scan after either success or failure.
        isScanning = false
        scan.Text = "Scan Scripts"

        if not success then
            status.Text = "Review failed. Check output for details."
            warn(errorMessage)
        end


    end)

    label("PLAYER MONITORING", 12, Color3.fromRGB(192, 155, 255), 7)
    label("Optional module — coming later. Nothing is installed in your game.", 13, Color3.fromRGB(190, 177, 208), 8)

    return panel

end

return UI
