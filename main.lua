--[[ 

ZLOCK Anti Virus Version 1.3.6
Last updated: 2021-11-30
Created and written by zblox164

]]

local selectionService = game:GetService("Selection")
local testService = game:GetService("TestService")
local serverStorage = game:GetService("ServerStorage")
local insertService = game:GetService("InsertService")
local changeHistoryService = game:GetService("ChangeHistoryService")

local services = {
	workspace,
	game.Players,
	game.ReplicatedFirst,
	game.ReplicatedStorage,
	game.ServerStorage,
	game.ServerScriptService,
	game.StarterGui,
	game.StarterPack,
	game.StarterPlayer,
	game.SoundService,
	game.Chat,
	game.LocalizationService,
	game.TestService,
	game.Lighting,
	game.SoundService
}

local virusNameM = require(script.VirusList)
local tagM = require(script.TagList)
local serverM = require(script.ServerSideList)
local junkM = require(script.JunkList)

local virusNames = virusNameM.virusNames
local tags = tagM.tags
local servers = serverM.serverSides
local junk = junkM.deprecated

local toolbar = plugin:CreateToolbar("ZLOCK Quick bar")
local button = toolbar:CreateButton("Click to open", "ZLOCK", "rbxassetid://7184112961")
local scangamequickbar = toolbar:CreateButton("Click to scan game", "Game Scan", "rbxassetid://8130258586")
local settingsquickbar = toolbar:CreateButton("Click to open settings", "Settings", "rbxassetid://8145354364")

local UI = script.UI

local insert = table.insert
local find = table.find
local match = string.match
local len = string.len
local lower = string.lower
local upper = string.upper

-- settings
local loadToggle = true
local getToggle = true
local reqToggle = true
local autoToggle = true
local junkToggle = false

local clearOnExitToggle = false
local deletingToggle = true
local disableToggle = true

-- UI
local opened = false
local main = UI.Main
local topbar = main.topbar
local warning = UI.warning
local deletion = UI.deletion

local askSetting = UI.ask
local loadSetting = UI.load
local autoSetting = UI.auto
local reqSetting = UI.req
local getSetting = UI.get

local _settings = main.Settings
local clearExit = _settings.other:WaitForChild("clear")
local delete = _settings.other:WaitForChild("deleting")
local disable = _settings.other:WaitForChild("disable")
local auto = _settings.prot:WaitForChild("auto")
local get = _settings.prot:WaitForChild("get")
local load = _settings.prot:WaitForChild("load")
local req = _settings.prot:WaitForChild("req")
local dep = _settings.prot:WaitForChild("dep")

local versionText = {
	main.version,
	main.Settings.version,
	main.Help.version
}

local ve = tostring(script.Parent.Version.Value)
local openVal = false
local gameScan
local cancelScan = false

local function esc(x)
	return (x:gsub('%%', '%%%%')
		:gsub('^%^', '%%^')
		:gsub('%$$', '%%$')
		:gsub('%(', '%%(')
		:gsub('%)', '%%)')
		:gsub('%.', '%%.')
		:gsub('%[', '%%[')
		:gsub('%]', '%%]')
		:gsub('%*', '%%*')
		:gsub('%+', '%%+')
		:gsub('%-', '%%-')
		:gsub('%?', '%%?'))
end

local function getRisk(virusType)
	local risk = "?"

	if virusType == "Known Virus" then
		risk = 4
	elseif virusType == "Common Virus Name" then
		risk = 5
	elseif virusType == "require()" then
		risk = "?"
	elseif virusType == "Virus require" then
		risk = 5
	elseif virusType == "Unreadable script" then
		risk = "?"
	elseif virusType == "Virus invoke" then
		risk = 6
	elseif virusType == "Unwanted website webhook" then
		risk = 7
	elseif virusType == "Discord link" then
		risk = 6
	elseif virusType == "Keyword 'serverside'" then
		risk = 3
	elseif virusType == "Keyword 'virus'" then
		risk = 2
	elseif virusType == "Unwanted website link" then
		risk = 6
	elseif virusType == "loadstring()" then
		risk = 7
	elseif virusType == "getfenv()" then
		risk = 6
	elseif virusType == "PostAsync()" then
		risk = 7
	elseif virusType == "Server side exploit" then
		risk = 10
	elseif virusType == ".load()" or virusType == ":Run()"  or virusType == ".Execute()" or virusType == ":mbye()" then
		risk = 7
	end

	return risk
