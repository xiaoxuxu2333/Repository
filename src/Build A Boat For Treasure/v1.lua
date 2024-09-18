local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer

local goldBlock = localPlayer:WaitForChild("Data"):WaitForChild("GoldBlock")
local gold = localPlayer.Data:WaitForChild("Gold")

local claimRiverResultsGoldEvent = workspace:WaitForChild("ClaimRiverResultsGold")
local stagePositions = {}
local chestTrigger, chestTriggerOriginCFrame

for _, stage in workspace:WaitForChild("BoatStages"):WaitForChild("NormalStages"):GetChildren() do
	local index = tonumber(stage.Name:match("%d+"))
	if index then
		stagePositions[index] = stage.DarknessPart.CFrame
	end
	if stage.Name == "TheEnd" then
		chestTrigger = stage.GoldenChest.Trigger
		chestTriggerOriginCFrame = chestTrigger.CFrame
	end
end

local stagesData = {}
for _, data in localPlayer.OtherData:GetChildren() do
	if data.Name:match("Stage%d+") then
		stagesData[tonumber(data.Name:match("%d+"))] = data
	end
end

local UILib = getgenv().UILibCache or loadstring(game:HttpGet("https://gitee.com/xiaoxuxu233/mirror/raw/master/wizard.lua"))
getgenv().UILibCache = UILib

local UI = UILib()
local window = UI:NewWindow("Unnamed")
local main = window:NewSection("主要功能")

main:CreateToggle("自动刷金条&块", function(enabled)
	goldFarming = enabled
	if not goldFarming then return end

	local status = {}

	local text = Drawing.new("Text")
	text.Outline = true
	text.OutlineColor = Color3.new(0, 0, 0)
	text.Color = Color3.new(1, 1, 1)
	text.Center = false
	text.Position = Vector2.new(50, 50)
	text.Text = ""
	text.Visible = true

	local oldGold = gold.Value
	local startTime = time()
	local root = localPlayer.Character.HumanoidRootPart
	local unlockChest, characterAdded
	local connections = {}
	local lockPosition = stagePositions[1]
	local chestCloseTime, chestOpenTime = 0, 0
	
	for _, stage in stagesData do
		stage:SetAttribute("TriggerStart", 0)
		stage:SetAttribute("TriggerDuration", 0)
		table.insert(connections, stage.Changed:Connect(function(str)
			if str ~= "" then
				stage:SetAttribute("TriggerDuration", time() - stage:GetAttribute("TriggerStart"))
			else
				stage:SetAttribute("TriggerDuration", 0)
			end
		end))
	end

	table.insert(connections, RunService.Heartbeat:Connect(function()
		if unlockChest and root.Parent then
			-- chestTrigger.CFrame = root.CFrame
			firetouchinterest(chestTrigger, root, 0)
		else
			-- chestTrigger.CFrame = chestTriggerOriginCFrame
		end
		
		root.CFrame = lockPosition
		root.Velocity = Vector3.zero
		
		for i = 1, #stagesData do
			local triggerDuration = stagesData[i]:GetAttribute("TriggerDuration")
			status[i] = triggerDuration > 0 and string.format("用时 %.2f 秒", triggerDuration) or ""
		end
		
		local info = ""
		for stat, value in status do
			info = info .. string.format("%s: %s\n", stat, value)
		end
		text.Text = info
	end))

	table.insert(connections, localPlayer.CharacterAdded:Connect(function(newChar)
	    startTime = time()
		oldGold = gold.Value
		
		root = newChar:WaitForChild("HumanoidRootPart")
	end))
	
	table.insert(connections, localPlayer.CharacterRemoving:Connect(function()
		chestCloseTime = time()
		status["宝箱用时"] = string.format("%.2f秒", chestCloseTime - chestOpenTime)
		unlockChest = nil
		claimRiverResultsGoldEvent:FireServer()
		
		local tempStartTime = startTime
		gold.Changed:Wait()
		local tempOldGold = oldGold
		
		local earned = gold.Value - tempOldGold
		local spentTime = time() - tempStartTime
		local earnedPreMinute = math.ceil(earned / spentTime * 60)
		local earnedPreHour = earnedPreMinute * 60
		local earnedPreDay = earnedPreHour * 24
		
		status["总用时"] = string.format("%.2f秒", spentTime)
		status["每分钟金条"] = string.format("%.0f", earnedPreMinute)
		status["每小时金条"] = string.format("%.0f", earnedPreHour)
		status["每天金条"] = string.format("%.0f", earnedPreDay)
		status["收入"] = earned
	end))

	table.insert(connections, localPlayer.PlayerGui.ChildAdded:Connect(function(newGui)
		if newGui.Name == "RiverResultsGui" then
			newGui:WaitForChild("LocalScript").Enabled = false
		end
	end))

	table.insert(connections, game.Lighting.Changed:Connect(function()
		if game.Lighting.FogEnd < 100000 then
			chestOpenTime = time()
		end
	end))

	while goldFarming do
		-- 13.5秒宝箱时间
		for i = 1, 9 do
			if not goldFarming then break end
			if i == 3 then
			    task.delay(0.3, function()
				    unlockChest = true
				end)
			end
			
			lockPosition = stagePositions[i]
			stagesData[i]:SetAttribute("TriggerStart", time())
			task.wait(i ~= 1 and 2 or 6.75)
		end
		
		while unlockChest and goldFarming do
			task.wait()
		end
	end

	for _, connection in connections do
		connection:Disconnect()
	end
	text:Destroy()
	chestTrigger.CFrame = chestTriggerOriginCFrame
end)

