local import = ...
local Base = import("Elements/Base")
local Util = import("Core/Util")
local HttpService = game:GetService("HttpService")

-- Community card designed for Discord invites.
-- def: Title, Description, Icon, Invite, Online, Members, CopyText, RefreshCallback(box)
local DiscordBox = Base.Class("DiscordBox")

local function display(value, fallback)
    if value == nil or value == "" then return fallback end
    return tostring(value)
end

local function inviteCode(invite)
    invite = tostring(invite or "")
    return invite:match("discord%.gg/([^/%?%#]+)")
        or invite:match("discord%.com/invite/([^/%?%#]+)")
        or invite:match("discordapp%.com/invite/([^/%?%#]+)")
end

local function requestFunction()
    local env = (type(getgenv) == "function" and getgenv()) or _G
    local synTable = rawget(env, "syn") or rawget(_G, "syn")
    local httpTable = rawget(env, "http") or rawget(_G, "http")
    local fluxusTable = rawget(env, "fluxus") or rawget(_G, "fluxus")
    return rawget(env, "request")
        or rawget(env, "http_request")
        or (type(synTable) == "table" and synTable.request)
        or (type(httpTable) == "table" and httpTable.request)
        or (type(fluxusTable) == "table" and fluxusTable.request)
end

local function readBody(url)
    local request = requestFunction()
    if type(request) == "function" then
        local response = request({
            Url = url,
            Method = "GET",
            Headers = {
                ["Accept"] = "application/json",
                ["User-Agent"] = "Mozilla/5.0 OasisUI DiscordBox",
            },
        })
        if type(response) == "table" then
            local status = tonumber(response.StatusCode or response.Status or response.status_code) or 200
            if status >= 200 and status < 300 then
                return response.Body or response.body
            end
        end
    end
    return game:HttpGet(url, true)
end

local function fetchInviteStats(invite)
    local code = inviteCode(invite)
    if not code then return nil, "invalid invite" end
    local endpoints = {
        "https://discord.com/api/v10/invites/" .. code .. "?with_counts=true&with_expiration=true",
        "https://discord.com/api/v9/invites/" .. code .. "?with_counts=true",
        "https://discordapp.com/api/v9/invites/" .. code .. "?with_counts=true",
    }
    local lastError
    for _, url in ipairs(endpoints) do
        local ok, body = pcall(readBody, url)
        if ok and type(body) == "string" and body ~= "" then
            local decoded, data = pcall(HttpService.JSONDecode, HttpService, body)
            if decoded and type(data) == "table" then
                local online = data.approximate_presence_count
                local members = data.approximate_member_count
                if online ~= nil or members ~= nil then
                    return online, members
                end
            end
        else
            lastError = body
        end
    end
    return nil, lastError or "Discord did not return member counts"
end

function DiscordBox.new(container, def)
    local self = setmetatable({}, DiscordBox)
    Base.Init(self, container, def)
    self.Title = def.Title or "Discord Community"
    self.Description = def.Description or "Updates, support and announcements"
    self.Invite = def.Invite or def.Url or def.URL or ""
    self.Online = def.Online
    self.Members = def.Members
    self.NoSave = true
    return self
end

function DiscordBox:SetInvite(invite)
    self.Invite = tostring(invite or "")
    self.StateChanged:Fire("Invite")
    return self
end

function DiscordBox:SetStats(online, members)
    self.Online = online
    self.Members = members
    self.StateChanged:Fire("Stats")
    return self
end

function DiscordBox:Refresh()
    local callback = self.Def.RefreshCallback or self.Def.OnRefresh
    task.spawn(function()
        local ok, first, second
        if type(callback) == "function" then
            ok, first, second = pcall(callback, self)
        else
            ok, first, second = pcall(fetchInviteStats, self.Invite)
        end
        if not ok then
            warn("[OasisUI] DiscordBox refresh error: " .. tostring(first))
            return
        end
        if type(first) == "table" then
            self:SetStats(first.Online or first.online, first.Members or first.members)
        elseif first ~= nil or (second ~= nil and tonumber(second) ~= nil) then
            self:SetStats(first, second)
        end
    end)
    return self
end

function DiscordBox:Copy()
    local callback = self.Def.CopyCallback or self.Def.OnCopy
    if type(callback) == "function" then
        Util.Safe(callback, self.Invite, self)
        return true
    end
    if type(setclipboard) == "function" and self.Invite ~= "" then
        return pcall(setclipboard, self.Invite)
    end
    return false
end

function DiscordBox:Matches(query)
    local text = table.concat({ self.Title, self.Description, self.Invite }, " "):lower()
    return text:find(query, 1, true) ~= nil
end

local function statCard(parent, order, iconName, labelText)
    local card = Util.New("Frame", {
        Size = UDim2.new(0.5, -3, 0, 27),
        LayoutOrder = order,
        Theme = {
            BackgroundColor3 = "Surface",
            BackgroundTransparency = function(t) return math.min(t.ElevatedTransparency + 0.08, 0.88) end,
        },
        Parent = parent,
    })
    Util.Corner(5, card)
    Util.Stroke(card, "Stroke", function(t) return math.min(t.StrokeTransparency + 0.12, 0.92) end)
    Util.Icon(iconName, {
        Size = UDim2.fromOffset(11, 11),
        Position = UDim2.new(0, 8, 0.5, -5),
        Color = order == 1 and "Success" or "TextMuted",
        Parent = card,
    })
    return Util.Label({
        Text = labelText,
        TextSize = 10,
        Color = "TextDim",
        Size = UDim2.new(1, -25, 1, 0),
        Position = UDim2.fromOffset(23, 0),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = card,
    })