end

local function inspect(sc)
	local regularSource = sc.Source
	local source = lower(regularSource)
	local main, vir, serv, tag, jnk = script.Source, script.VirusList.Source, script.ServerSideList.Source, script.TagList.Source, script.JunkList.Source
	local _type
	local isVirus = false
	local currentRisk = 1

	for i, v in pairs(tags) do
		if len(source) > 1  then
			if regularSource ~= main and regularSource ~= tag and regularSource ~= vir and regularSource ~= serv and regularSource ~= jnk then
				local sub = lower(esc(i))
				
				if not loadToggle and i == "loadstring(" then
					continue
				elseif not getToggle and i == "getfenv(" then
					continue
				elseif not reqToggle and i == "require(" then
					continue
				end
				
				if match(source, sub) == lower(i) then
					_type = v
					isVirus = true
					
					currentRisk = getRisk(_type)
					
					if currentRisk == 10 then
						return true, _type, 10
					end
				end
			end
		end
	end
	
	if isVirus then
		return isVirus, _type, currentRisk
	end
	
	if junkToggle then
		source = sc.Source
	
		for index, tag in pairs(junk) do
			if len(source) > 1 then
				if regularSource ~= main and regularSource ~= tag and regularSource ~= vir and regularSource ~= serv and regularSource ~= jnk then
					local sub = esc(index)
					
					if match(source, sub) == index then
						_type = tag
						
						return true, _type, 1
					end
				end
			end
		end
		
		if match(lower(source), "while true do") == "while true do" then
			if match(lower(source), "wait") ~= "wait" then
				return true, "While loop doesn't yield", 1
			end
		end
	end

	return false, nil, nil
end

local function locate(obj) 
	local viruses
	local types
	local risk
	
	if obj:IsA("LuaSourceContainer") then
		if obj.Source ~= script.VirusList.Source and obj.Source ~= script.ServerSideList.Source then
			for i, v in pairs(virusNames) do
				if lower(obj.Name):match(lower(v)) or lower(obj.Name) == lower(v) then
					viruses = obj
					types = "Common Virus Name"
					
					return viruses, types, 5
				end
			end
			
			for i, v in pairs(servers) do
				if lower(obj.Name):match(lower(v)) or lower(obj.Name) == lower(v) then
					viruses = obj
					types = "Server side exploit"

					return viruses, types, 10
				end
			end
			
			local virus, _type, _risk = inspect(obj)

			if virus then
				viruses = obj
				types = _type
				risk = _risk
			end
		end
	elseif obj:IsA("ScreenGui") then
		for i, v in pairs(servers) do
			if lower(obj.Name):match(lower(v)) or lower(obj.Name) == lower(v) then
				viruses = obj
				types = "Server side exploit"
				
				return viruses, types, 10
			end
		end
	end
	
	return viruses, types, risk
end

local function update(s, t, v)
	UI.Main.topbar.amount.Text = s .. "/" .. t
	UI.Main.topbar.found.Text = "Threats Found: " .. v
end

local function scan(selection, a, s)
	local viruses = {}
	local types = {}
	local risks = {}
	local headNode = selection[1]:GetDescendants() or selection[1]
	main.cancel.Visible = true
	
	local scanned = 0
	local virusesFound = 0
	local total = 1
	
	if headNode[1] and not cancelScan then
		total = #headNode + 1
		
		for i, v in pairs(headNode) do
			if cancelScan then
				main.cancel.Visible = false
				break
			end
			
			local virus, _type, risk = locate(v)
			
			if virus then
				insert(viruses, virus)
				insert(types, _type)
				insert(risks, risk)
				virusesFound += 1
			end
			
			scanned = i
			update(scanned, total, virusesFound)
			
			if not a then
				if i%100 == 0 then
					wait()
				end
			elseif not a and s then
				if i%500 == 0 then
					wait()
				end
			else
				if i%50 == 0 then
					wait()
				end
			end
		end
		
		local virus, _type, risk = locate(selection[1])
		
		local isNotService = true

		for i, v in pairs(services) do
			if selection[1] and selection[1] == v then
				isNotService = false
				break
			end
		end
		
		if isNotService then
			if virus then
				insert(viruses, virus)
				insert(types, _type)
				insert(risks, risk)
				virusesFound += 1
			else
				if viruses[1] then
					insert(viruses, selection[1])
					insert(types, "May be 'Parent' of a virus")
					insert(risks, "?")
					virusesFound += 1
				end
			end
		end
		
		scanned += 1
		update(scanned, total, virusesFound)
	else
		headNode = selection[1]
		
		local virus, _type, risk = locate(headNode)

		if virus then
			insert(viruses, virus)
			insert(types, _type)
			insert(risks, risk)
			virusesFound += 1
		end
		
		scanned += 1
		update(scanned, total, virusesFound)
	end
	
	if #viruses >= 1 then
		return viruses, types, risks
	end
