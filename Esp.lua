-- Feel free to use, made by Hiasei

--[[
Usage:
espInstance = ESP.new({Box = true, Name = true, Health = true})
espInstance:WrapObject(char)
]]
local RunService = game:GetService("RunService")
local Player = game:GetService("Players").LocalPlayer
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local IsWindowFocused = true

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
	Square.Color = Color3.fromRGB(0,255,0)
	Square.Thickness = 2
	Square.Filled = false
	Square.Transparency = 1

	self.Square = Square

	self.Update = RunService.RenderStepped:Connect(function()

		if not object or not object.Parent then
			Square.Visible = false
			self.Update:Disconnect()
			return
		end

		local cf = object.CFrame
		local pos = cf.Position

		local up = cf.UpVector
		local right = cf.RightVector

		local top,topVis = Camera:WorldToViewportPoint(pos + up*2)
		local bottom,bottomVis = Camera:WorldToViewportPoint(pos - up*2)
		local left,leftVis = Camera:WorldToViewportPoint(pos - right*2)
		local rightPos,rightVis = Camera:WorldToViewportPoint(pos + right*2)

		if not (topVis and bottomVis and leftVis and rightVis) then
			Square.Visible = false
			return
		end

		if not IsWindowFocused then
			Square.Visible = false
			return
		end

		if top.Z < 0 or bottom.Z < 0 or left.Z < 0 or rightPos.Z < 0 then
			Square.Visible = false
			return
		end

		local width = math.max(math.abs(rightPos.X-left.X),5)
		local height = math.max(math.abs(bottom.Y-top.Y),width/2)

		local size = Vector2.new(width,height)

		local position = Vector2.new(
			(left.X+rightPos.X)/2 - size.X/2,
			math.min(top.Y,bottom.Y)
		)

		Square.Size = size
		Square.Position = position
		Square.Visible = true

	end)

	function self:Destroy()
		if self.Update then
			self.Update:Disconnect()
		end
		if Square then
			Square.Visible = false
		end
	end

	return self

end

ESP.Elements.Name = function(object)

	local self = {}

	local Text = Drawing.new("Text")
	Text.Size = 20
	Text.Center = true
	Text.Outline = true
	Text.Color = Color3.fromRGB(255,255,255)

	Text.Text = object.Parent.Name

	self.Text = Text

	self.Update = RunService.RenderStepped:Connect(function()

		if not object or not object.Parent then
			Text.Visible = false
			self.Update:Disconnect()
			return
		end

		local pos = object.Position + Vector3.new(0,3,0)

		local screenPos,visible = Camera:WorldToViewportPoint(pos)

		if visible and screenPos.Z > 0 and IsWindowFocused then
			Text.Position = Vector2.new(screenPos.X,screenPos.Y)
			Text.Visible = true
		else
			Text.Visible = false
		end

	end)

	function self:Destroy()
		if self.Update then
			self.Update:Disconnect()
		end
		if Text then
			Text.Visible = false
		end
	end

	return self

end

ESP.Elements.HealthBar = function(object,boxObject,getHealth,getMaxHealth)

	local self = {}

	local Main = Drawing.new("Line")
	Main.Thickness = 4
	Main.Transparency = 1
	Main.Visible = false

	local Outline = Drawing.new("Line")
	Outline.Color = Color3.fromRGB(0,0,0)
	Outline.Thickness = 6
	Outline.Transparency = 1
	Outline.Visible = false

	self.Main = Main
	self.Outline = Outline

	self.Update = RunService.RenderStepped:Connect(function()

		if not object or not object.Parent then
			Main.Visible = false
			Outline.Visible = false
			return
		end

		if not IsWindowFocused then
			Main.Visible = false
			Outline.Visible = false
			return
		end

		if not boxObject or not boxObject.Square then
			Main.Visible = false
			Outline.Visible = false
			return
		end

		local square = boxObject.Square

		if not square.Visible then
			Main.Visible = false
			Outline.Visible = false
			return
		end

		local hp = getHealth and getHealth() or 0
		local max = getMaxHealth and getMaxHealth() or 100

		if max <= 0 then max = 100 end
		if hp < 0 then hp = 0 end

		local ratio = math.clamp(hp / max, 0, 1)

		local boxPos = square.Position
		local boxSize = square.Size

		if boxSize.Y <= 0 then
			Main.Visible = false
			Outline.Visible = false
			return
		end

		local barX = boxPos.X - 6
		local topY = boxPos.Y
		local bottomY = boxPos.Y + boxSize.Y

		local healthHeight = boxSize.Y * ratio

		Outline.From = Vector2.new(barX, bottomY)
		Outline.To = Vector2.new(barX, topY)

		Main.From = Vector2.new(barX, bottomY)
		Main.To = Vector2.new(barX, bottomY - healthHeight)

		local r = math.floor(255 * (1 - ratio))
		local g = math.floor(255 * ratio)

		Main.Color = Color3.fromRGB(r, g, 0)

		Main.Visible = true
		Outline.Visible = true

	end)

	function self:Destroy()
		if self.Update then
			self.Update:Disconnect()
		end
		if Main then
			Main:Destroy()
		end
		if Outline then
			Outline:Destroy()
		end
	end

	return self

end

function ESP.new(config)

	local self=setmetatable({}, {__index=ESP})

	self.Config=config or {}
	self.Objects={}

	return self

end

function ESP:WrapObject(object)

	local Humanoid = object:FindFirstChildOfClass("Humanoid")
	local rootPart = Humanoid and object:FindFirstChild("HumanoidRootPart") or object

	if not rootPart then return end

	local entity={}
	entity.Object=rootPart

	if self.Config.Box then
		entity.Box=self.Elements.Box(rootPart)
	end

	if self.Config.Name then
		entity.Name=self.Elements.Name(rootPart)
	end

	if self.Config.Health then

		local getHealth
		local getMaxHealth

		if self.Config.GetHealth then
			getHealth=function()
				return self.Config.GetHealth(object)
			end
		elseif Humanoid then
			getHealth=function()
				return Humanoid.Health
			end
		end

		if self.Config.GetMaxHealth then
			getMaxHealth=function()
				return self.Config.GetMaxHealth(object)
			end
		elseif Humanoid then
			getMaxHealth=function()
				return Humanoid.MaxHealth
			end
		end

		entity.Health=self.Elements.HealthBar(rootPart,entity.Box,getHealth,getMaxHealth)

	end

	function entity:Destroy()
		if entity.Box then entity.Box:Destroy() end
		if entity.Name then entity.Name:Destroy() end
		if entity.Health then entity.Health:Destroy() end
	end

	table.insert(self.Objects,entity)

	return entity

end

return ESP
