local module = {}

function module.Create(opts)
	local cg = game:GetService("CoreGui")
	local s = Instance.new("ScreenGui")
	s.Name = opts.GuiName
	s.IgnoreGuiInset = true
	s.ResetOnSpawn = false
	s.Parent = cg

	local b = Instance.new("TextButton")
	b.Name = opts.ButtonName
	b.Size = opts.Size
	b.Position = opts.Position
	b.AnchorPoint = Vector2.new(0.5, 0.5)
	b.BackgroundColor3 = opts.BackgroundColor3
	b.BorderSizePixel = 0
	b.AutoButtonColor = true
	b.Font = Enum.Font.GothamBold
	b.Text = opts.Text
	b.TextSize = 16
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Parent = s

	local glow = Instance.new("UIGradient")
	glow.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 150))
	}
	glow.Rotation = 0
	glow.Parent = b

	task.spawn(function()
		while b.Parent do
			for i = 0, 1, 0.02 do
				glow.Offset = Vector2.new(i, 0)
				task.wait(0.03)
			end
		end
	end)

	if typeof(opts.Callback) == "function" then
		b.MouseButton1Click:Connect(opts.Callback)
	end

	return b
end

return module