end

local function cleanDeletedViruses()
	for i, v in ipairs(main.viruses:GetChildren()) do
		if v:IsA("GuiObject") then
			if not v.obj.Value.Parent then
				v:Destroy()
				cleanDeletedViruses()
			end
		end
	end
end

local function cleanPathsForQuarantine(name, obj, path)
	for i, v in ipairs(main.viruses:GetChildren()) do
		if v:IsA("Frame") then
			if match(v.path.Text, name) == name then
				local instance = v.obj.Value
				if instance ~= obj then
					if instance:IsA("Script") or instance:IsA("LocalScript") then
						instance.Disabled = true
					end
					
					instance.Parent = serverStorage.Quarantined
					v.path.Text = instance:GetFullName()
					v.quarantine.Visible = false
					v.quarantined.Visible = true
				end
			end
		end
	end

	return true
end

local function quarantine(v, visualVirus)
	changeHistoryService:SetWaypoint("Quarantining a threat.")
	
	if not serverStorage:FindFirstChild("Quarantined") then
		local quarantine = Instance.new("Folder")
		quarantine.Name = "Quarantined"
		quarantine.Parent = serverStorage
		
		v.Parent = quarantine
	else
		v.Parent = serverStorage:FindFirstChild("Quarantined a threat.")
	end
	
	visualVirus.path.Text = v:GetFullName()
	visualVirus.quarantine.Visible = false
	visualVirus.quarantined.Visible = true
	
	cleanPathsForQuarantine(v.Name, v, visualVirus.path.Text)
	changeHistoryService:SetWaypoint("Quatantined a threat")
end

local function clearAllViruses()
	for i, v in ipairs(main.viruses:GetChildren()) do
		if v:IsA("GuiObject") then
			v:Destroy()
		end
	end
end

local function clean()
	for i, v in ipairs(main.viruses:GetChildren()) do
		if v:IsA("Frame") then
			local compare1 = v:FindFirstChild("obj").Value
			
			for  index, value in pairs(main.viruses:GetChildren()) do
				if value:IsA("Frame") then
					local compare2 = value:FindFirstChild("obj").Value
					
					if index ~= i then
						if compare1 == compare2 then
							value:Destroy()
							
							return clean()
						end
					end
				end	
			end
		end
	end
end

local function deleteAll()
	changeHistoryService:SetWaypoint("Deleting All")
	local deleted = {}
	
	local children = main.viruses:GetChildren()
	
	for i, v in pairs(children) do
		if v:IsA("Frame") then
			v.obj.Value.Parent = nil
			table.insert(deleted, v.obj.Value)
		end
	end
	
	spawn(function()
		wait(30)
		
		for i, v in ipairs(deleted) do
			if v.Parent == nil then
				v:Destroy()
			else
				break
			end
		end
	end)
	
	clearAllViruses()
	
	topbar.amount.Text = ""
	topbar.found.Text = "Threats Found: "
	
	changeHistoryService:SetWaypoint("Deleted All")
end