main:CreateToggle("自动刷金块", function(enabled)
	goldBlockFarming = enabled
	if not goldBlockFarming then return end

	local status = {}

	local text = Drawing.new("Text")
	text.Outline = true
	text.OutlineColor = Color3.new(0, 0, 0)
	text.Color = Color3.new(1, 1, 1)
	text.Center = false
	text.Position = Vector2.new(50, 50)
	text.Text = ""
	text.Visible = true
	
	local startTime = time()
	local oldGoldBlock = goldBlock.Value
	local root = localPlayer.Character.HumanoidRootPart
	local characterAdded
	local connections = {}
	local lockPosition = stagePositions[1]
	local chestCloseTime, chestOpenTime = 0, 0

	table.insert(connections, localPlayer.CharacterAdded:Connect(function(newChar)
	    startTime = time()
		oldGoldBlock = goldBlock.Value
		
		root = newChar:WaitForChild("HumanoidRootPart")
	end))
	
	table.insert(connections, localPlayer.CharacterRemoving:Connect(function()
		chestCloseTime = time()
		status["宝箱用时"] = string.format("%.2f秒", chestCloseTime - chestOpenTime)
		
		local tempStartTime = startTime
		goldBlock.Changed:Wait()
		local tempOldGold = oldGoldBlock
		
		local earned = goldBlock.Value - tempOldGold
		local spentTime = time() - tempStartTime
		local earnedPreMinute = math.ceil(earned / spentTime * 60)
		local earnedPreHour = earnedPreMinute * 60
		local earnedPreDay = earnedPreHour * 24
		
		status["总用时"] = string.format("%.2f秒", spentTime)
		status["每分钟金块"] = string.format("%.0f", earnedPreMinute)
		status["每小时金块"] = string.format("%.0f", earnedPreHour)
		status["每天金块"] = string.format("%.0f", earnedPreDay)
	end))

	table.insert(connections, localPlayer.PlayerGui.ChildAdded:Connect(function(newGui)
		if newGui.Name == "RiverResultsGui" then
			newGui:WaitForChild("LocalScript").Enabled = false
		end
	end))
	
	table.insert(connections, game.Lighting.Changed:Connect(function()
		if game.Lighting.FogEnd < 100000 then
			chestOpenTime = time()
		end
	end))
	
	root.CFrame = lockPosition
	task.wait(2)

	table.insert(connections, RunService.Heartbeat:Connect(function()
		if root.Parent then
			-- chestTrigger.CFrame = root.CFrame
			firetouchinterest(chestTrigger, root, 0)
		end
		
		root.CFrame = lockPosition
		root.Velocity = Vector3.zero
		
		local info = ""
		for stat, value in status do
			info = info .. string.format("%s: %s\n", stat, value)
		end
		text.Text = info
	end))
	
	while goldBlockFarming do
		task.wait()
	end
	
	for _, connection in connections do
		connection:Disconnect()
	end
	text:Destroy()
	chestTrigger.CFrame = chestTriggerOriginCFrame
end)