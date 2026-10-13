AnalysisClient = {}

local HttpService = game:GetService("HttpService")

-- Convert scripts into a JSON here.
function AnalysisClient.toJSON(scripts)
    return HttpService:JSONEncode({scripts = scripts})
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

    -- If it failed then error.
    if not response.Success then
        error("Scan request failed: " .. response.StatusCode)
    end

    -- Return the response decoded back into LUA.
    return HttpService:JSONDecode(response.Body)

end

return AnalysisClient