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
            Square.Visible = false
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
            self.Square.Visible = false
            self.Square = nil
        end
    end

    return self
end

ESP.Elements.Name = function(object)
    local self = {}
    
    local NameText = Drawing.new("Text")
    NameText.Text = object.Parent.Name or "Player"
    NameText.Size = 20
    NameText.Color = Color3.fromRGB(255, 255, 255)
    NameText.Center = true
    NameText.Outline = true
    NameText.Visible = true
    
    self.Text = NameText
    
    self.Update = RunService.RenderStepped:Connect(function()
        if not object.Parent or not object then
            self.Update:Disconnect()
            NameText.Visible = false
            return
        end
    
        local pos = object.Position + Vector3.new(0, 3, 0)
        local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    
        if onScreen and IsWindowFocused and game then
            NameText.Position = Vector2.new(screenPos.X, screenPos.Y)
            NameText.Visible = true
        else
            NameText.Visible = false
        end
    end)
    
    self.Destroy = function()
        if self.Update then
            self.Update:Disconnect()
            self.Update = nil
        end
        if self.Text then
            self.Text.Visible = false
            self.Text = nil
        end
    end
    
    return self
end

ESP.Elements.HealthBar = function(object, boxObject, getHealth, getMaxHealth)
    local self = {}

    local MainBar = Drawing.new("Line")
    MainBar.Thickness = 4
    MainBar.Visible = false

    local OutlineBar = Drawing.new("Line")
    OutlineBar.Color = Color3.fromRGB(0,0,0)
    OutlineBar.Thickness = 6
    OutlineBar.Visible = false

    self.Main = MainBar
    self.Outline = OutlineBar

    self.Update = RunService.RenderStepped:Connect(function()

        if not object.Parent then
            MainBar.Visible = false
            OutlineBar.Visible = false
            return
        end

        if not IsWindowFocused then
            MainBar.Visible = false
            OutlineBar.Visible = false
            return
        end

        if not boxObject or not boxObject.Square then
            MainBar.Visible = false
            OutlineBar.Visible = false
            return
        end

        local health = getHealth and getHealth() or 0
        local maxHealth = getMaxHealth and getMaxHealth() or 1

        local ratio = math.clamp(health / maxHealth, 0, 1)

        local boxPos = boxObject.Square.Position
        local boxSize = boxObject.Square.Size

        local barX = boxPos.X - 6
        local topY = boxPos.Y
        local bottomY = boxPos.Y + boxSize.Y

        local healthHeight = boxSize.Y * ratio

        MainBar.From = Vector2.new(barX, bottomY)
        MainBar.To = Vector2.new(barX, bottomY - healthHeight)

        OutlineBar.From = Vector2.new(barX, bottomY)
        OutlineBar.To = Vector2.new(barX, topY)

        MainBar.Color = Color3.fromRGB(
            255 * (1 - ratio),
            255 * ratio,
            0
        )

        MainBar.Visible = true
        OutlineBar.Visible = true
    end)

    self.Destroy = function()
        if self.Update then
            self.Update:Disconnect()
            self.Update = nil
        end

        if self.Main then
            self.Main.Visible = false
            self.Main = nil
        end

        if self.Outline then
            self.Outline.Visible = false
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
