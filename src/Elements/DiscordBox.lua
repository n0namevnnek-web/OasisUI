local import = ...
local Base = import("Elements/Base")
local Util = import("Core/Util")

-- Community card designed for Discord invites.
-- def: Title, Description, Icon, Invite, Online, Members, CopyText, RefreshCallback(box)
local DiscordBox = Base.Class("DiscordBox")

local function display(value, fallback)
    if value == nil or value == "" then return fallback end
    return tostring(value)
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
    if type(callback) ~= "function" then return self end
    task.spawn(function()
        local ok, first, second = pcall(callback, self)
        if not ok then
            warn("[OasisUI] DiscordBox refresh error: " .. tostring(first))
            return
        end
        if type(first) == "table" then
            self:SetStats(first.Online or first.online, first.Members or first.members)
        elseif first ~= nil or second ~= nil then
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
        Size = UDim2.new(1, 0, 0, 108),
        Visible = self.Visible,
        Theme = {
            BackgroundColor3 = "Elevated",
            BackgroundTransparency = function(t) return math.min(t.ElevatedTransparency + 0.04, 0.82) end,
        },
        Parent = parent,
    }))
    Util.Corner(7, box)
    Util.Stroke(box)

    local iconHolder = Util.New("Frame", {
        Size = UDim2.fromOffset(38, 38),
        Position = UDim2.fromOffset(9, 9),
        Theme = { BackgroundColor3 = "Surface", BackgroundTransparency = "ElevatedTransparency" },
        Parent = box,
    })
    Util.Corner(7, iconHolder)
    local icon = Util.Icon(self.Def.Icon or "message-circle", {
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.fromOffset(5, 5),
        Color = "Text",
        Parent = iconHolder,
    })

    local title = Util.Label({
        Text = self.Title,
        TextSize = 12,
        Weight = Enum.FontWeight.SemiBold,
        Size = UDim2.new(1, -98, 0, 17),
        Position = UDim2.fromOffset(55, 9),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = box,
    })
    local description = Util.Label({
        Text = self.Description,
        TextSize = 10,
        Color = "TextMuted",
        Size = UDim2.new(1, -98, 0, 15),
        Position = UDim2.fromOffset(55, 27),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = box,
    })

    local refresh
    if self.Def.RefreshCallback or self.Def.OnRefresh then
        refresh = Util.New("TextButton", {
            Size = UDim2.fromOffset(28, 28),
            Position = UDim2.new(1, -37, 0, 12),
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
        Size = UDim2.new(1, -18, 0, 27),
        Position = UDim2.fromOffset(9, 51),
        Parent = box,
    })
    Util.List(stats, 6, Enum.FillDirection.Horizontal)
    local online = statCard(stats, 1, "circle", "")
    local members = statCard(stats, 2, "users", "")

    local copy = Util.New("TextButton", {
        Size = UDim2.new(1, -18, 0, 22),
        Position = UDim2.fromOffset(9, 81),
        Theme = { BackgroundColor3 = "Surface", BackgroundTransparency = "ElevatedTransparency" },
        Parent = box,
    })
    Util.Corner(5, copy)
    Util.Stroke(copy, "Stroke", function(t) return math.min(t.StrokeTransparency + 0.12, 0.92) end)
    Util.Icon("copy", { Size = UDim2.fromOffset(11, 11), Position = UDim2.fromOffset(9, 5), Color = "TextMuted", Parent = copy })
    local copyLabel = Util.Label({
        Text = self.Def.CopyText or "Copy Discord invite",
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
            if copyLabel.Parent then copyLabel.Text = self.Def.CopyText or "Copy Discord invite" end
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
    return box
end

return DiscordBox
