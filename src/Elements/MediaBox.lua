local import = ...
local Base = import("Elements/Base")
local Util = import("Core/Util")

-- A compact image card used by migrated MacLib hubs.
local MediaBox = Base.Class("MediaBox")

function MediaBox.new(container, def)
    local self = setmetatable({}, MediaBox)
    Base.Init(self, container, def)
    self.NoSave = true
    return self
end

function MediaBox:Matches(query)
    local def = self.Def
    return (tostring(def.Title or "") .. " " .. tostring(def.Description or "")):lower():find(query, 1, true) ~= nil
end

function MediaBox:Render(parent, maid)
    local def = self.Def
    local frame = maid:Give(Util.New("Frame", {
        Name = "MediaBox",
        Size = UDim2.new(1, 0, 0, def.Height or 76),
        Theme = { BackgroundColor3 = "Elevated", BackgroundTransparency = "ElevatedTransparency" },
        Visible = self.Visible,
        Parent = parent,
    }))
    Util.Corner(8, frame)
    Util.Stroke(frame)

    local image = Util.New("ImageLabel", {
        Size = UDim2.fromOffset(54, 54),
        Position = UDim2.fromOffset(10, 11),
        Image = Util.IconId(def.Image or def.Icon or def.FallbackIcon or "image") or "",
        ScaleType = Enum.ScaleType.Crop,
        Theme = { BackgroundColor3 = "ElevatedHover" },
        Parent = frame,
    })
    Util.Corner(7, image)

    Util.Label({
        Text = def.Title or "Media",
        TextSize = 14,
        Weight = Enum.FontWeight.SemiBold,
        Position = UDim2.fromOffset(76, 12),
        Size = UDim2.new(1, -88, 0, 20),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = frame,
    })
    Util.Label({
        Text = def.Description or def.Content or "",
        TextSize = 11,
        Color = "TextMuted",
        Position = UDim2.fromOffset(76, 33),
        Size = UDim2.new(1, -88, 0, 32),
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = frame,
    })
    return frame
end

return MediaBox
