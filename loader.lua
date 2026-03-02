local Title = "Note"
local Description = "Sorry, this script is in Alpha and we are still making scripts for the games, wait until we finish it."

local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local g = Instance.new("ScreenGui", game.CoreGui)

local m = Instance.new("Frame", g)
m.Size = UDim2.new(0, 0, 0, 0)
m.Position = UDim2.new(0.5, 0, 0.5, 0)
m.AnchorPoint = Vector2.new(0.5,0.5)
m.BackgroundColor3 = Color3.fromRGB(0,0,0)
m.BorderSizePixel = 0

local stroke = Instance.new("UIStroke", m)
stroke.Color = Color3.fromRGB(255,0,0)
stroke.Thickness = 2
stroke.Transparency = 1

local x = Instance.new("TextButton", m)
x.Size = UDim2.new(0,30,0,30)
x.Position = UDim2.new(1,-34,0,4)
x.BackgroundTransparency = 1
x.Text = "X"
x.Font = Enum.Font.GothamBold
x.TextSize = 18
x.TextColor3 = Color3.fromRGB(255,255,255)
x.TextTransparency = 1

local t = Instance.new("TextLabel", m)
t.Size = UDim2.new(1,-20,0,50)
t.Position = UDim2.new(0,10,0,40)
t.BackgroundTransparency = 1
t.Text = Title
t.Font = Enum.Font.GothamBold
t.TextSize = 22
t.TextColor3 = Color3.fromRGB(255,255,255)
t.TextTransparency = 1
t.TextXAlignment = Enum.TextXAlignment.Center

local d = Instance.new("TextLabel", m)
d.Size = UDim2.new(1,-30,0,40)
d.Position = UDim2.new(0,15,0,85)
d.BackgroundTransparency = 1
d.Text = Description
d.Font = Enum.Font.Gotham
d.TextSize = 15
d.TextColor3 = Color3.fromRGB(200,200,200)
d.TextTransparency = 1
d.TextWrapped = true
d.TextXAlignment = Enum.TextXAlignment.Center

TweenService:Create(m, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
	Size = UDim2.new(0,360,0,160)
}):Play()

task.wait(0.1)

TweenService:Create(stroke, TweenInfo.new(0.3), {Transparency = 0}):Play()
TweenService:Create(t, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
TweenService:Create(d, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
TweenService:Create(x, TweenInfo.new(0.3), {TextTransparency = 0}):Play()

x.MouseEnter:Connect(function()
	TweenService:Create(x, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(255,80,80)}):Play()
end)

x.MouseLeave:Connect(function()
	TweenService:Create(x, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(255,255,255)}):Play()
end)

x.MouseButton1Click:Connect(function()
	local tween = TweenService:Create(m, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(0,0,0,0)
	})
	tween:Play()
	tween.Completed:Wait()
	g:Destroy()
end)

local dragging, dragInput, start, pos

m.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		start = input.Position
		pos = m.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

m.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		dragInput = input
	end
end)

UIS.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - start
		m.Position = UDim2.new(pos.X.Scale, pos.X.Offset + delta.X, pos.Y.Scale, pos.Y.Offset + delta.Y)
	end
end)
