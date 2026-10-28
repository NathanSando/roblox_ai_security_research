local Dropdown = require(script.Parent.Dropdown)
local UI = {}
local RunService = game:GetService("RunService")

local ScriptScanner = require(script.Parent.ScriptScanner)
local AnalysisClient = require(script.Parent.AnalysisClient)
local ResultsUI = require(script.Parent.ResultsUI)

function UI.create(plugin)
    local results = ResultsUI.create(plugin)
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
    background.BackgroundColor3 = Color3.fromRGB(26, 27, 29)
    background.BorderSizePixel = 0
    background.CanvasSize = UDim2.fromOffset(0, 0)
    background.AutomaticCanvasSize = Enum.AutomaticSize.Y
    background.ScrollBarThickness = 6
    background.ScrollBarImageColor3 = Color3.fromRGB(212, 233, 232)
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

    local function label(text, order, parent)
        local item = Instance.new("TextLabel")
        item.Size = UDim2.new(1, 0, 0, 0)
        item.AutomaticSize = Enum.AutomaticSize.Y
        item.BackgroundTransparency = 1
        item.Font = Enum.Font.Gotham
        item.Text = text
        item.TextSize = 16
        item.TextColor3 = Color3.fromRGB(212, 233, 232)
        item.TextWrapped = true
        item.TextXAlignment = Enum.TextXAlignment.Left
        item.TextYAlignment = Enum.TextYAlignment.Top
        item.LayoutOrder = order
        item.Parent = parent or background
        return item
    end

    -- Each header toggles its own content without stopping an active review.
    local function dropdown(name, order)
        local header = Instance.new("TextButton")
        header.Size = UDim2.new(1, 0, 0, 36)
        header.BackgroundTransparency = 0
        header.BackgroundColor3 = Color3.fromRGB(48, 51, 55)
        header.BorderSizePixel = 0
        header.Text = "+   " .. name
        header.TextColor3 = Color3.fromRGB(151, 172, 223)
        header.TextSize = 16
        header.Font = Enum.Font.GothamBold
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.LayoutOrder = order
        header.Parent = background
        local headerCorner = Instance.new("UICorner")
        headerCorner.CornerRadius = UDim.new(0, 6)
        headerCorner.Parent = header
        local headerPadding = Instance.new("UIPadding")
        headerPadding.PaddingLeft = UDim.new(0, 12)
        headerPadding.PaddingRight = UDim.new(0, 12)
        headerPadding.Parent = header

        local content = Instance.new("Frame")
        content.Size = UDim2.new(1, 0, 0, 0)
        content.AutomaticSize = Enum.AutomaticSize.Y
        content.BackgroundTransparency = 1
        content.LayoutOrder = order + 1
        content.Visible = false
        content.Parent = background

        local contentLayout = Instance.new("UIListLayout")
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.Padding = UDim.new(0, 14)
        contentLayout.Parent = content

        header.Activated:Connect(function()
            Dropdown.toggle(header, content, name)
        end)
        return content
    end
    local title = label("REYE", 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.TextColor3 = Color3.fromRGB(151, 172, 223)
    local descriptionContent = dropdown("Description", 2)
    label("Reye uses AI to review your game's scripts, trace how they connect, and highlight potential security issues with evidence and suggested fixes.", 1, descriptionContent)
    local reviewContent = dropdown("Script Review", 4)
    label("Review your scripts for potential security issues and understand what to check next.", 4, reviewContent)

    local scan = Instance.new("TextButton")
    scan.Size = UDim2.new(1, 0, 0, 44)
    scan.BackgroundColor3 = Color3.fromRGB(36, 38, 41)
    scan.BorderSizePixel = 0
    scan.Text = "Review Scripts"
    scan.Font = Enum.Font.GothamBold
    scan.TextSize = 16
    scan.TextColor3 = Color3.fromRGB(95, 205, 130)
    scan.LayoutOrder = 5
    scan.Parent = reviewContent

    local scanStripe = Instance.new("Frame")
    scanStripe.Name = "StatusStripe"
    scanStripe.AnchorPoint = Vector2.new(0, 0.5)
    scanStripe.Position = UDim2.new(0, 8, 0.5, 0)
    scanStripe.Size = UDim2.fromOffset(4, 24)
    scanStripe.BackgroundColor3 = Color3.fromRGB(95, 205, 130)
    scanStripe.BorderSizePixel = 0
    scanStripe.Parent = scan
    local stripeCorner = Instance.new("UICorner")
    stripeCorner.CornerRadius = UDim.new(0, 2)
    stripeCorner.Parent = scanStripe

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = scan

    local status = label("Scanning has not been commenced yet.", 7, reviewContent)

    local elapsed = label("", 8, reviewContent)
    elapsed.Visible = false
    local timerConnection
    local isScanning = false
    local activeScan

    local cancel = Instance.new("TextButton")
    cancel.Size = UDim2.new(1, 0, 0, 36)
    cancel.BackgroundColor3 = Color3.fromRGB(36, 38, 41)
    cancel.BorderSizePixel = 0
    cancel.Text = "Cancel Scan"
    cancel.TextColor3 = Color3.fromRGB(255, 110, 110)
    cancel.TextSize = 16
    cancel.Font = Enum.Font.GothamBold
    cancel.LayoutOrder = 6
    cancel.Visible = false
    cancel.Parent = reviewContent
    local cancelCorner = Instance.new("UICorner")
    cancelCorner.CornerRadius = UDim.new(0, 8)
    cancelCorner.Parent = cancel
    cancel.Activated:Connect(function()
        if activeScan and not activeScan.cancelRequested then
            AnalysisClient.cancelScan(activeScan)
            cancel.Text = "Cancelling..."
        end
    end)

    local reopen = Instance.new("TextButton")
    reopen.Size = UDim2.new(1, 0, 0, 36)
    reopen.BackgroundColor3 = Color3.fromRGB(57, 60, 64)
    reopen.BorderSizePixel = 0
    reopen.Text = "Open Last Results"
    reopen.TextColor3 = Color3.fromRGB(212, 233, 232)
    reopen.Font = Enum.Font.GothamMedium
    reopen.TextSize = 16
    reopen.LayoutOrder = 9
    reopen.Visible = false
    reopen.Parent = reviewContent
    local reopenCorner = Instance.new("UICorner")
    reopenCorner.CornerRadius = UDim.new(0, 8)
    reopenCorner.Parent = reopen
    reopen.Activated:Connect(results.open)

    -- Stop updating the label if Studio unloads this plugin.
    plugin.Unloading:Connect(function()
        if timerConnection then
            timerConnection:Disconnect()
            timerConnection = nil
        end
    end)

    scan.Activated:Connect(function()

        if isScanning == true then
            return
        end

        isScanning = true
        activeScan = {}
        cancel.Visible = true
        cancel.Text = "Cancel Scan"
        scan.Text = "Reviewing scripts"
        scanStripe.BackgroundColor3 = Color3.fromRGB(255, 110, 110)
        scan.TextColor3 = scanStripe.BackgroundColor3
        scan.AutoButtonColor = false
        status.Visible = false
        local startedAt = os.clock()
        elapsed.Visible = true
        elapsed.Text = "Elapsed: 0 seconds"
        elapsed.TextColor3 = Color3.fromRGB(212, 233, 232)

        -- Update independently while the HTTP request waits for the AI.
        timerConnection = RunService.Heartbeat:Connect(function()
            local seconds = os.clock() - startedAt
            elapsed.Text = string.format("Elapsed: %d seconds", math.floor(seconds))

            -- Cycle zero to three dots while gently pulsing the red stripe.
            local dots = string.rep(".", math.floor(seconds * 2) % 4)
            scan.Text = (activeScan.cancelRequested and "Stopping scan" or "Reviewing scripts") .. dots
            cancel.Text = activeScan.cancelRequested and "Cancelling..." or "Cancel Scan"
            if activeScan.cancelError then
                status.Visible = true
                status.Text = activeScan.cancelError .. ". Review is still active; you can retry cancellation."
            end
            local blend = (1 - math.cos(seconds * math.pi * 2 / 3)) / 2
            scanStripe.BackgroundColor3 = Color3.fromRGB(220, 80, 80):Lerp(
                Color3.fromRGB(255, 145, 145), blend
            )
            scan.TextColor3 = scanStripe.BackgroundColor3
        end)

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

            -- Send the JSON to the AI and get the report.
            local report, outcome = AnalysisClient.getFindings(json, activeScan)
            if outcome == "cancelled" then
                status.Text = "Review cancelled."
                return
            end
            results.show(report)
            reopen.Visible = true
            status.Text = "Review complete. See Reye Results."

        end)

        -- Keep the final elapsed time, but stop the timer and pulse.
        if timerConnection then
            timerConnection:Disconnect()
            timerConnection = nil
        end

        elapsed.Text = string.format("Elapsed: %.1f seconds", os.clock() - startedAt)
        elapsed.TextColor3 = Color3.fromRGB(212, 233, 232)

        -- Allow another scan after either success or failure.
        status.Visible = true
        isScanning = false
        activeScan = nil
        cancel.Visible = false
        scan.Text = "Review Scripts"
        scanStripe.BackgroundColor3 = Color3.fromRGB(95, 205, 130)
        scan.TextColor3 = scanStripe.BackgroundColor3
        scan.AutoButtonColor = true

        if not success then
            status.Text = "Review failed: " .. tostring(errorMessage)
            warn(errorMessage)
        end


    end)

    local monitoringContent = dropdown("Player Monitoring", 9)
    label("Optional module that is coming later. Nothing is installed in your game.", 10, monitoringContent)

    return panel

end

return UI
