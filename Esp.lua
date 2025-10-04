local RunService = game:GetService("RunService")

local Player = game:GetService("Players").LocalPlayer
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

IsWindowFocused = true
UserInputService.WindowFocused:Connect(function()
	IsWindowFocused = true
end)
UserInputService.WindowFocusReleased:Connect(function()
	IsWindowFocused = false
end)

local ESP = {Elements = {}}

ESP.Elements.Box = function(object)
    local self = {}

    local Square = Drawing.new("Square")
    Square.Size = Vector2.new(100, 100)
    Square.Position = Vector2.new(300, 300)
    Square.Color = Color3.fromRGB(0, 255, 0)
    Square.Thickness = 2
    Square.Transparency = 1
    Square.Filled = false

    self.Square = Square

    self.Update = RunService.RenderStepped:Connect(function()
        if not object.Parent then
            self.Update:Disconnect()
            Square:Remove()
            return
        end

        local partCFrame = object.CFrame
        local partPos = partCFrame.Position
        local up = partCFrame.UpVector
        local right = partCFrame.RightVector

        local top, topOnScreen = Camera:WorldToViewportPoint(partPos + (up * 2))
        local bottom, bottomOnScreen = Camera:WorldToViewportPoint(partPos - (up * 2))

        local left, leftOnScreen = Camera:WorldToViewportPoint(partPos - (right * 2))
        local rightPos, rightOnScreen = Camera:WorldToViewportPoint(partPos + (right * 2))

        if topOnScreen and bottomOnScreen and leftOnScreen and rightOnScreen and IsWindowFocused and game then
            Square.Visible = true

            local width = math.max(math.abs(rightPos.X - left.X), 5)
            local height = math.max(math.abs(bottom.Y - top.Y), width / 2)

            local size = Vector2.new(width, height)
            local position = Vector2.new(
                (left.X + rightPos.X) / 2 - size.X / 2,
                math.min(top.Y, bottom.Y)
            )

            Square.Size = size
            Square.Position = position
        else
            Square.Visible = false
        end
    end)

    self.Destroy = function()
        if self.Update then
            self.Update:Disconnect()
            self.Update = nil
        end

        if self.Square then
            self.Square:Remove()
            self.Square = nil
        end
    end

    return self
end

ESP.Elements.Name = function(object)
    local self = {}

    local Player = game:GetService("Players").LocalPlayer
    local PlayerGui = Player:WaitForChild("PlayerGui")
    local Gui = PlayerGui:FindFirstChild("ESPGui") or Instance.new("ScreenGui")
    Gui.Name = "ESPGui"
    Gui.ResetOnSpawn = false
    Gui.Parent = PlayerGui

    local NameLabel = Instance.new("TextLabel")
    NameLabel.Text = object.Parent.Name or "Player"
    NameLabel.Size = UDim2.new(0, 100, 0, 20)
    NameLabel.BackgroundTransparency = 1
    NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    NameLabel.TextStrokeTransparency = 0
    NameLabel.TextScaled = true
    NameLabel.TextXAlignment = Enum.TextXAlignment.Center
    NameLabel.TextYAlignment = Enum.TextYAlignment.Center
    NameLabel.Visible = true
    NameLabel.Parent = Gui

    self.Label = NameLabel

    self.Update = RunService.RenderStepped:Connect(function()
        if not object.Parent then
            self.Update:Disconnect()
            NameLabel:Destroy()
            return
        end

        local cam = workspace.CurrentCamera
        local pos = object.Position
        local screenPos, onScreen = cam:WorldToViewportPoint(pos)

        if onScreen then
            NameLabel.Position = UDim2.new(0, screenPos.X - NameLabel.AbsoluteSize.X / 2, 0, screenPos.Y - NameLabel.AbsoluteSize.Y / 2)
            NameLabel.Visible = true
        else
            NameLabel.Visible = false
        end
    end)

    self.Destroy = function()
        if self.Update then
            self.Update:Disconnect()
            self.Update = nil
        end
        if self.Label then
            self.Label:Destroy()
            self.Label = nil
        end
    end

    return self
end


ESP.Elements.HealthBar = function(object,boxObject)
    local self = {}

    local MainBar = Drawing.new("Line")
    MainBar.Color = Color3.fromRGB(0, 255, 0)
    MainBar.Thickness = 4
    MainBar.Visible = true

    local OutlineBar = Drawing.new("Line")
    OutlineBar.Color = Color3.fromRGB(0, 0, 0)
    OutlineBar.Thickness = 5
    OutlineBar.Visible = true

    self.Main = MainBar
    self.Outline = OutlineBar

    self.Ratio = 1

    self.Update = RunService.RenderStepped:Connect(function()
        if not object.Parent then
            return
        end
        if not IsWindowFocused and not game then
            MainBar.Visible = false
            OutlineBar.Visible = false

            return
        end
        if not boxObject.Square then
            if self.Update then self.Update:Disconnect() end
            MainBar:Remove()
            OutlineBar:Remove()
            return
        end

        local boxPos = boxObject.Square.Position
        local boxSize = boxObject.Square.Size

        local barX = boxPos.X - 6
        local barYTop = boxPos.Y
        local barYBottom = boxPos.Y + boxSize.Y

        local ratio = math.clamp(self.Ratio, 0, 1)

        local from = Vector2.new(barX, barYBottom)
        local to = Vector2.new(barX, barYBottom - boxSize.Y * ratio)

        OutlineBar.From = Vector2.new(barX - 1, barYBottom)
        OutlineBar.To = Vector2.new(barX + 1, barYTop)
        OutlineBar.Visible = true

        MainBar.From = from
        MainBar.To = to
        MainBar.Color = Color3.fromRGB(255 * (1 - ratio), 255 * ratio, 0)
        MainBar.Visible = true
    end)

    function self:SetRatio(value)
        self.Ratio = value
    end

    self.Destroy = function()
        if self.Update then
            self.Update:Disconnect()
            self.Update = nil
        end
        if self.Main then
            self.Main:Remove()
            self.Main = nil
        end
        if self.Outline then
            self.Outline:Remove()
            self.Outline = nil
        end
    end

    return self
end

function ESP.new(config)
    local self = setmetatable(ESP,{})
    self.Config = config or {}
    self.Objects = {}
    return self
end

function ESP:WrapObject(object)
    local Humanoid = object:FindFirstChildOfClass("Humanoid")
    local rootPart = Humanoid and object:FindFirstChild("HumanoidRootPart") or object
    if not rootPart then return end

    local entity = {}
    entity.Object = rootPart

    if self.Config.Box then
        entity.Box = self.Elements.Box(rootPart)
    end

    if self.Config.Name then
        entity.Name = self.Elements.Name(rootPart)
    end

    if self.Config.Health and Humanoid then
        entity.Health = self.Elements.HealthBar(rootPart, entity.Box)
    end

    entity.Destroy = function()
        if entity.Box then entity.Box:Destroy() end
        if entity.Name then entity.Name:Destroy() end
        if entity.Health then entity.Health:Destroy() end
    end

    table.insert(self.Objects, entity)
    return entity
end

return ESP
--[[

local esp = ESP.new({
    Box = false,
    Name = true,
    Health = false
})


local Objects = {}

for _, player in pairs(game:GetService("Players"):GetPlayers()) do
    local character = player.Character
    if character then
        local entity = esp:WrapObject(character)

        table.insert(Objects, entity)
    end
end]]