end

function DiscordBox:Render(parent, maid)
    local box = maid:Give(Util.New("Frame", {
        Name = "DiscordBox",
        Size = UDim2.new(1, 0, 0, 122),
        Visible = self.Visible,
        Theme = {
            BackgroundColor3 = "Elevated",
            BackgroundTransparency = function(t) return math.min(t.ElevatedTransparency + 0.04, 0.82) end,
        },
        Parent = parent,
    }))
    Util.Corner(7, box)
    Util.Stroke(box)
    local accent = Util.New("Frame", {
        Size = UDim2.new(0, 3, 1, -14), Position = UDim2.fromOffset(0, 7),
        Theme = { BackgroundColor3 = "Accent" }, Parent = box,
    })
    Util.Corner(UDim.new(1, 0), accent)
    Util.New("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 0.55) }),
        Parent = accent,
    })

    local iconHolder = Util.New("Frame", {
        Size = UDim2.fromOffset(42, 42),
        Position = UDim2.fromOffset(11, 10),
        Theme = { BackgroundColor3 = "Surface", BackgroundTransparency = "ElevatedTransparency" },
        Parent = box,
    })
    Util.Corner(7, iconHolder)
    local icon = Util.Icon(self.Def.Icon or "message-circle", {
        Size = UDim2.fromOffset(32, 32),
        Position = UDim2.fromOffset(5, 5),
        Color = "Text",
        Parent = iconHolder,
    })

    local title = Util.Label({
        Text = self.Title,
        TextSize = 13,
        Weight = Enum.FontWeight.SemiBold,
        Size = UDim2.new(1, -98, 0, 17),
        Position = UDim2.fromOffset(61, 10),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = box,
    })
    local description = Util.Label({
        Text = self.Description,
        TextSize = 10,
        Color = "TextMuted",
        Size = UDim2.new(1, -98, 0, 15),
        Position = UDim2.fromOffset(61, 29),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = box,
    })

    local refresh
    if self.Invite ~= "" or self.Def.RefreshCallback or self.Def.OnRefresh then
        refresh = Util.New("TextButton", {
            Size = UDim2.fromOffset(28, 28),
            Position = UDim2.new(1, -39, 0, 14),
            Theme = { BackgroundColor3 = "Surface", BackgroundTransparency = "ElevatedTransparency" },
            Parent = box,
        })
        Util.Corner(6, refresh)
        Util.Icon("refresh-cw", { Size = UDim2.fromOffset(13, 13), Position = UDim2.fromOffset(8, 8), Color = "TextDim", Parent = refresh })
        Util.Feedback(refresh)
        maid:Give(refresh.MouseButton1Click:Connect(function() self:Refresh() end))
    end

    local stats = Util.New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(11, 59),
        Size = UDim2.new(1, -22, 0, 27),
        Parent = box,
    })
    Util.List(stats, 6, Enum.FillDirection.Horizontal)
    local online = statCard(stats, 1, "circle", "")
    local members = statCard(stats, 2, "users", "")

    local copy = Util.New("TextButton", {
        Size = UDim2.new(1, -22, 0, 26),
        Position = UDim2.fromOffset(11, 91),
        Theme = { BackgroundColor3 = "Surface", BackgroundTransparency = "ElevatedTransparency" },
        Parent = box,
    })
    Util.Corner(5, copy)
    Util.Stroke(copy, "Stroke", function(t) return math.min(t.StrokeTransparency + 0.12, 0.92) end)
    Util.Icon("copy", { Size = UDim2.fromOffset(12, 12), Position = UDim2.fromOffset(10, 7), Color = "Accent", Parent = copy })
    local copyLabel = Util.Label({
        Text = self.Def.CopyText or self.Def.ButtonText or "Copy Discord invite",
        TextSize = 10,
        Weight = Enum.FontWeight.SemiBold,
        Color = "TextDim",
        TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.new(1, -34, 1, 0),
        Position = UDim2.fromOffset(22, 0),
        Parent = copy,
    })
    Util.Feedback(copy)
    maid:Give(copy.MouseButton1Click:Connect(function()
        local copied = self:Copy()
        copyLabel.Text = copied and (self.Def.CopiedText or "Invite copied") or (self.Def.UnsupportedText or "Clipboard unavailable")
        task.delay(1.4, function()
            if copyLabel.Parent then copyLabel.Text = self.Def.CopyText or self.Def.ButtonText or "Copy Discord invite" end
        end)
    end))

    local function paint()
        box.Visible = self.Visible
        title.Text = self.Title
        description.Text = self.Description
        online.Text = (self.Def.OnlineLabel or "Online") .. "  " .. display(self.Online, "—")
        members.Text = (self.Def.MembersLabel or "Members") .. "  " .. display(self.Members, "—")
        copy.Active = self.Invite ~= "" or type(self.Def.CopyCallback or self.Def.OnCopy) == "function"
        copyLabel.TextTransparency = copy.Active and 0 or 0.5
        icon.ImageTransparency = self.Locked and 0.5 or 0
    end
    paint()
    maid:Give(self.StateChanged:Connect(paint))
    if self.Invite ~= "" or self.Def.RefreshCallback or self.Def.OnRefresh then
        local alive = true
        maid:Give(function() alive = false end)
        task.spawn(function()
            self:Refresh()
            local interval = math.max(tonumber(self.Def.AutoRefresh) or 60, 15)
            while alive do
                task.wait(interval)
                if alive then self:Refresh() end
            end
        end)
    end
    return box
end

return DiscordBox
