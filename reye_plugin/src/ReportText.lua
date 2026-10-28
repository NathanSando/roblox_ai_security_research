local ReportText = {}

local function escape(value)
    return (value:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
        :gsub('"', "&quot;"):gsub("'", "&apos;"))
end

-- Escape report content before adding our own RichText tags.
function ReportText.highlight(value)
    local input = tostring(value or "Not provided.")
    local parts = {}
    local position = 1
    local plainStart = 1
    while position <= #input do
        local quote = input:sub(position, position)
        local previous = input:sub(position - 1, position - 1)
        local isQuote = quote == "`" or (quote == "'" and not previous:match("[%w_]"))
        if isQuote then
            local closing = input:find(quote, position + 1, true)
            -- Apostrophes within words are not closing quotation marks.
            while closing and quote == "'" and input:sub(closing + 1, closing + 1):match("[%w_]") do
                closing = input:find(quote, closing + 1, true)
            end
            if closing and closing > position + 1 and not input:sub(position, closing):find("\n", 1, true) then
                table.insert(parts, escape(input:sub(plainStart, position)))
                table.insert(parts, '<font color="#BDCCEF">' .. escape(input:sub(position + 1, closing - 1)) .. '</font>')
                table.insert(parts, escape(quote))
                position = closing + 1
                plainStart = position
            else
                position = position + 1
            end
        else
            position = position + 1
        end
    end
    table.insert(parts, escape(input:sub(plainStart)))
    return table.concat(parts)
end

ReportText.escape = escape

return ReportText