local AnalysisClient = {}

local HttpService = game:GetService("HttpService")

-- Convert scripts into a JSON here.
function AnalysisClient.toJSON(scripts)
    return HttpService:JSONEncode({scripts = scripts})
end

-- Removes scans from backend using the ID.
local function removeScan(scanId)
    local response = HttpService:RequestAsync({
        Url = "http://127.0.0.1:5000/scan/" .. scanId,
        Method = "DELETE"
    })

    if not response.Success then
        error("Could not remove scan: " .. response.StatusCode)
    end
end

-- Send the JSON into the backend for findings from AI.
function AnalysisClient.getFindings(json)

    -- Make a request to get the report.
    local response = HttpService:RequestAsync({
        Url = "http://127.0.0.1:5000/scan",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = json
    })

    if not response.Success then
        error("Could not start scan: " .. response.StatusCode)
    end

    local data = HttpService:JSONDecode(response.Body)
    local scanId = data.scan_id

    if type(scanId) ~= "string" or scanId == "" then
        error("Backend did not return a scan ID.")
    end

    -- Keep track of the response creation duration.
    local startedAt = os.clock()

    -- This does polling for the response to avoid connection time out.
    while true do

        -- If it is taking too long then error.
        if os.clock() - startedAt >= 600 then
            error("Stopped waiting after 10 minutes. The backend may still be reviewing.")
        end

        task.wait(2)

        -- Send in the scanId to try and get an update.
        local response = HttpService:RequestAsync({
            Url = "http://127.0.0.1:5000/scan/" .. scanId,
            Method = "GET"
        })

        -- Check if the scan went through.
        if not response.Success then
            error("Could not check scan: " .. response.StatusCode)
        end

        -- If the scan went through then decode the response.
        local result = HttpService:JSONDecode(response.Body)

        -- Check the status of the results.
        if result.status == "completed" or result.status == "failed" then
            local removed, cleanupError = pcall(removeScan, scanId)

            if not removed then
                warn(cleanupError)
            end

            if result.status == "completed" then
                return result.report
            else
                error(result.error)
            end

        end

    end

end

return AnalysisClient