local function display(selection, a, s)
	cancelScan = false
	
	local viruses
	local types
	local risks
	local head

	if selection and selection ~= {} then
		viruses, types, risks = scan(selection, a)

		if viruses then
			for i = 1, #viruses, 1 do
				local virusType = types[i]
				local risk = risks[i]

				local visualVirus = script.template:Clone()
				visualVirus.name.txt.Text = viruses[i].Name
				visualVirus.risk.txt.Text = risk .. "/10"
				visualVirus.threat.txt.Text = virusType
				visualVirus.obj.Value = viruses[i]
				visualVirus.path.Text = viruses[i]:GetFullName()
				
				risk = getRisk(virusType)
				
				if viruses[i] == selection[1] then
					visualVirus.headNode.Value = true
				end

				if risk ~= "?" then
					visualVirus.Name = tostring(10 - risk)
				else
					visualVirus.Name = "Unknown"
				end

				visualVirus.quarantine.MouseButton1Click:Connect(function()
					quarantine(viruses[i], visualVirus)
					
					if viruses[i]:IsA("Script") or viruses[i]:IsA("LocalScript") then
						viruses[i].Disabled = true
					end
				end)
				
				visualVirus.clear.MouseButton1Click:Connect(function()
					visualVirus:Destroy()
				end)

				if not viruses[i]:IsA("LuaSourceContainer") then
					visualVirus.open:Destroy()
				else
					visualVirus.open.MouseButton1Click:Connect(function()
						plugin:OpenScript(visualVirus.obj.Value, 0)
					end)
				end

				visualVirus.delete.MouseButton1Click:Connect(function()
					viruses[i]:Destroy()
					visualVirus:Destroy()
					cleanDeletedViruses()
				end)

				visualVirus.Parent = UI.Main.viruses

				if i%100 == 0 then
					wait()
				end
			end
			
			main.cancel.Visible = false
			
			if s then
				testService:Message("Scanned: " .. s.Name .. ". Found: " .. #viruses)
			end
			
			if a then
				clean()
			end
			
			main.viruses.CanvasPosition = Vector2.new(0, 0)
			
			return true
		end
	else
		warn("Cannot perform scan. Please select an object to perform a selection scan.")
	end
	
	if not s then
		testService:Message("Scan finished. Found: 0 viruses.")
	else
		testService:Message("Scanned: " .. s.Name .. ". Found 0 viruses.")
	end
	
	main.viruses.CanvasPosition = Vector2.new(0, 0)
	main.cancel.Visible = false
	
	return false
end

local function showWarning()
	if not openVal then
		openVal = true
		local c  = 0

		for i, v in pairs(tags) do
			c += 1
		end

		main.v.Text = #virusNames
		main.ss.Text = #servers
		main.keywords.Text = c
		main.Visible = false
		warning.Visible = true
		UI.Parent = game.CoreGui
	end
end

workspace.ChildAdded:Connect(function(child)
	if autoToggle then
		cancelScan = false
		
		if display({child}, true) then
			showWarning()
			
			main.cancel.Visible = false
		end
	end
	
	cancelScan = false
end)

local function fullGameScan()
	clearAllViruses()

	gameScan = true
	cancelScan = false

	for i, v in pairs(services) do
		if cancelScan then
			break
		end

		if display({v}, false, v) then
			continue
		end
	end

	UI.Main.topbar.scanned.Text = "Scaned Services:"
	UI.Main.topbar.amount.Text = #services .. "/" .. #services
	UI.Main.topbar.found.Text = "Threats Found: " .. #main.viruses:GetChildren() - 2

	main.cancel.Visible = false
end

local function updateSettings()	
	local data = {
		["disableToggle"] = disableToggle,
		["autoToggle"] = autoToggle,
		["getToggle"] = getToggle,
		["loadToggle"] = loadToggle,
		["reqToggle"] = reqToggle,
		["junkToggle"] = junkToggle,
		["clearOnExitToggle"] = clearOnExitToggle,
		["deletingToggle"] = deletingToggle
	}
	
	plugin:SetSetting("ZLOCK Settings " .. game.GameId, data)
end

local function loadSettings()
	local data = plugin:GetSetting("ZLOCK Settings " .. game.GameId) or nil
	
	if data then	
		disableToggle = data.disableToggle
		autoToggle = data.autoToggle
		getToggle = data.getToggle
		loadToggle = data.loadToggle
		reqToggle = data.reqToggle
		junkToggle = data.junkToggle
		clearOnExitToggle = data.clearOnExitToggle
		deletingToggle = data.deletingToggle
	end
	
	disable.TextButton.TextColor3 = Color3.fromRGB(0.564706*255, 1*255, 0.364706*255)
	
	if disableToggle then
		disable.TextButton.Text = "✓"
		disable.TextButton.TextColor3 = Color3.new(0.564706, 1, 0.364706)
	else
		disable.TextButton.Text = "X"
		disable.TextButton.TextColor3 = Color3.new(1, 0.431373, 0.431373)
	end

	if autoToggle then
		auto.TextButton.Text = "✓"
		auto.TextButton.TextColor3 = Color3.new(0.564706, 1, 0.364706)
	else
		auto.TextButton.Text = "X"
		auto.TextButton.TextColor3 = Color3.new(1, 0.431373, 0.431373)
	end
	
	if getToggle then
		get.TextButton.Text = "✓"
		get.TextButton.TextColor3 = Color3.new(0.564706, 1, 0.364706)
	else
		get.TextButton.Text = "X"
		get.TextButton.TextColor3 = Color3.new(1, 0.431373, 0.431373)
	end

	if loadToggle then
		load.TextButton.Text = "✓"
		load.TextButton.TextColor3 = Color3.new(0.564706, 1, 0.364706)
	else
		load.TextButton.Text = "X"
		load.TextButton.TextColor3 = Color3.new(1, 0.431373, 0.431373)
	end
	
	if reqToggle then
		req.TextButton.Text = "✓"
		req.TextButton.TextColor3 = Color3.new(0.564706, 1, 0.364706)
	else
		req.TextButton.Text = "X"
		req.TextButton.TextColor3 = Color3.new(1, 0.431373, 0.431373)
	end

	if junkToggle then
		dep.TextButton.Text = "✓"
		dep.TextButton.TextColor3 = Color3.new(0.564706, 1, 0.364706)
	else
		dep.TextButton.Text = "X"
		dep.TextButton.TextColor3 = Color3.new(1, 0.431373, 0.431373)
	end
	
	if clearOnExitToggle then
		clearExit.TextButton.Text = "✓"
		clearExit.TextButton.TextColor3 = Color3.new(0.564706, 1, 0.364706)
	else
		clearExit.TextButton.Text = "X"
		clearExit.TextButton.TextColor3 = Color3.new(1, 0.431373, 0.431373)
	end

	if deletingToggle then
		delete.TextButton.Text = "✓"
		delete.TextButton.TextColor3 = Color3.new(0.564706, 1, 0.364706)
	else
		delete.TextButton.Text = "X"
		delete.TextButton.TextColor3 = Color3.new(1, 0.431373, 0.431373)
	end
end

main.cancel.MouseButton1Click:Connect(function()
	cancelScan = true
end)

button.Click:Connect(function()
	openVal = not openVal
	local c  = 0

	for i, v in pairs(tags) do
		c += 1
	end

	for i, v in pairs(junk) do
		c += 1
	end

	main.v.Text = #virusNames
	main.ss.Text = #servers
	main.keywords.Text = c

	if openVal then
		UI.Parent = game.CoreGui
	else
		UI.Parent = script
		updateSettings()
	end
end)

settingsquickbar.Click:Connect(function()
	_settings.Visible = true
	main.clearAll.Visible = false
	main.deleteAll.Visible = false
	
	openVal = true
	UI.Parent = game.CoreGui
end)

topbar.close.MouseButton1Click:Connect(function()
	UI.Parent = script
	openVal = false

	local c = 0

	for i, v in pairs(tags) do
		c += 1
	end

	for i, v in pairs(junk) do
		c += 1
	end

	main.v.Text = #virusNames
	main.ss.Text = #servers
	main.keywords.Text = c

	if clearOnExitToggle then
		clearAllViruses()
	end
end)

main.clearAll.MouseButton1Click:Connect(function()
	clearAllViruses()
	topbar.amount.Text = ""
	topbar.found.Text = "Threats Found: "
end)

main.deleteAll.MouseButton1Click:Connect(function()
	if (#main.viruses:GetChildren() - 2) >= 1 then
		if deletingToggle then
			deletion.Visible = true
			deletion.yes.MouseButton1Click:Connect(function()
				deleteAll()
				deletion.Visible = false
			end)
		else
			deleteAll()
		end
	end
end)

changeHistoryService.OnUndo:Connect(function(action)
	if action == "Quatantined a threat" then
		clearAllViruses()
	end
end)

warning.view.MouseButton1Click:Connect(function()
	if openVal then
		warning.Visible = false
		main.Visible = true
	else
		openVal = true
		local c  = 0

		for i, v in pairs(tags) do
			c += 1
		end

		main.v.Text = #virusNames
		main.ss.Text = #servers
		main.keywords.Text = c
		main.Visible = true
		warning.Visible = false
		UI.Parent = game.CoreGui
	end
end)

topbar.scan.MouseButton1Click:Connect(function()
	local selection = selectionService:Get()
	clearAllViruses()
	cancelScan = false
	display(selection, false)
	main.cancel.Visible = false
	UI.Main.topbar.scanned.Text = "Scaned:"
end)

UI.warning.close.MouseButton1Click:Connect(function()
	UI.warning.Visible = false
	openVal = false
	UI.Parent = script
	main.Visible = true
end)

clearExit.TextButton.MouseButton1Click:Connect(function()
	clearOnExitToggle = not clearOnExitToggle

	if clearOnExitToggle then
		clearExit.TextButton.Text = "✓"
		clearExit.TextButton.TextColor3 = Color3.new(0.564706, 1, 0.364706)
		updateSettings()
	else
		clearExit.TextButton.Text = "X"
		clearExit.TextButton.TextColor3 = Color3.new(1, 0.431373, 0.431373)
		updateSettings()
	end
end)

delete.TextButton.MouseButton1Click:Connect(function()
	deletingToggle = not deletingToggle
	
	if deletingToggle then
		delete.TextButton.Text = "✓"
		delete.TextButton.TextColor3 = Color3.new(0.564706, 1, 0.364706)
		updateSettings()
	else
		delete.TextButton.Text = "X"
		delete.TextButton.TextColor3 = Color3.new(1, 0.431373, 0.431373)
		updateSettings()
	end
end)

deletion.yes.MouseButton1Click:Connect(function()
	deletion.Visible = false
end)

disable.TextButton.MouseButton1Click:Connect(function()
	askSetting.yes.MouseButton1Click:Connect(function()
		disableToggle = false
		askSetting.Visible = false
		disable.TextButton.Text = "X"
		disable.TextButton.TextColor3 = Color3.new(1, 0.431373, 0.431373)
		updateSettings()
	end)

	if not disableToggle then
		disable.TextButton.Text = "✓"
		disable.TextButton.TextColor3 = Color3.new(0.564706, 1, 0.364706)
		disableToggle = true
		updateSettings()
	else
		askSetting.Visible = true
	end
end)

auto.TextButton.MouseButton1Click:Connect(function()
	autoSetting.yes.MouseButton1Click:Connect(function()
		autoToggle = false
		autoSetting.Visible = false
		auto.TextButton.Text = "X"
		auto.TextButton.TextColor3 = Color3.new(1, 0.431373, 0.431373)
		updateSettings()
	end)
	
	if not autoToggle then
		auto.TextButton.Text = "✓"
		auto.TextButton.TextColor3 = Color3.new(0.564706, 1, 0.364706)
		autoToggle = true
		updateSettings()
	else
		if disableToggle then
			autoSetting.Visible = true
		else
			auto.TextButton.Text = "X"
			auto.TextButton.TextColor3 = Color3.new(1, 0.431373, 0.431373)
			autoToggle = false
			updateSettings()
		end
	end
end)

get.TextButton.MouseButton1Click:Connect(function()
	getSetting.yes.MouseButton1Click:Connect(function()
		getToggle = false
		getSetting.Visible = false
		get.TextButton.Text = "X"
		get.TextButton.TextColor3 = Color3.new(1, 0.431373, 0.431373)
		updateSettings()
	end)

	if not getToggle then
		get.TextButton.Text = "✓"
		get.TextButton.TextColor3 = Color3.new(0.564706, 1, 0.364706)
		getToggle = true
		updateSettings()
	else
		if disableToggle then
			getSetting.Visible = true
		else
			get.TextButton.Text = "X"
			get.TextButton.TextColor3 = Color3.new(1, 0.431373, 0.431373)
			getToggle = false
			updateSettings()
		end
	end
end)

load.TextButton.MouseButton1Click:Connect(function()	
	loadSetting.yes.MouseButton1Click:Connect(function()
		loadToggle = false
		loadSetting.Visible = false
		load.TextButton.Text = "X"
		load.TextButton.TextColor3 = Color3.new(1, 0.431373, 0.431373)
		updateSettings()
	end)

	if not loadToggle then
		load.TextButton.Text = "✓"
		load.TextButton.TextColor3 = Color3.new(0.564706, 1, 0.364706)
		loadToggle = true
		updateSettings()
	else
		if disableToggle then
			loadSetting.Visible = true
		else
			load.TextButton.Text = "X"
			load.TextButton.TextColor3 = Color3.new(1, 0.431373, 0.431373)
			loadToggle = false
			updateSettings()
		end
	end
end)

req.TextButton.MouseButton1Click:Connect(function()
	reqSetting.yes.MouseButton1Click:Connect(function()
		reqToggle = false
		reqSetting.Visible = false
		req.TextButton.Text = "X"
		req.TextButton.TextColor3 = Color3.new(1, 0.431373, 0.431373)
		updateSettings()
	end)

	if not reqToggle then
		req.TextButton.Text = "✓"
		req.TextButton.TextColor3 = Color3.new(0.564706, 1, 0.364706)
		reqToggle = true
		updateSettings()
	else
		if disableToggle then
			reqSetting.Visible = true
		else
			req.TextButton.Text = "X"
			req.TextButton.TextColor3 = Color3.new(1, 0.431373, 0.431373)
			reqToggle = false
			updateSettings()
		end
	end
end)

dep.TextButton.MouseButton1Click:Connect(function()
	if not junkToggle then
		dep.TextButton.Text = "✓"
		dep.TextButton.TextColor3 = Color3.new(0.564706, 1, 0.364706)
		junkToggle = true
		updateSettings()
	else
		dep.TextButton.Text = "X"
		dep.TextButton.TextColor3 = Color3.new(1, 0.431373, 0.431373)
		junkToggle = false
		updateSettings()
	end
end)

main.help.MouseButton1Click:Connect(function()
	main.Help.Visible = true
end)

main.Help.help.MouseButton1Click:Connect(function()
	main.Help.Visible = false
end)

topbar.scanGame.MouseButton1Click:Connect(function()
	fullGameScan()
end)

deletion.no.MouseButton1Click:Connect(function()
	deletion.Visible = false
end)

askSetting.no.MouseButton1Click:Connect(function()
	askSetting.Visible = false
end)

getSetting.no.MouseButton1Click:Connect(function()
	getSetting.Visible = false
end)

autoSetting.no.MouseButton1Click:Connect(function()
	autoSetting.Visible = false
end)

loadSetting.no.MouseButton1Click:Connect(function()
	loadSetting.Visible = false
end)

reqSetting.no.MouseButton1Click:Connect(function()
	reqSetting.Visible = false
end)

scangamequickbar.Click:Connect(function()
	fullGameScan()

	UI.Parent = game.CoreGui
	openVal = true
end)

topbar.settings.MouseButton1Click:Connect(function()
	_settings.Visible = not _settings.Visible
	main.clearAll.Visible = not main.clearAll.Visible
	main.deleteAll.Visible = not main.deleteAll.Visible
end)

plugin.Unloading:Connect(function()
	UI.Parent = script
end)

while game.GameId == 0 do
	wait(0.2)
end

loadSettings()

warn("ZLOCK Version: " .. ve .. " loaded!")

while true do
	wait(30)
	
	local testPlugin = insertService:LoadAsset(7190436853)
	local vversion = testPlugin:WaitForChild("ZLOCK").Version.Value
	
	if vversion == ve then
		testPlugin:Destroy()
	else
		warn("ZLOCK " .. ve .. " is out of date. Please update to the latest version for the best security and performance.")
		testPlugin:Destroy()
		
		for i = 1, #versionText, 1 do 
			versionText[i].TextColor3 = Color3.fromRGB(139, 44, 44)
			loadSettings()
		end
	end
end
