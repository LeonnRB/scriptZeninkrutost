local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")

local isTouchDevice = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local screenGui = nil
local drawGui = nil
local drawObjects = {}
local connections = {}
local espObjects = {}
local flyEnabled = false
local flyVelocity = nil
local flyGyro = nil
local flySpeed = 60
local noclipEnabled = false
local noclipOriginal = {}
local autoStraferEnabled = false
local savedWalkSpeed = nil
local strafeSpeed = 55
local fastStopEnabled = false
local lastFloorMaterial = Enum.Material.Air
local fastStopActive = false
local mobileUp = false
local mobileDown = false
local jumpRequestAt = 0
local noSmokeEnabled = false
local noFlashEnabled = false
local infiniteAmmoEnabled = false
local rapidFireEnabled = false
local removeRecoilEnabled = false
local removeSpreadEnabled = false
local fastCrouchEnabled = false
local setInfiniteAmmo = nil
local setRapidFire = nil
local setRemoveRecoil = nil
local setRemoveSpread = nil
local setFastCrouch = nil
local thirdpersonEnabled = false
local zoomValue = 15
local applyingCamera = false
local savedCameraMode = nil
local savedMinZoom = nil
local savedMaxZoom = nil
local cameraFovEnabled = false
local cameraFovValue = 120
local glowEnemyEnabled = false
local localGlowEnabled = false
local glowEnemyColor = Color3.fromRGB(255, 60, 60)
local localGlowColor = Color3.fromRGB(60, 255, 120)
local glowFull = {Enemy = false, Local = false}
local enemyHighlights = {}
local localHighlight = nil
local glowViewmodelEnabled = false
local glowViewmodelColor = Color3.fromRGB(255, 255, 255)
local glowViewmodelFull = false
local viewmodelHighlights = {}
local laserMinesEnabled = false
local laserMineGlowEnabled = false
local laserMineGlowFull = false
local laserMineGlowColor = Color3.fromRGB(255, 0, 0)
local laserMineBoxEnabled = false
local laserMineBoxColor = Color3.fromRGB(255, 255, 255)
local laserMineHighlights = {}
local laserMineBoxes = {}
local grenadeCfg = {
	enabled = false,
	heGlow = false, heColor = Color3.fromRGB(255, 120, 0),
	flashGlow = false, flashColor = Color3.fromRGB(255, 255, 255),
	smokeGlow = false, smokeColor = Color3.fromRGB(120, 120, 120),
	incGlow = false, incColor = Color3.fromRGB(255, 60, 0),
	esp = false,
	redWarning = false
}
local fogCfg = {enabled = false, fogStart = 20, fogEnd = 250, color = Color3.fromRGB(255, 255, 255)}
local setFogEnabled = nil
local applyFog = nil
local knifeCfg = {enabled = false, option = "None"}
local applyKnife = nil
local customModelOption = "None"
local customModelFolder = nil
local customHidden = {}
local destroyCustomModel = nil
local restoreCustomTransparency = nil
local setCustomModel = nil
local updateCustomModel = nil
local worldAmbienceEnabled = false
local fullAmbienceEnabled = false
local worldColor = Color3.fromRGB(255, 255, 255)
local savedAmbient = nil
local savedOutdoorAmbient = nil
local bulletTracersEnabled = false
local savedBeamStates = {}
local skyOption = "None"
local skyPresets = nil
local skyKeyByOption = nil
local customSky = nil
local applySky = nil
local restoreSkyState = nil
local espEnabled = false
local teamCheckEnabled = false
local espBoxEnabled = false
local espNamesEnabled = false
local espSkeletonEnabled = false
local flagsEnabled = false
local flagOptions = {ForceField = false, Money = false, Ping = false}
local espWeaponEnabled = false
local flyRagdollEnabled = false
local boxColor = Color3.fromRGB(255, 255, 255)
local skeletonColor = Color3.fromRGB(255, 255, 255)
local aimEnabled = false
local aimBoneMode = "Head"
local aimFOV = 90
local aimFOVColor = Color3.fromRGB(255, 255, 255)
local aimTeamCheck = false
local aimForceFieldCheck = false
local aimSpeed = 5
local aimSmooth = 0
local aimWallCheck = false
local aimFOVCircle = nil
local antiAimEnabled = false
local antiYaw = "None"
local antiYawMode = "At Camera"
local antiSpinEnabled = false
local antiChar = nil
local savedRootC0 = nil
local watermarkEnabled = false
local watermarkSetState = nil
local introFinished = false
local introGuiRef = nil
local applyCameraSettings = nil
local updateCameraSection = nil
local setCameraFovEnabled = nil
local forceCameraFov = nil
local hookCameraFov = nil
local watermarkGui = nil
local watermarkScreenGui = nil
local grenadeEspScreenGui = nil
local checkboxTweens = {}
local configEntries = {}
local uiTheme = {accent = Color3.fromRGB(255, 0, 0), scale = isTouchDevice and 0.85 or 1, callbacks = {}, menuScale = nil, wmScale = nil}

local function accentShade(kind)
	local h, s, v = uiTheme.accent:ToHSV()
	if kind == "fill" then return Color3.fromHSV(h, s, v * 0.88) end
	if kind == "bright" then return Color3.fromHSV(h, math.clamp(s * 0.76, 0, 1), v) end
	if kind == "text" then return Color3.fromHSV(h, math.clamp(s * 0.67, 0, 1), v) end
	if kind == "dark" then return Color3.fromHSV(h, s, v * 0.55) end
	return uiTheme.accent
end
local function registerAccent(fn)
	table.insert(uiTheme.callbacks, fn)
	pcall(fn)
end
local function applyAccent()
	for _, fn in ipairs(uiTheme.callbacks) do pcall(fn) end
end
local function applyUIScale()
	if uiTheme.menuScale then pcall(function() uiTheme.menuScale.Scale = uiTheme.scale end) end
	if uiTheme.wmScale then pcall(function() uiTheme.wmScale.Scale = uiTheme.scale end) end
end
local function registerConfig(key, kind, getFn, setFn)
	for _, e in ipairs(configEntries) do
		if e.key == key then
			e.kind = kind
			e.get = getFn
			e.set = setFn
			return
		end
	end
	table.insert(configEntries, {key = key, kind = kind, get = getFn, set = setFn})
end
local function connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(connections, connection)
	return connection
end

local GuiDraw = {}
do
	local fontMap = {[0] = Enum.Font.Legacy, [1] = Enum.Font.SourceSans, [2] = Enum.Font.Gotham, [3] = Enum.Font.Code}
	local function measure(text, size, font)
		local ok, res = pcall(function()
			return TextService:GetTextSize(tostring(text), size, font, Vector2.new(4096, 4096))
		end)
		if ok and res then return res end
		return Vector2.new(#tostring(text) * size * 0.5, size)
	end
	function GuiDraw.new(class)
		local gui, stroke
		if class == "Text" then
			gui = Instance.new("TextLabel")
			gui.BackgroundTransparency = 1
			gui.AnchorPoint = Vector2.new(0, 0)
			gui.TextYAlignment = Enum.TextYAlignment.Top
		elseif class == "Line" then
			gui = Instance.new("Frame")
			gui.AnchorPoint = Vector2.new(0.5, 0.5)
		elseif class == "Circle" then
			gui = Instance.new("Frame")
			gui.AnchorPoint = Vector2.new(0.5, 0.5)
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(1, 0)
			c.Parent = gui
			stroke = Instance.new("UIStroke")
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Parent = gui
		else
			gui = Instance.new("Frame")
			gui.AnchorPoint = Vector2.new(0, 0)
			stroke = Instance.new("UIStroke")
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Parent = gui
		end
		gui.Name = "ZeninDraw"
		gui.BorderSizePixel = 0
		gui.BackgroundColor3 = Color3.new(1, 1, 1)
		gui.BackgroundTransparency = 1
		gui.Visible = false
		gui.Active = false
		gui.ZIndex = 1
		gui.Parent = drawGui
		local p = {
			Filled = false, Color = Color3.new(1, 1, 1), Thickness = 1, Transparency = 1,
			Visible = false, ZIndex = 1, Position = Vector2.zero, Size = Vector2.zero,
			Text = "", Center = false, Outline = false, Font = 2,
			From = Vector2.zero, To = Vector2.zero, Radius = 0
		}
		local dead = false
		local function paint()
			local alpha = math.clamp(p.Transparency, 0, 1)
			if class == "Text" then
				gui.TextColor3 = p.Color
				gui.TextTransparency = 1 - alpha
				gui.TextStrokeTransparency = p.Outline and (1 - alpha) or 1
			elseif class == "Line" then
				gui.BackgroundColor3 = p.Color
				gui.BackgroundTransparency = 1 - alpha
			else
				if p.Filled then
					gui.BackgroundColor3 = p.Color
					gui.BackgroundTransparency = 1 - alpha
					if stroke then stroke.Transparency = 1 end
				else
					gui.BackgroundTransparency = 1
					if stroke then
						stroke.Color = p.Color
						stroke.Transparency = 1 - alpha
						stroke.Thickness = math.max(1, p.Thickness)
					end
				end
			end
		end
		local function textSetup()
			if class ~= "Text" then return end
			gui.Font = fontMap[p.Font] or Enum.Font.Gotham
			gui.TextSize = math.max(1, p.Size)
			gui.Text = tostring(p.Text)
			gui.TextXAlignment = p.Center and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
			local b = measure(p.Text, gui.TextSize, gui.Font)
			gui.Size = UDim2.fromOffset(math.ceil(b.X) + 2, math.ceil(b.Y) + 2)
		end
		local function geometry()
			if class == "Line" then
				local a, b = p.From, p.To
				local d = b - a
				local len = d.Magnitude
				gui.Size = UDim2.fromOffset(math.max(1, len), math.max(1, p.Thickness))
				gui.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
				gui.Rotation = math.deg(math.atan2(d.Y, d.X))
			elseif class == "Circle" then
				local r = math.max(0, p.Radius)
				gui.Size = UDim2.fromOffset(r * 2, r * 2)
				gui.Position = UDim2.fromOffset(p.Position.X, p.Position.Y)
			elseif class == "Text" then
				gui.Position = UDim2.fromOffset(p.Position.X, p.Position.Y)
			else
				gui.Position = UDim2.fromOffset(p.Position.X, p.Position.Y)
				gui.Size = UDim2.fromOffset(math.max(0, p.Size.X), math.max(0, p.Size.Y))
			end
		end
		local obj = {}
		local mt = {}
		mt.__index = function(_, k)
			if k == "TextBounds" then
				if class == "Text" then
					return measure(p.Text, math.max(1, p.Size), fontMap[p.Font] or Enum.Font.Gotham)
				end
				return p.Size
			end
			if k == "Remove" or k == "Destroy" then
				return function()
					if dead then return end
					dead = true
					pcall(function() gui:Destroy() end)
				end
			end
			return p[k]
		end
		mt.__newindex = function(_, k, v)
			if dead then return end
			if p[k] == v then return end
			p[k] = v
			if k == "Visible" then
				gui.Visible = v and true or false
			elseif k == "ZIndex" then
				pcall(function() gui.ZIndex = math.clamp(math.floor(v), 1, 100) end)
			elseif k == "Color" or k == "Transparency" or k == "Filled" or k == "Outline" then
				paint()
			elseif k == "Thickness" then
				paint()
				if class == "Line" then geometry() end
			elseif k == "Text" or k == "Font" or k == "Center" then
				textSetup()
				paint()
			elseif k == "Size" then
				if class == "Text" then textSetup() else geometry() end
			else
				geometry()
			end
		end
		setmetatable(obj, mt)
		textSetup()
		paint()
		geometry()
		table.insert(drawObjects, obj)
		return obj
	end
end
local realDrawing = nil
pcall(function()
	if typeof(Drawing) == "table" and Drawing.new then realDrawing = Drawing end
end)
local DrawLib = (not isTouchDevice and realDrawing) or GuiDraw

do
	local knifePresets = {
		["None"] = {knifeType = "Knife", knifeSkin = "Knife_Stock"},
		["Karambit"] = {knifeType = "Karambit", knifeSkin = "Karambit_Vanilla"},
		["Butterfly"] = {knifeType = "Butterfly Knife", knifeSkin = "Butterfly Knife_Vanilla"},
		["Skeleton"] = {knifeType = "Skeleton Knife", knifeSkin = "Skeleton Knife_Vanilla"},
		["M9 Bayonet"] = {knifeType = "M9 Bayonet", knifeSkin = "M9 Bayonet_Vanilla"}
	}
	applyKnife = function()
		if not knifeCfg.enabled then return end
		local lp = Players.LocalPlayer
		if not lp then return end
		local preset = knifePresets[knifeCfg.option]
		if not preset then return end
		pcall(function()
			lp:SetAttribute("KnifeType", preset.knifeType)
			lp:SetAttribute("KnifeSkin", preset.knifeSkin)
		end)
	end
end

local function destroyFlyMovers()
	if flyVelocity then pcall(function() flyVelocity:Destroy() end) flyVelocity = nil end
	if flyGyro then pcall(function() flyGyro:Destroy() end) flyGyro = nil end
end
local function stopFly()
	destroyFlyMovers()
	local char = Players.LocalPlayer and Players.LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		pcall(function()
			hum.PlatformStand = false
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		end)
	end
end
local function setupFly(character)
	destroyFlyMovers()
	if not flyEnabled or not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local hum = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then return end
	local bv = Instance.new("BodyVelocity")
	bv.Name = "ZeninFlyVelocity"
	bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bv.P = 12000
	bv.Velocity = Vector3.zero
	bv.Parent = hrp
	local bg = Instance.new("BodyGyro")
	bg.Name = "ZeninFlyGyro"
	bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	bg.P = 12000
	bg.CFrame = hrp.CFrame
	bg.Parent = hrp
	flyVelocity = bv
	flyGyro = bg
	pcall(function() hum.PlatformStand = true end)
end
local function restoreNoclip()
	for part, original in pairs(noclipOriginal) do
		if part and part.Parent then pcall(function() part.CanCollide = original end) end
	end
	noclipOriginal = {}
end

do
	local savedFireRates = {}
	local savedAutoValues = {}
	local savedRecoilValues = {}
	local savedSpreadValues = {}
	local savedCrouchRecoveryValues = {}
	local spreadAttributesList = {"Spread", "JumpSpread", "LadderSpread", "LandSpread", "FireSpread", "StandSpread", "CrouchSpread", "MoveSpread", "RunSpread"}
	setInfiniteAmmo = function(state)
		infiniteAmmoEnabled = state
		local weapons = ReplicatedStorage:FindFirstChild("Weapons")
		if not weapons then return end
		for _, folder in ipairs(weapons:GetChildren()) do
			if folder:IsA("Folder") then pcall(function() folder:SetAttribute("UseAmmo", state and 0 or 1) end) end
		end
	end
	setRapidFire = function(state)
		rapidFireEnabled = state
		local weapons = ReplicatedStorage:FindFirstChild("Weapons")
		if state then
			if not weapons then return end
			for _, folder in ipairs(weapons:GetChildren()) do
				if folder:IsA("Folder") then
					local ok, value = pcall(function() return folder:GetAttribute("FireRate") end)
					if ok and type(value) == "number" then savedFireRates[folder] = value end
					local okAuto, autoValue = pcall(function() return folder:GetAttribute("Auto") end)
					if okAuto and type(autoValue) == "boolean" then savedAutoValues[folder] = autoValue end
					pcall(function() folder:SetAttribute("FireRate", 0) end)
					pcall(function() folder:SetAttribute("Auto", true) end)
				end
			end
		else
			for folder, value in pairs(savedFireRates) do
				if folder and folder.Parent then pcall(function() folder:SetAttribute("FireRate", value) end) end
			end
			savedFireRates = {}
			for folder, value in pairs(savedAutoValues) do
				if folder and folder.Parent then pcall(function() folder:SetAttribute("Auto", value) end) end
			end
			savedAutoValues = {}
		end
	end
	setRemoveRecoil = function(state)
		removeRecoilEnabled = state
		local weapons = ReplicatedStorage:FindFirstChild("Weapons")
		if not weapons then return end
		if state then
			for _, folder in ipairs(weapons:GetChildren()) do
				if folder:IsA("Folder") then
					local saved = {}
					local okX, valX = pcall(function() return folder:GetAttribute("RecoilX") end)
					if okX and valX ~= nil then saved.RecoilX = valX end
					local okY, valY = pcall(function() return folder:GetAttribute("RecoilY") end)
					if okY and valY ~= nil then saved.RecoilY = valY end
					savedRecoilValues[folder] = saved
					pcall(function() folder:SetAttribute("RecoilX", 0) end)
					pcall(function() folder:SetAttribute("RecoilY", 0) end)
				end
			end
		else
			for folder, saved in pairs(savedRecoilValues) do
				if folder and folder.Parent then
					if saved.RecoilX ~= nil then pcall(function() folder:SetAttribute("RecoilX", saved.RecoilX) end)
					else pcall(function() folder:SetAttribute("RecoilX", nil) end) end
					if saved.RecoilY ~= nil then pcall(function() folder:SetAttribute("RecoilY", saved.RecoilY) end)
					else pcall(function() folder:SetAttribute("RecoilY", nil) end) end
				end
			end
			savedRecoilValues = {}
		end
	end
	setRemoveSpread = function(state)
		removeSpreadEnabled = state
		local weapons = ReplicatedStorage:FindFirstChild("Weapons")
		if not weapons then return end
		if state then
			for _, folder in ipairs(weapons:GetChildren()) do
				if folder:IsA("Folder") then
					local saved = {}
					for _, attrName in ipairs(spreadAttributesList) do
						local ok, val = pcall(function() return folder:GetAttribute(attrName) end)
						saved[attrName] = (ok and val ~= nil) and val or nil
						pcall(function() folder:SetAttribute(attrName, 0) end)
					end
					savedSpreadValues[folder] = saved
				end
			end
		else
			for folder, saved in pairs(savedSpreadValues) do
				if folder and folder.Parent then
					for _, attrName in ipairs(spreadAttributesList) do
						if saved[attrName] ~= nil then pcall(function() folder:SetAttribute(attrName, saved[attrName]) end)
						else pcall(function() folder:SetAttribute(attrName, nil) end) end
					end
				end
			end
			savedSpreadValues = {}
		end
	end
	setFastCrouch = function(state)
		fastCrouchEnabled = state
		local weapons = ReplicatedStorage:FindFirstChild("Weapons")
		if not weapons then return end
		if state then
			for _, folder in ipairs(weapons:GetChildren()) do
				if folder:IsA("Folder") then
					local ok, val = pcall(function() return folder:GetAttribute("CrouchRecoveryTime") end)
					savedCrouchRecoveryValues[folder] = (ok and val ~= nil) and val or nil
					pcall(function() folder:SetAttribute("CrouchRecoveryTime", 0) end)
				end
			end
		else
			for folder, savedVal in pairs(savedCrouchRecoveryValues) do
				if folder and folder.Parent then
					if savedVal ~= nil then pcall(function() folder:SetAttribute("CrouchRecoveryTime", savedVal) end)
					else pcall(function() folder:SetAttribute("CrouchRecoveryTime", nil) end) end
				end
			end
			savedCrouchRecoveryValues = {}
		end
	end
end

local updateNoSmoke = nil
local setNoSmoke = nil
do
	local smokeSaved = {}
	local function isEmitter(obj)
		return obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Beam") or obj:IsA("Trail")
	end
	local function setNumericTransparency(obj, value)
		local ok = pcall(function() obj.Transparency = value end)
		if not ok then pcall(function() obj.Transparency = NumberRange.new(value, value) end) end
	end
	local function hideSmokeObject(obj)
		local entry = smokeSaved[obj]
		if not entry then
			entry = {emitters = {}}
			for _, desc in ipairs(obj:GetDescendants()) do
				if isEmitter(desc) then table.insert(entry.emitters, {obj = desc, enabled = desc.Enabled, trans = desc.Transparency}) end
			end
			if isEmitter(obj) then table.insert(entry.emitters, {obj = obj, enabled = obj.Enabled, trans = obj.Transparency}) end
			smokeSaved[obj] = entry
		end
		setNumericTransparency(obj, 1)
		if isEmitter(obj) then pcall(function() obj.Enabled = false end) end
		for _, e in ipairs(entry.emitters) do
			if e.obj and e.obj.Parent then
				pcall(function() e.obj.Transparency = NumberRange.new(1, 1) end)
				pcall(function() e.obj.Enabled = false end)
			end
		end
	end
	local function showSmokeObject(obj, entry)
		setNumericTransparency(obj, 0)
		for _, e in ipairs(entry.emitters) do
			if e.obj and e.obj.Parent then
				pcall(function() e.obj.Transparency = e.trans end)
				pcall(function() e.obj.Enabled = e.enabled end)
			end
		end
		if isEmitter(obj) then pcall(function() obj.Enabled = true end) end
	end
	updateNoSmoke = function()
		if not noSmokeEnabled then return end
		local debris = workspace:FindFirstChild("Debris")
		if not debris then return end
		for _, folder in ipairs(debris:GetChildren()) do
			if folder.Name == "Smoke" then
				for _, obj in ipairs(folder:GetDescendants()) do
					if string.lower(obj.Name) == "smoak" then hideSmokeObject(obj) end
				end
			end
		end
	end
	setNoSmoke = function(state)
		noSmokeEnabled = state
		if not state then
			for obj, entry in pairs(smokeSaved) do
				if obj and obj.Parent then showSmokeObject(obj, entry) end
			end
			smokeSaved = {}
		end
	end
end

local function applyNoFlash(state)
	local lp = Players.LocalPlayer
	if not lp then return end
	local ps = lp:FindFirstChild("PlayerScripts")
	if not ps then return end
	local base = ps:FindFirstChild("PlayerBase")
	if not base then return end
	local flash = base:FindFirstChild("FlashbangEffect")
	if not flash then return end
	pcall(function() flash.Disabled = state and true or false end)
end
local function updateNoFlash()
	if not noFlashEnabled then return end
	applyNoFlash(true)
end

do
	local savedSkyObjects = nil
	local savedLightingProps = nil
	skyPresets = {
		Twilight = {SkyName = "CleanLightDuskSky", SkyboxBk = "rbxassetid://271042516", SkyboxDn = "rbxassetid://271077243", SkyboxFt = "rbxassetid://271042556", SkyboxLf = "rbxassetid://271042310", SkyboxRt = "rbxassetid://271042467", SkyboxUp = "rbxassetid://271077958", StarCount = nil, SunAngularSize = 0, MoonAngularSize = 11, ClockTime = 17.6, Brightness = 2},
		ClassicNight = {SkyName = "ClassicNightSky", SkyboxBk = "rbxassetid://1013853", SkyboxDn = "rbxassetid://1013851", SkyboxFt = "rbxassetid://1013852", SkyboxLf = "rbxassetid://1013854", SkyboxRt = "rbxassetid://1013855", SkyboxUp = "rbxassetid://1013856", StarCount = 3000, SunAngularSize = 0, MoonAngularSize = 11, ClockTime = 0, Brightness = 1},
		RedDay = {SkyName = "YellowSunriseSky", SkyboxBk = "rbxassetid://1012890", SkyboxDn = "rbxassetid://1012891", SkyboxFt = "rbxassetid://1012887", SkyboxLf = "rbxassetid://1012889", SkyboxRt = "rbxassetid://1012888", SkyboxUp = "rbxassetid://1014449", StarCount = nil, SunAngularSize = 18, MoonAngularSize = 0, ClockTime = 6.4, Brightness = 2.2}
	}
	skyKeyByOption = {["Twilight"] = "Twilight", ["Classic Night"] = "ClassicNight", ["Red Day"] = "RedDay"}
	local function saveSkyState()
		if savedSkyObjects then return end
		savedSkyObjects = {}
		for _, obj in ipairs(Lighting:GetChildren()) do
			if obj:IsA("Sky") or obj:IsA("Atmosphere") then
				pcall(function() obj.Archivable = true end)
				local ok, clone = pcall(function() return obj:Clone() end)
				if ok and clone then table.insert(savedSkyObjects, clone) end
			end
		end
		savedLightingProps = {FogStart = Lighting.FogStart, FogEnd = Lighting.FogEnd, ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness}
	end
	local function clearSkyObjects()
		for _, obj in ipairs(Lighting:GetChildren()) do
			if obj:IsA("Sky") then pcall(function() obj:Destroy() end)
			elseif obj:IsA("Atmosphere") and not fogCfg.enabled then pcall(function() obj:Destroy() end) end
		end
		customSky = nil
	end
	restoreSkyState = function()
		if not savedSkyObjects and not savedLightingProps then return end
		clearSkyObjects()
		if savedLightingProps then
			pcall(function()
				if not fogCfg.enabled then
					Lighting.FogStart = savedLightingProps.FogStart
					Lighting.FogEnd = savedLightingProps.FogEnd
				end
				Lighting.ClockTime = savedLightingProps.ClockTime
				Lighting.Brightness = savedLightingProps.Brightness
			end)
		end
		if savedSkyObjects then
			for _, clone in ipairs(savedSkyObjects) do pcall(function() clone.Parent = Lighting end) end
		end
		savedSkyObjects = nil
		savedLightingProps = nil
	end
	applySky = function(option)
		if option == "None" then restoreSkyState() return end
		local key = skyKeyByOption[option]
		local preset = key and skyPresets[key]
		if not preset then return end
		saveSkyState()
		clearSkyObjects()
		pcall(function()
			if not fogCfg.enabled then
				Lighting.FogEnd = 100000
				Lighting.FogStart = 100000
			end
			local sky = Instance.new("Sky")
			sky.Name = preset.SkyName
			sky.SkyboxBk = preset.SkyboxBk
			sky.SkyboxDn = preset.SkyboxDn
			sky.SkyboxFt = preset.SkyboxFt
			sky.SkyboxLf = preset.SkyboxLf
			sky.SkyboxRt = preset.SkyboxRt
			sky.SkyboxUp = preset.SkyboxUp
			if preset.StarCount then sky.StarCount = preset.StarCount end
			sky.SunAngularSize = preset.SunAngularSize
			sky.MoonAngularSize = preset.MoonAngularSize
			sky.Parent = Lighting
			customSky = sky
			Lighting.ClockTime = preset.ClockTime
			Lighting.Brightness = preset.Brightness
		end)
	end
end

do
	local removedAtmospheres = {}
	local savedFogProps = nil
	local function detachAtmospheres()
		for _, obj in ipairs(Lighting:GetChildren()) do
			if obj:IsA("Atmosphere") then
				local originalParent = obj.Parent
				local ok = pcall(function() obj.Parent = nil end)
				if ok then table.insert(removedAtmospheres, {obj = obj, parent = originalParent}) end
			end
		end
	end
	local function restoreAtmospheres()
		for i = #removedAtmospheres, 1, -1 do
			local entry = removedAtmospheres[i]
			if entry.obj then
				local target = entry.parent or Lighting
				local ok = pcall(function() entry.obj.Parent = target end)
				if ok then break end
			end
		end
		removedAtmospheres = {}
	end
	applyFog = function()
		if not fogCfg.enabled then return end
		detachAtmospheres()
		pcall(function()
			if Lighting.FogStart ~= fogCfg.fogStart then Lighting.FogStart = fogCfg.fogStart end
			if Lighting.FogEnd ~= fogCfg.fogEnd then Lighting.FogEnd = fogCfg.fogEnd end
			if Lighting.FogColor ~= fogCfg.color then Lighting.FogColor = fogCfg.color end
		end)
	end
	setFogEnabled = function(state)
		fogCfg.enabled = state
		if state then
			if savedFogProps == nil then
				savedFogProps = {FogStart = Lighting.FogStart, FogEnd = Lighting.FogEnd, FogColor = Lighting.FogColor}
			end
			applyFog()
		else
			restoreAtmospheres()
			if savedFogProps then
				pcall(function()
					Lighting.FogStart = savedFogProps.FogStart
					Lighting.FogEnd = savedFogProps.FogEnd
					Lighting.FogColor = savedFogProps.FogColor
				end)
				savedFogProps = nil
			end
		end
	end
end

local function setWorldAmbience(state)
	worldAmbienceEnabled = state
	if state then
		if savedAmbient == nil then savedAmbient = Lighting.Ambient end
		if fullAmbienceEnabled and savedOutdoorAmbient == nil then savedOutdoorAmbient = Lighting.OutdoorAmbient end
		pcall(function()
			Lighting.Ambient = worldColor
			if fullAmbienceEnabled then Lighting.OutdoorAmbient = worldColor end
		end)
	else
		pcall(function()
			if savedAmbient ~= nil then Lighting.Ambient = savedAmbient end
			if savedOutdoorAmbient ~= nil then Lighting.OutdoorAmbient = savedOutdoorAmbient end
		end)
		savedAmbient = nil
		savedOutdoorAmbient = nil
	end
end
local function setFullAmbience(state)
	fullAmbienceEnabled = state
	if state then
		if worldAmbienceEnabled then
			if savedOutdoorAmbient == nil then savedOutdoorAmbient = Lighting.OutdoorAmbient end
			pcall(function() Lighting.OutdoorAmbient = worldColor end)
		end
	else
		if savedOutdoorAmbient ~= nil then
			pcall(function() Lighting.OutdoorAmbient = savedOutdoorAmbient end)
			savedOutdoorAmbient = nil
		end
	end
end
local function setBulletTracers(state)
	bulletTracersEnabled = state
	local weapons = ReplicatedStorage:FindFirstChild("Weapons")
	if not weapons then return end
	if state then
		for _, folder in ipairs(weapons:GetChildren()) do
			if folder:IsA("Folder") then
				local existed = false
				local oldValue = nil
				local ok, value = pcall(function() return folder:GetAttribute("Beam") end)
				if ok and value ~= nil then existed = true oldValue = value end
				savedBeamStates[folder] = {existed = existed, value = oldValue}
				pcall(function() folder:SetAttribute("Beam", true) end)
			end
		end
	else
		for folder, info in pairs(savedBeamStates) do
			if folder and folder.Parent then
				pcall(function()
					if info.existed then folder:SetAttribute("Beam", info.value)
					else folder:SetAttribute("Beam", nil) end
				end)
			end
		end
		savedBeamStates = {}
	end
end

do
	local customModelChar = nil
	local patriotClones = {}
	local droneParts = {}
	local blockPart = nil
	local propAngle = 0
	local putinParts = {}
	local function patriotColor(part)
		local n = part.Name
		if n == "LeftLeg" or n == "RightLeg" or n == "LeftLowerLeg" or n == "RightLowerLeg" or n == "LeftFoot" or n == "RightFoot" then return Color3.fromRGB(213, 43, 30) end
		if n == "Torso" or n == "LowerTorso" or n == "LeftUpperLeg" or n == "RightUpperLeg" then return Color3.fromRGB(0, 56, 168) end
		return Color3.fromRGB(245, 245, 245)
	end
	local function makeModelPart(size, color, shape)
		local p = Instance.new("Part")
		p.Size = size
		p.Color = color
		p.Material = Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.CastShadow = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then pcall(function() p.Shape = shape end) end
		p.Parent = customModelFolder
		return p
	end
	local function createPatriotClone(orig)
		local clone
		pcall(function() orig.Archivable = true end)
		local ok, c = pcall(function() return orig:Clone() end)
		if ok and c and c:IsA("BasePart") then
			clone = c
			for _, d in ipairs(clone:GetDescendants()) do
				if not d:IsA("DataModelMesh") then pcall(function() d:Destroy() end) end
			end
		else
			if c then pcall(function() c:Destroy() end) end
			clone = Instance.new("Part")
			pcall(function()
				clone.Size = orig.Size
				if orig:IsA("Part") then clone.Shape = orig.Shape end
			end)
		end
		pcall(function()
			clone.Name = "ZeninPatriot_" .. orig.Name
			clone.Anchored = true
			clone.CanCollide = false
			clone.CanTouch = false
			clone.CanQuery = false
			clone.Transparency = 0
			clone.Color = patriotColor(orig)
			clone.Material = Enum.Material.SmoothPlastic
			clone.Reflectance = 0
			clone.CastShadow = false
			clone.CFrame = orig.CFrame
			clone.Parent = customModelFolder
		end)
		return clone
	end
	local function buildDrone()
		droneParts = {}
		local function addStatic(size, offset, color, shape)
			local p = makeModelPart(size, color, shape)
			table.insert(droneParts, {part = p, offset = offset, isProp = false})
		end
		addStatic(Vector3.new(0.9, 0.28, 1.3), CFrame.new(0, 0, 0), Color3.fromRGB(45, 45, 50))
		addStatic(Vector3.new(0.5, 0.18, 0.7), CFrame.new(0, 0.22, 0.05), Color3.fromRGB(70, 70, 76))
		addStatic(Vector3.new(0.3, 0.25, 0.2), CFrame.new(0, 0.08, -0.72), Color3.fromRGB(25, 25, 28))
		addStatic(Vector3.new(0.16, 0.16, 0.16), CFrame.new(0, 0.08, -0.84), Color3.fromRGB(15, 15, 18), Enum.PartType.Ball)
		addStatic(Vector3.new(0.04, 0.45, 0.04), CFrame.new(0, 0.45, 0.55) * CFrame.Angles(math.rad(-20), 0, 0), Color3.fromRGB(20, 20, 22))
		local armRot = {{x = 0.375, z = 0.375, a = 45}, {x = -0.375, z = -0.375, a = 45}, {x = 0.375, z = -0.375, a = -45}, {x = -0.375, z = 0.375, a = -45}}
		for _, arm in ipairs(armRot) do
			addStatic(Vector3.new(0.14, 0.08, 1.06), CFrame.new(arm.x, 0, arm.z) * CFrame.Angles(0, math.rad(arm.a), 0), Color3.fromRGB(30, 30, 33))
		end
		for _, sx in ipairs({-1, 1}) do
			for _, sz in ipairs({-1, 1}) do
				local mx, mz = sx * 0.75, sz * 0.75
				addStatic(Vector3.new(0.22, 0.2, 0.2), CFrame.new(mx, 0.06, mz) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(85, 85, 92), Enum.PartType.Cylinder)
				for _, baseAngle in ipairs({0, math.pi / 2}) do
					local p = makeModelPart(Vector3.new(1.0, 0.03, 0.1), Color3.fromRGB(205, 35, 40))
					table.insert(droneParts, {part = p, pos = Vector3.new(mx, 0.2, mz), baseAngle = baseAngle, dir = sx * sz, isProp = true})
				end
			end
		end
	end
	local function buildPutin()
		putinParts = {}
		local function add(size, color, boneName, offset, altBone, shape)
			local p = makeModelPart(size, color, shape)
			table.insert(putinParts, {part = p, bone = boneName, altBone = altBone, offset = offset})
		end
		add(Vector3.new(1.2, 1.2, 1.2), Color3.fromRGB(255, 220, 185), "Head", CFrame.new(0, 0, 0), nil, Enum.PartType.Ball)
		add(Vector3.new(0.18, 0.12, 0.06), Color3.fromRGB(255, 255, 255), "Head", CFrame.new(-0.28, 0.18, -0.52), nil, Enum.PartType.Ball)
		add(Vector3.new(0.18, 0.12, 0.06), Color3.fromRGB(255, 255, 255), "Head", CFrame.new(0.28, 0.18, -0.52), nil, Enum.PartType.Ball)
		add(Vector3.new(0.08, 0.08, 0.04), Color3.fromRGB(0, 0, 0), "Head", CFrame.new(-0.28, 0.18, -0.56), nil, Enum.PartType.Ball)
		add(Vector3.new(0.08, 0.08, 0.04), Color3.fromRGB(0, 0, 0), "Head", CFrame.new(0.28, 0.18, -0.56), nil, Enum.PartType.Ball)
		add(Vector3.new(0.12, 0.18, 0.12), Color3.fromRGB(245, 210, 175), "Head", CFrame.new(0, 0.06, -0.58), nil, Enum.PartType.Ball)
		add(Vector3.new(0.35, 0.05, 0.03), Color3.fromRGB(160, 90, 90), "Head", CFrame.new(0, -0.18, -0.58), nil)
		add(Vector3.new(2, 2, 1), Color3.fromRGB(20, 20, 20), "Torso", CFrame.new(0, 0, 0), "UpperTorso")
		add(Vector3.new(1, 2, 1), Color3.fromRGB(20, 20, 20), "Left Arm", CFrame.new(0, 0, 0), "LeftUpperArm")
		add(Vector3.new(1, 2, 1), Color3.fromRGB(20, 20, 20), "Right Arm", CFrame.new(0, 0, 0), "RightUpperArm")
		add(Vector3.new(1, 2, 1), Color3.fromRGB(20, 20, 20), "Left Leg", CFrame.new(0, 0, 0), "LeftUpperLeg")
		add(Vector3.new(1, 2, 1), Color3.fromRGB(20, 20, 20), "Right Leg", CFrame.new(0, 0, 0), "RightUpperLeg")
	end
	destroyCustomModel = function()
		if customModelFolder then pcall(function() customModelFolder:Destroy() end) end
		customModelFolder = nil
		customModelChar = nil
		patriotClones = {}
		droneParts = {}
		putinParts = {}
		blockPart = nil
	end
	restoreCustomTransparency = function()
		for inst, original in pairs(customHidden) do
			if inst and inst.Parent then pcall(function() inst.Transparency = original end) end
		end
		customHidden = {}
	end
	local function ensureCustomModel(char)
		if customModelFolder and customModelFolder.Parent and customModelChar == char then return end
		destroyCustomModel()
		customModelChar = char
		local ok, f = pcall(function()
			local folder = Instance.new("Folder")
			folder.Name = "ZeninCustomModel"
			folder.Parent = workspace
			return folder
		end)
		if not ok or not f then return end
		customModelFolder = f
		if customModelOption == "FPV Drone" then buildDrone()
		elseif customModelOption == "Block" then blockPart = makeModelPart(Vector3.new(2.4, 5, 1.6), Color3.fromRGB(255, 255, 255))
		elseif customModelOption == "Putin" then buildPutin() end
	end
	setCustomModel = function(option)
		if customModelOption == option then return end
		customModelOption = option
		destroyCustomModel()
		if option == "None" then restoreCustomTransparency() end
	end
	updateCustomModel = function(char, hrp, dt)
		if customModelOption == "None" or not char then return end
		ensureCustomModel(char)
		if not customModelFolder then return end
		for _, d in ipairs(char:GetDescendants()) do
			if d:IsA("BasePart") then
				if customHidden[d] == nil then customHidden[d] = d.Transparency end
				if d.Transparency ~= 1 then pcall(function() d.Transparency = 1 end) end
				if customModelOption == "Patriot" and d.Name ~= "HumanoidRootPart" then
					local clone = patriotClones[d]
					if not clone or clone.Parent == nil then
						clone = createPatriotClone(d)
						patriotClones[d] = clone
					end
					if clone then pcall(function() clone.CFrame = d.CFrame end) end
				end
			elseif d:IsA("Decal") or d:IsA("Texture") then
				if customHidden[d] == nil then customHidden[d] = d.Transparency end
				if d.Transparency ~= 1 then pcall(function() d.Transparency = 1 end) end
			end
		end
		for orig, clone in pairs(patriotClones) do
			if orig.Parent == nil then
				pcall(function() clone:Destroy() end)
				patriotClones[orig] = nil
			end
		end
		local rootCF = nil
		if hrp then rootCF = hrp.CFrame
		else
			local ok, pivot = pcall(char.GetPivot, char)
			if ok and pivot then rootCF = pivot end
		end
		if not rootCF then return end
		if customModelOption == "FPV Drone" then
			local pos = rootCF.Position + Vector3.new(0, 3.2, 0)
			local look = rootCF.LookVector
			local flat = Vector3.new(look.X, 0, look.Z)
			local droneCF = CFrame.new(pos)
			if flat.Magnitude > 0.001 then droneCF = CFrame.lookAt(pos, pos + flat.Unit) end
			propAngle = (propAngle + dt * 45) % (math.pi * 2)
			for _, spec in ipairs(droneParts) do
				if spec.part and spec.part.Parent then
					pcall(function()
						if spec.isProp then
							spec.part.CFrame = droneCF * CFrame.new(spec.pos) * CFrame.Angles(0, spec.baseAngle + propAngle * spec.dir, 0)
						else
							spec.part.CFrame = droneCF * spec.offset
						end
					end)
				end
			end
		elseif customModelOption == "Block" and blockPart then
			pcall(function() blockPart.CFrame = rootCF * CFrame.new(0, -0.5, 0) end)
		elseif customModelOption == "Putin" then
			for _, spec in ipairs(putinParts) do
				if spec.part and spec.part.Parent then
					local bone = char:FindFirstChild(spec.bone)
					if not bone and spec.altBone then bone = char:FindFirstChild(spec.altBone) end
					if bone then pcall(function() spec.part.CFrame = bone.CFrame * spec.offset end) end
				end
			end
		end
	end
end

do
	local savedCameraFov = nil
	local fovTween = nil
	local fovConn = nil
	local hookedCamera = nil
	forceCameraFov = function()
		if not cameraFovEnabled then return end
		local camera = workspace.CurrentCamera
		if not camera then return end
		if camera.FieldOfView == cameraFovValue then return end
		if fovTween then pcall(function() fovTween:Cancel() end) end
		local ok, t = pcall(function()
			return TweenService:Create(camera, TweenInfo.new(0, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {FieldOfView = cameraFovValue})
		end)
		if ok and t then
			fovTween = t
			t:Play()
		end
	end
	hookCameraFov = function()
		local camera = workspace.CurrentCamera
		if hookedCamera == camera then return end
		if fovConn then pcall(function() fovConn:Disconnect() end) fovConn = nil end
		hookedCamera = camera
		if camera then
			fovConn = connect(camera:GetPropertyChangedSignal("FieldOfView"), function()
				if not cameraFovEnabled then return end
				if not fovTween or fovTween.PlaybackState ~= Enum.PlaybackState.Playing then forceCameraFov() end
			end)
			forceCameraFov()
		end
	end
	setCameraFovEnabled = function(state)
		cameraFovEnabled = state
		local camera = workspace.CurrentCamera
		if state then
			if camera and savedCameraFov == nil then savedCameraFov = camera.FieldOfView end
			hookCameraFov()
			forceCameraFov()
		else
			if fovTween then pcall(function() fovTween:Cancel() end) fovTween = nil end
			if camera and savedCameraFov ~= nil then pcall(function() camera.FieldOfView = savedCameraFov end) end
			savedCameraFov = nil
		end
		if updateCameraSection then updateCameraSection(false) end
	end
end

local function cleanup()
	flyEnabled = false
	autoStraferEnabled = false
	noclipEnabled = false
	glowEnemyEnabled = false
	localGlowEnabled = false
	worldAmbienceEnabled = false
	fullAmbienceEnabled = false
	customModelOption = "None"
	aimEnabled = false
	antiAimEnabled = false
	flyRagdollEnabled = false
	laserMinesEnabled = false
	glowViewmodelEnabled = false
	glowViewmodelFull = false
	fastStopEnabled = false
	flagsEnabled = false
	flagOptions.ForceField = false
	flagOptions.Money = false
	flagOptions.Ping = false
	espWeaponEnabled = false
	aimForceFieldCheck = false
	watermarkEnabled = false
	knifeCfg.enabled = false
	grenadeCfg.enabled = false
	grenadeCfg.esp = false
	grenadeCfg.redWarning = false
	uiTheme.accent = Color3.fromRGB(255, 0, 0)
	uiTheme.scale = isTouchDevice and 0.85 or 1
	stopFly()
	restoreNoclip()
	restoreCustomTransparency()
	destroyCustomModel()
	if fogCfg.enabled then pcall(function() setFogEnabled(false) end) end
	fogCfg.enabled = false
	if cameraFovEnabled then pcall(function() setCameraFovEnabled(false) end) end
	cameraFovEnabled = false
	if savedRootC0 then
		local lChar = Players.LocalPlayer and Players.LocalPlayer.Character
		local lHrp = lChar and lChar:FindFirstChild("HumanoidRootPart")
		local lJoint = lHrp and lHrp:FindFirstChildOfClass("Motor6D")
		if lJoint then pcall(function() lJoint.C0 = savedRootC0 end) end
		savedRootC0 = nil
		antiChar = nil
	end
	pcall(function()
		if savedAmbient ~= nil then Lighting.Ambient = savedAmbient end
		if savedOutdoorAmbient ~= nil then Lighting.OutdoorAmbient = savedOutdoorAmbient end
	end)
	savedAmbient = nil
	savedOutdoorAmbient = nil
	if bulletTracersEnabled then pcall(function() setBulletTracers(false) end) end
	skyOption = "None"
	pcall(restoreSkyState)
	if localHighlight then pcall(function() localHighlight:Destroy() end) localHighlight = nil end
	for player, h in pairs(enemyHighlights) do
		if h then pcall(function() h:Destroy() end) end
		enemyHighlights[player] = nil
	end
	for mine, h in pairs(laserMineHighlights) do
		if h then pcall(function() h:Destroy() end) end
		laserMineHighlights[mine] = nil
	end
	for mine, box in pairs(laserMineBoxes) do
		if box then pcall(function() box.Visible = false box:Remove() end) end
		laserMineBoxes[mine] = nil
	end
	for key, h in pairs(viewmodelHighlights) do
		if h then pcall(function() h:Destroy() end) end
		viewmodelHighlights[key] = nil
	end
	if aimFOVCircle then pcall(function() aimFOVCircle:Remove() end) aimFOVCircle = nil end
	if infiniteAmmoEnabled then pcall(function() setInfiniteAmmo(false) end) end
	if rapidFireEnabled then pcall(function() setRapidFire(false) end) end
	if removeRecoilEnabled then pcall(function() setRemoveRecoil(false) end) end
	if removeSpreadEnabled then pcall(function() setRemoveSpread(false) end) end
	if fastCrouchEnabled then pcall(function() setFastCrouch(false) end) end
	if thirdpersonEnabled then
		thirdpersonEnabled = false
		local lp = Players.LocalPlayer
		if lp and savedCameraMode ~= nil then
			pcall(function()
				lp.CameraMode = savedCameraMode
				lp.CameraMinZoomDistance = savedMinZoom
				lp.CameraMaxZoomDistance = savedMaxZoom
			end)
		end
		savedCameraMode, savedMinZoom, savedMaxZoom = nil, nil, nil
	end
	if savedWalkSpeed ~= nil then
		local char = Players.LocalPlayer and Players.LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then pcall(function() hum.WalkSpeed = savedWalkSpeed end) end
		savedWalkSpeed = nil
	end
	if noFlashEnabled then pcall(function() applyNoFlash(false) end) noFlashEnabled = false end
	if noSmokeEnabled then pcall(function() setNoSmoke(false) end) end
	for i = #connections, 1, -1 do
		pcall(function() connections[i]:Disconnect() end)
		connections[i] = nil
	end
	for player, obj in pairs(espObjects) do
		for _, drawing in pairs(obj) do
			if drawing then
				pcall(function() drawing.Visible = false end)
				pcall(function() drawing:Remove() end)
			end
		end
		espObjects[player] = nil
	end
	for _, obj in ipairs(drawObjects) do
		pcall(function() obj:Remove() end)
	end
	drawObjects = {}
	if watermarkGui then pcall(function() watermarkGui:Destroy() end) watermarkGui = nil end
	if watermarkScreenGui then pcall(function() watermarkScreenGui:Destroy() end) watermarkScreenGui = nil end
	if grenadeEspScreenGui then pcall(function() grenadeEspScreenGui:Destroy() end) grenadeEspScreenGui = nil end
	if introGuiRef then pcall(function() introGuiRef:Destroy() end) introGuiRef = nil end
	if drawGui then pcall(function() drawGui:Destroy() end) drawGui = nil end
	if screenGui then pcall(function() screenGui:Destroy() end) screenGui = nil end
end

if _G.ZeninInternalMenuCleanup ~= nil then pcall(_G.ZeninInternalMenuCleanup) end
_G.ZeninInternalMenuCleanup = cleanup

do
	local oldFolder = workspace:FindFirstChild("ZeninCustomModel")
	if oldFolder then pcall(function() oldFolder:Destroy() end) end
	local function getGuiParent()
		if gethui ~= nil then
			local ok, result = pcall(gethui)
			if ok and result ~= nil then return result end
		end
		local player = Players.LocalPlayer
		if player then return player:WaitForChild("PlayerGui") end
		return game:GetService("CoreGui")
	end
	local guiParent = getGuiParent()
	for _, name in ipairs({"ZeninInternalMenu", "ZeninIntro", "ZeninDrawLayer", "ZeninWatermarkGui", "ZeninGrenadeEsp", "ZeninTouchControls"}) do
		local old = guiParent:FindFirstChild(name)
		if old then pcall(function() old:Destroy() end) end
	end
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ZeninInternalMenu"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 999999
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	screenGui.Enabled = false
	if syn ~= nil and syn.protect_gui ~= nil then pcall(syn.protect_gui, screenGui) end
	local parented = pcall(function() screenGui.Parent = guiParent end)
	if not parented then pcall(function() screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end) end
	drawGui = Instance.new("ScreenGui")
	drawGui.Name = "ZeninDrawLayer"
	drawGui.ResetOnSpawn = false
	drawGui.IgnoreGuiInset = true
	drawGui.DisplayOrder = 999995
	drawGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	drawGui.Enabled = true
	if syn ~= nil and syn.protect_gui ~= nil then pcall(syn.protect_gui, drawGui) end
	pcall(function() drawGui.Parent = screenGui.Parent end)
end

local function buildUI()
	local main = Instance.new("Frame")
	main.Name = "Main"
	main.BackgroundColor3 = Color3.fromRGB(11, 11, 13)
	main.BorderSizePixel = 0
	main.AnchorPoint = Vector2.new(0.5, 0.5)
	main.Position = UDim2.fromScale(0.5, 0.5)
	main.Size = UDim2.fromOffset(560, 400)
	main.ClipsDescendants = true
	main.Parent = screenGui
	local configContent = nil
	local configStroke = nil
	local configTabActive = false
	local refreshConfigList = nil
	local selectConfigTab = nil
	local settingsContent = nil
	local settingsStroke = nil
	local settingsTabActive = false
	local selectSettingsTab = nil
	local scContent = nil
	local scStroke = nil
	local scTabActive = false
	local selectScTab = nil
	local toggleMenuFn = nil
	local palette = nil
	local activePicker = nil
	local paletteHue, paletteSat, paletteVal = 0, 1, 1
	local paletteDragMode = nil
	local refreshPalette = nil
	local togglePalette = nil
	local floatMenus = {}
	local strokes = {}
	local strokeTweens = {}
	local strokeVisible = {}
	do
		local menuScale = Instance.new("UIScale")
		menuScale.Name = "MenuScale"
		menuScale.Scale = uiTheme.scale
		menuScale.Parent = main
		uiTheme.menuScale = menuScale
		local mainCorner = Instance.new("UICorner")
		mainCorner.CornerRadius = UDim.new(0, 10)
		mainCorner.Parent = main
		local mainStroke = Instance.new("UIStroke")
		mainStroke.Color = Color3.fromRGB(32, 32, 36)
		mainStroke.Thickness = 1
		mainStroke.Parent = main
		local gradientFrame = Instance.new("Frame")
		gradientFrame.Name = "TopGradient"
		gradientFrame.BackgroundColor3 = uiTheme.accent
		gradientFrame.BorderSizePixel = 0
		gradientFrame.Position = UDim2.fromOffset(0, 0)
		gradientFrame.Size = UDim2.new(0.42, 40, 0, 46)
		gradientFrame.ZIndex = 1
		gradientFrame.Parent = main
		local gfc = Instance.new("UICorner")
		gfc.CornerRadius = UDim.new(0, 10)
		gfc.Parent = gradientFrame
		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, uiTheme.accent), ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))})
		gradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.58), NumberSequenceKeypoint.new(1, 0.94)})
		gradient.Rotation = 45
		gradient.Parent = gradientFrame
		local zLabel = Instance.new("TextLabel")
		zLabel.Text = "Z"
		zLabel.Font = Enum.Font.SourceSansBold
		zLabel.TextSize = 24
		zLabel.TextColor3 = uiTheme.accent
		zLabel.BackgroundTransparency = 1
		zLabel.Position = UDim2.fromOffset(12, 10)
		zLabel.Size = UDim2.fromOffset(22, 24)
		zLabel.TextXAlignment = Enum.TextXAlignment.Left
		zLabel.ZIndex = 3
		zLabel.Parent = main
		registerAccent(function()
			gradientFrame.BackgroundColor3 = uiTheme.accent
			gradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, uiTheme.accent), ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))})
			zLabel.TextColor3 = uiTheme.accent
		end)
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Text = "Zenin Internal"
		titleLabel.Font = Enum.Font.SourceSansBold
		titleLabel.TextSize = 18
		titleLabel.TextColor3 = Color3.fromRGB(228, 228, 228)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Position = UDim2.fromOffset(37, 10)
		titleLabel.Size = UDim2.fromOffset(190, 24)
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.ZIndex = 3
		titleLabel.Parent = main
		local line = Instance.new("Frame")
		line.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		line.BorderSizePixel = 0
		line.Position = UDim2.new(0, 14, 1, -56)
		line.Size = UDim2.new(1, -28, 0, 1)
		line.ZIndex = 2
		line.Parent = main
		local lg = Instance.new("UIGradient")
		lg.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)), ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 190, 190))})
		lg.Transparency = NumberSequence.new(0.55)
		lg.Parent = line
	end
	local function makeScrollContent(name, canvasHeight, visible)
		local frame = Instance.new("ScrollingFrame")
		frame.Name = name
		frame.BackgroundTransparency = 1
		frame.BorderSizePixel = 0
		frame.Position = UDim2.fromOffset(14, 52)
		frame.Size = UDim2.new(1, -28, 1, -116)
		frame.ZIndex = 2
		frame.Visible = visible
		frame.Parent = main
		frame.CanvasSize = UDim2.fromOffset(0, canvasHeight)
		frame.ScrollBarThickness = isTouchDevice and 6 or 4
		frame.ScrollBarImageColor3 = Color3.fromRGB(75, 75, 82)
		frame.ScrollBarImageTransparency = 0.15
		frame.ElasticBehavior = Enum.ElasticBehavior.Never
		frame.ScrollingDirection = Enum.ScrollingDirection.Y
		frame.AutomaticCanvasSize = Enum.AutomaticSize.None
		frame.CanvasPosition = Vector2.new(0, 0)
		return frame
	end
	local visualsContent = makeScrollContent("VisualsContent", 815, true)
	local aimContent = makeScrollContent("AimContent", 320, false)
	local miscContent = makeScrollContent("MiscContent", 380, false)
	scContent = makeScrollContent("SCContent", 120, false)
	local function createCheckbox(parent, posY, labelText, callback, configKey)
		local row = Instance.new("TextButton")
		row.Name = labelText
		row.Text = ""
		row.BackgroundTransparency = 1
		row.BorderSizePixel = 0
		row.Position = UDim2.fromOffset(10, posY)
		row.Size = UDim2.new(1, -20, 0, 22)
		row.AutoButtonColor = false
		row.Active = true
		row.ZIndex = 5
		row.Parent = parent
		local box = Instance.new("Frame")
		box.BackgroundColor3 = Color3.fromRGB(34, 34, 40)
		box.BorderSizePixel = 0
		box.Position = UDim2.fromOffset(0, 3)
		box.Size = UDim2.fromOffset(16, 16)
		box.ZIndex = 6
		box.Parent = row
		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(0, 4)
		bc.Parent = box
		local boxStroke = Instance.new("UIStroke")
		boxStroke.Color = Color3.fromRGB(58, 58, 66)
		boxStroke.Thickness = 1
		boxStroke.Parent = box
		local leg1 = Instance.new("Frame")
		leg1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		leg1.BackgroundTransparency = 1
		leg1.BorderSizePixel = 0
		leg1.AnchorPoint = Vector2.new(0.5, 0.5)
		leg1.Position = UDim2.fromOffset(5, 10)
		leg1.Size = UDim2.fromOffset(5, 2)
		leg1.Rotation = 45
		leg1.ZIndex = 7
		leg1.Parent = box
		local l1c = Instance.new("UICorner")
		l1c.CornerRadius = UDim.new(1, 0)
		l1c.Parent = leg1
		local leg2 = Instance.new("Frame")
		leg2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		leg2.BackgroundTransparency = 1
		leg2.BorderSizePixel = 0
		leg2.AnchorPoint = Vector2.new(0.5, 0.5)
		leg2.Position = UDim2.fromOffset(9.5, 8)
		leg2.Size = UDim2.fromOffset(9, 2)
		leg2.Rotation = -49
		leg2.ZIndex = 7
		leg2.Parent = box
		local l2c = Instance.new("UICorner")
		l2c.CornerRadius = UDim.new(1, 0)
		l2c.Parent = leg2
		local label = Instance.new("TextLabel")
		label.Text = labelText
		label.Font = Enum.Font.SourceSansBold
		label.TextSize = 14
		label.TextColor3 = Color3.fromRGB(200, 200, 205)
		label.BackgroundTransparency = 1
		label.Position = UDim2.fromOffset(24, 0)
		label.Size = UDim2.new(1, -24, 1, 0)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.ZIndex = 6
		label.Parent = row
		local state = false
		local function setState(newState, instant)
			state = newState
			local old = checkboxTweens[row]
			if old then
				for _, t in ipairs(old) do t:Cancel() end
				checkboxTweens[row] = nil
			end
			local targetBg = state and accentShade("fill") or Color3.fromRGB(34, 34, 40)
			local targetStroke = state and accentShade("bright") or Color3.fromRGB(58, 58, 66)
			local targetCheck = state and 0 or 1
			local targetText = state and Color3.fromRGB(235, 235, 238) or Color3.fromRGB(200, 200, 205)
			if instant then
				box.BackgroundColor3 = targetBg
				boxStroke.Color = targetStroke
				leg1.BackgroundTransparency = targetCheck
				leg2.BackgroundTransparency = targetCheck
				label.TextColor3 = targetText
			else
				local info = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				local tweens = {TweenService:Create(box, info, {BackgroundColor3 = targetBg}), TweenService:Create(boxStroke, info, {Color = targetStroke}), TweenService:Create(leg1, info, {BackgroundTransparency = targetCheck}), TweenService:Create(leg2, info, {BackgroundTransparency = targetCheck}), TweenService:Create(label, info, {TextColor3 = targetText})}
				checkboxTweens[row] = tweens
				for _, t in ipairs(tweens) do t:Play() end
			end
			callback(state)
		end
		registerAccent(function()
			if state then
				box.BackgroundColor3 = accentShade("fill")
				boxStroke.Color = accentShade("bright")
			end
		end)
		connect(row.MouseButton1Click, function() setState(not state, false) end)
		setState(false, true)
		if configKey then
			registerConfig(configKey, "bool", function() return state end, function(v) setState(v and true or false, true) end)
		end
		return setState
	end
	local function createSection(parent, titleText, height)
		local section = Instance.new("Frame")
		section.Name = titleText
		section.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
		section.BorderSizePixel = 0
		section.Position = UDim2.fromOffset(0, 0)
		section.Size = UDim2.fromOffset(260, height)
		section.ZIndex = 3
		section.Parent = parent
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = section
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(38, 38, 44)
		stroke.Thickness = 1
		stroke.Parent = section
		local title = Instance.new("TextLabel")
		title.Text = titleText
		title.Font = Enum.Font.SourceSansBold
		title.TextSize = 13
		title.TextColor3 = Color3.fromRGB(165, 165, 172)
		title.BackgroundTransparency = 1
		title.Position = UDim2.fromOffset(10, 7)
		title.Size = UDim2.fromOffset(160, 15)
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.ZIndex = 3
		title.Parent = section
		return section
	end
	local function closeFloatMenus(except)
		for _, m in ipairs(floatMenus) do
			if m ~= except then pcall(function() m.Visible = false end) end
		end
		paletteDragMode = nil
	end
	local function buildPalette()
		palette = Instance.new("Frame")
		palette.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
		palette.BorderSizePixel = 0
		palette.Size = UDim2.fromOffset(190, 152)
		palette.ZIndex = 30
		palette.Visible = false
		palette.Active = true
		palette.Parent = main
		table.insert(floatMenus, palette)
		local pc = Instance.new("UICorner")
		pc.CornerRadius = UDim.new(0, 8)
		pc.Parent = palette
		local ps = Instance.new("UIStroke")
		ps.Color = Color3.fromRGB(50, 50, 58)
		ps.Thickness = 1
		ps.Parent = palette
		local svHue = Instance.new("Frame")
		svHue.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		svHue.BorderSizePixel = 0
		svHue.Position = UDim2.fromOffset(10, 10)
		svHue.Size = UDim2.fromOffset(170, 110)
		svHue.ZIndex = 31
		svHue.Parent = palette
		local shc = Instance.new("UICorner")
		shc.CornerRadius = UDim.new(0, 4)
		shc.Parent = svHue
		local svWhite = Instance.new("Frame")
		svWhite.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		svWhite.BorderSizePixel = 0
		svWhite.Position = UDim2.fromOffset(10, 10)
		svWhite.Size = UDim2.fromOffset(170, 110)
		svWhite.ZIndex = 32
		svWhite.Parent = palette
		local swc = Instance.new("UICorner")
		swc.CornerRadius = UDim.new(0, 4)
		swc.Parent = svWhite
		local swg = Instance.new("UIGradient")
		swg.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
		swg.Parent = svWhite
		local svBlack = Instance.new("Frame")
		svBlack.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		svBlack.BorderSizePixel = 0
		svBlack.Position = UDim2.fromOffset(10, 10)
		svBlack.Size = UDim2.fromOffset(170, 110)
		svBlack.ZIndex = 33
		svBlack.Parent = palette
		local sbc = Instance.new("UICorner")
		sbc.CornerRadius = UDim.new(0, 4)
		sbc.Parent = svBlack
		local sbg = Instance.new("UIGradient")
		sbg.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
		sbg.Rotation = 90
		sbg.Parent = svBlack
		local svCursor = Instance.new("Frame")
		svCursor.BackgroundTransparency = 1
		svCursor.BorderSizePixel = 0
		svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
		svCursor.Position = UDim2.new(1, 0, 0, 0)
		svCursor.Size = UDim2.fromOffset(10, 10)
		svCursor.ZIndex = 34
		svCursor.Parent = svBlack
		local scc = Instance.new("UICorner")
		scc.CornerRadius = UDim.new(1, 0)
		scc.Parent = svCursor
		local scs = Instance.new("UIStroke")
		scs.Color = Color3.fromRGB(255, 255, 255)
		scs.Thickness = 1.5
		scs.Parent = svCursor
		local svHitbox = Instance.new("TextButton")
		svHitbox.Text = ""
		svHitbox.BackgroundTransparency = 1
		svHitbox.BorderSizePixel = 0
		svHitbox.Position = UDim2.fromOffset(10, 10)
		svHitbox.Size = UDim2.fromOffset(170, 110)
		svHitbox.AutoButtonColor = false
		svHitbox.Active = true
		svHitbox.ZIndex = 35
		svHitbox.Parent = palette
		local hueBar = Instance.new("Frame")
		hueBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		hueBar.BorderSizePixel = 0
		hueBar.Position = UDim2.fromOffset(10, 130)
		hueBar.Size = UDim2.fromOffset(170, 12)
		hueBar.ZIndex = 31
		hueBar.Parent = palette
		local hbc = Instance.new("UICorner")
		hbc.CornerRadius = UDim.new(1, 0)
		hbc.Parent = hueBar
		local hg = Instance.new("UIGradient")
		hg.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(1/6, Color3.fromRGB(255, 255, 0)), ColorSequenceKeypoint.new(2/6, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(3/6, Color3.fromRGB(0, 255, 255)), ColorSequenceKeypoint.new(4/6, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(5/6, Color3.fromRGB(255, 0, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))})
		hg.Parent = hueBar
		local hueCursor = Instance.new("Frame")
		hueCursor.BackgroundTransparency = 1
		hueCursor.BorderSizePixel = 0
		hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
		hueCursor.Position = UDim2.new(0, 0, 0.5, 0)
		hueCursor.Size = UDim2.fromOffset(8, 16)
		hueCursor.ZIndex = 34
		hueCursor.Parent = hueBar
		local hcc = Instance.new("UICorner")
		hcc.CornerRadius = UDim.new(0, 3)
		hcc.Parent = hueCursor
		local hcs = Instance.new("UIStroke")
		hcs.Color = Color3.fromRGB(255, 255, 255)
		hcs.Thickness = 1.5
		hcs.Parent = hueCursor
		local hueHitbox = Instance.new("TextButton")
		hueHitbox.Text = ""
		hueHitbox.BackgroundTransparency = 1
		hueHitbox.BorderSizePixel = 0
		hueHitbox.Position = UDim2.fromOffset(10, 124)
		hueHitbox.Size = UDim2.fromOffset(170, 24)
		hueHitbox.AutoButtonColor = false
		hueHitbox.Active = true
		hueHitbox.ZIndex = 35
		hueHitbox.Parent = palette
		refreshPalette = function()
			pcall(function()
				svHue.BackgroundColor3 = Color3.fromHSV(paletteHue, 1, 1)
				svCursor.Position = UDim2.new(paletteSat, 0, 1 - paletteVal, 0)
				hueCursor.Position = UDim2.new(paletteHue, 0, 0.5, 0)
			end)
			if activePicker then activePicker.setColor(Color3.fromHSV(paletteHue, paletteSat, paletteVal)) end
		end
		local function fromSV(pos)
			local ap, as = svHue.AbsolutePosition, svHue.AbsoluteSize
			if as.X <= 0 or as.Y <= 0 then return end
			paletteSat = math.clamp((pos.X - ap.X) / as.X, 0, 1)
			paletteVal = 1 - math.clamp((pos.Y - ap.Y) / as.Y, 0, 1)
			refreshPalette()
		end
		local function fromHue(pos)
			local ap, as = hueBar.AbsolutePosition, hueBar.AbsoluteSize
			if as.X <= 0 then return end
			paletteHue = math.clamp((pos.X - ap.X) / as.X, 0, 1)
			refreshPalette()
		end
		togglePalette = function(picker)
			if palette.Visible and activePicker == picker then
				palette.Visible = false
				paletteDragMode = nil
				return
			end
			closeFloatMenus(palette)
			activePicker = picker
			local h, s, v = picker.color:ToHSV()
			paletteHue, paletteSat, paletteVal = h, s, v
			refreshPalette()
			local scale = uiTheme.scale
			local bAbs, bSize = picker.button.AbsolutePosition, picker.button.AbsoluteSize
			local mAbs, mSize = main.AbsolutePosition, main.AbsoluteSize
			local pw, ph, pad = 190 * scale, 152 * scale, 8 * scale
			local x = bAbs.X - mAbs.X + bSize.X + pad
			local y = bAbs.Y - mAbs.Y - 6 * scale
			x = math.clamp(x, pad, math.max(pad, mSize.X - pw - pad))
			y = math.clamp(y, pad, math.max(pad, mSize.Y - ph - pad))
			palette.Position = UDim2.fromOffset(x / scale, y / scale)
			palette.Visible = true
		end
		connect(svHitbox.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				paletteDragMode = "sv"
				fromSV(input.Position)
			end
		end)
		connect(hueHitbox.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				paletteDragMode = "hue"
				fromHue(input.Position)
			end
		end)
		connect(UserInputService.InputChanged, function(input)
			if paletteDragMode and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				if paletteDragMode == "sv" then fromSV(input.Position)
				elseif paletteDragMode == "hue" then fromHue(input.Position) end
			end
		end)
		connect(UserInputService.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				paletteDragMode = nil
			end
		end)
	end
	buildPalette()
	for _, sf in ipairs({visualsContent, aimContent, miscContent, scContent}) do
		connect(sf:GetPropertyChangedSignal("CanvasPosition"), function() closeFloatMenus(nil) end)
	end
	local function createColorPicker(parent, posY, labelText, defaultColor, onChanged, configKey)
		local row = Instance.new("Frame")
		row.Name = labelText
		row.BackgroundTransparency = 1
		row.BorderSizePixel = 0
		row.Position = UDim2.fromOffset(10, posY)
		row.Size = UDim2.new(1, -20, 0, 22)
		row.ZIndex = 5
		row.Parent = parent
		local label = Instance.new("TextLabel")
		label.Text = labelText
		label.Font = Enum.Font.SourceSansBold
		label.TextSize = 14
		label.TextColor3 = Color3.fromRGB(200, 200, 205)
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, -28, 1, 0)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.ZIndex = 6
		label.Parent = row
		local button = Instance.new("TextButton")
		button.Text = ""
		button.BackgroundColor3 = defaultColor
		button.BorderSizePixel = 0
		button.AnchorPoint = Vector2.new(1, 0)
		button.Position = UDim2.new(1, 0, 0, 2)
		button.Size = UDim2.fromOffset(18, 18)
		button.AutoButtonColor = false
		button.Active = true
		button.ZIndex = 6
		button.Parent = row
		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(1, 0)
		bc.Parent = button
		local bs = Instance.new("UIStroke")
		bs.Color = Color3.fromRGB(58, 58, 66)
		bs.Thickness = 1
		bs.Parent = button
		local picker = {color = defaultColor, button = button}
		function picker.setColor(c)
			picker.color = c
			pcall(function() button.BackgroundColor3 = c end)
			onChanged(c)
		end
		connect(button.MouseButton1Click, function() togglePalette(picker) end)
		onChanged(defaultColor)
		if configKey then
			registerConfig(configKey, "color", function() return picker.color end, function(c) picker.setColor(c) end)
		end
		return picker
	end
	local function createSlider(parent, posY, labelText, minV, maxV, defaultV, onChanged, configKey)
		local row = Instance.new("Frame")
		row.Name = labelText
		row.BackgroundTransparency = 1
		row.BorderSizePixel = 0
		row.Position = UDim2.fromOffset(10, posY)
		row.Size = UDim2.new(1, -20, 0, 34)
		row.ZIndex = 5
		row.Parent = parent
		local label = Instance.new("TextLabel")
		label.Text = labelText
		label.Font = Enum.Font.SourceSansBold
		label.TextSize = 12
		label.TextColor3 = Color3.fromRGB(165, 165, 172)
		label.BackgroundTransparency = 1
		label.Position = UDim2.fromOffset(0, 0)
		label.Size = UDim2.new(1, -40, 0, 14)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.ZIndex = 6
		label.Parent = row
		local valueLabel = Instance.new("TextLabel")
		valueLabel.Text = tostring(defaultV)
		valueLabel.Font = Enum.Font.SourceSansBold
		valueLabel.TextSize = 12
		valueLabel.TextColor3 = Color3.fromRGB(235, 235, 238)
		valueLabel.BackgroundTransparency = 1
		valueLabel.Position = UDim2.new(1, -36, 0, 0)
		valueLabel.Size = UDim2.fromOffset(36, 14)
		valueLabel.TextXAlignment = Enum.TextXAlignment.Right
		valueLabel.ZIndex = 6
		valueLabel.Parent = row
		local track = Instance.new("Frame")
		track.BackgroundColor3 = Color3.fromRGB(34, 34, 40)
		track.BorderSizePixel = 0
		track.Position = UDim2.fromOffset(0, 22)
		track.Size = UDim2.new(1, 0, 0, 6)
		track.ZIndex = 6
		track.Parent = row
		local tc = Instance.new("UICorner")
		tc.CornerRadius = UDim.new(1, 0)
		tc.Parent = track
		local fill = Instance.new("Frame")
		fill.BackgroundColor3 = accentShade("fill")
		fill.BorderSizePixel = 0
		fill.Size = UDim2.new(0, 0, 1, 0)
		fill.ZIndex = 7
		fill.Parent = track
		local fc = Instance.new("UICorner")
		fc.CornerRadius = UDim.new(1, 0)
		fc.Parent = fill
		local knob = Instance.new("Frame")
		knob.BackgroundColor3 = accentShade("bright")
		knob.BorderSizePixel = 0
		knob.AnchorPoint = Vector2.new(0.5, 0.5)
		knob.Position = UDim2.new(0, 0, 0.5, 0)
		knob.Size = UDim2.fromOffset(14, 14)
		knob.ZIndex = 8
		knob.Parent = track
		local kc = Instance.new("UICorner")
		kc.CornerRadius = UDim.new(1, 0)
		kc.Parent = knob
		registerAccent(function()
			fill.BackgroundColor3 = accentShade("fill")
			knob.BackgroundColor3 = accentShade("bright")
		end)
		local hitbox = Instance.new("TextButton")
		hitbox.Text = ""
		hitbox.BackgroundTransparency = 1
		hitbox.BorderSizePixel = 0
		hitbox.Position = UDim2.fromOffset(0, 10)
		hitbox.Size = UDim2.new(1, 0, 0, 26)
		hitbox.AutoButtonColor = false
		hitbox.Active = true
		hitbox.ZIndex = 9
		hitbox.Parent = row
		local dragging = false
		local current = defaultV
		local function setVal(v, fire)
			v = math.clamp(math.floor(v + 0.5), minV, maxV)
			current = v
			local alpha = (v - minV) / (maxV - minV)
			pcall(function()
				fill.Size = UDim2.new(alpha, 0, 1, 0)
				knob.Position = UDim2.new(alpha, 0, 0.5, 0)
				valueLabel.Text = tostring(v)
			end)
			if fire then onChanged(v) end
		end
		local function fromInput(p)
			local ax, aw = track.AbsolutePosition.X, track.AbsoluteSize.X
			if aw <= 0 then return end
			setVal(minV + math.clamp((p.X - ax) / aw, 0, 1) * (maxV - minV), true)
		end
		connect(hitbox.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				fromInput(input.Position)
			end
		end)
		connect(UserInputService.InputChanged, function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				fromInput(input.Position)
			end
		end)
		connect(UserInputService.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		setVal(defaultV, false)
		if configKey then
			registerConfig(configKey, "num", function() return current end, function(v) setVal(tonumber(v) or defaultV, true) end)
		end
		return {row = row, label = label, valueLabel = valueLabel, track = track, fill = fill, knob = knob, setVal = setVal}
	end
	local function createDropdown(parent, posY, labelText, options, defaultOpt, onSelected, configKey)
		local row = Instance.new("Frame")
		row.Name = labelText
		row.BackgroundTransparency = 1
		row.BorderSizePixel = 0
		row.Position = UDim2.fromOffset(10, posY)
		row.Size = UDim2.new(1, -20, 0, 22)
		row.ZIndex = 5
		row.Parent = parent
		local label = Instance.new("TextLabel")
		label.Text = labelText
		label.Font = Enum.Font.SourceSansBold
		label.TextSize = 14
		label.TextColor3 = Color3.fromRGB(200, 200, 205)
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, -128, 1, 0)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.ZIndex = 6
		label.Parent = row
		local button = Instance.new("TextButton")
		button.Text = defaultOpt
		button.TextTruncate = Enum.TextTruncate.AtEnd
		button.BackgroundColor3 = Color3.fromRGB(34, 34, 40)
		button.BorderSizePixel = 0
		button.AnchorPoint = Vector2.new(1, 0)
		button.Position = UDim2.new(1, 0, 0, 0)
		button.Size = UDim2.fromOffset(120, 22)
		button.AutoButtonColor = false
		button.Active = true
		button.Font = Enum.Font.SourceSansBold
		button.TextSize = 13
		button.TextColor3 = Color3.fromRGB(220, 220, 225)
		button.ZIndex = 6
		button.Parent = row
		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(0, 6)
		bc.Parent = button
		local bs = Instance.new("UIStroke")
		bs.Color = Color3.fromRGB(58, 58, 66)
		bs.Thickness = 1
		bs.Parent = button
		local menuH = #options * 26 + 10
		local menu = Instance.new("Frame")
		menu.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
		menu.BorderSizePixel = 0
		menu.Size = UDim2.fromOffset(130, menuH)
		menu.ZIndex = 40
		menu.Visible = false
		menu.Active = true
		menu.Parent = main
		table.insert(floatMenus, menu)
		local mc = Instance.new("UICorner")
		mc.CornerRadius = UDim.new(0, 8)
		mc.Parent = menu
		local ms = Instance.new("UIStroke")
		ms.Color = Color3.fromRGB(50, 50, 58)
		ms.Thickness = 1
		ms.Parent = menu
		local current = defaultOpt
		local optButtons = {}
		local function refresh()
			for opt, btn in pairs(optButtons) do
				local sel = (opt == current)
				pcall(function()
					btn.BackgroundTransparency = sel and 0 or 1
					btn.TextColor3 = sel and accentShade("text") or Color3.fromRGB(200, 200, 205)
				end)
			end
		end
		registerAccent(refresh)
		for i, opt in ipairs(options) do
			local ob = Instance.new("TextButton")
			ob.Name = opt
			ob.Text = opt
			ob.BackgroundColor3 = Color3.fromRGB(34, 34, 40)
			ob.BackgroundTransparency = 1
			ob.BorderSizePixel = 0
			ob.Position = UDim2.fromOffset(5, 5 + (i - 1) * 26)
			ob.Size = UDim2.new(1, -10, 0, 24)
			ob.AutoButtonColor = false
			ob.Active = true
			ob.Font = Enum.Font.SourceSansBold
			ob.TextSize = 13
			ob.TextColor3 = Color3.fromRGB(200, 200, 205)
			ob.TextXAlignment = Enum.TextXAlignment.Left
			ob.ZIndex = 41
			ob.Parent = menu
			local oc = Instance.new("UICorner")
			oc.CornerRadius = UDim.new(0, 6)
			oc.Parent = ob
			local op = Instance.new("UIPadding")
			op.PaddingLeft = UDim.new(0, 8)
			op.Parent = ob
			optButtons[opt] = ob
			connect(ob.MouseButton1Click, function()
				menu.Visible = false
				if current ~= opt then
					current = opt
					button.Text = opt
					refresh()
					onSelected(opt)
				end
			end)
		end
		refresh()
		connect(button.MouseButton1Click, function()
			if menu.Visible then menu.Visible = false return end
			closeFloatMenus(menu)
			local scale = uiTheme.scale
			local bAbs, bSize = button.AbsolutePosition, button.AbsoluteSize
			local mAbs, mSize = main.AbsolutePosition, main.AbsoluteSize
			local mw, mh, pad = 130 * scale, menuH * scale, 8 * scale
			local x = bAbs.X - mAbs.X
			local y = bAbs.Y - mAbs.Y + bSize.Y + 4 * scale
			if y + mh > mSize.Y - pad then y = bAbs.Y - mAbs.Y - mh - 4 * scale end
			x = math.clamp(x, pad, math.max(pad, mSize.X - mw - pad))
			y = math.clamp(y, pad, math.max(pad, mSize.Y - mh - pad))
			menu.Position = UDim2.fromOffset(x / scale, y / scale)
			menu.Visible = true
		end)
		if configKey then
			registerConfig(configKey, "str", function() return current end, function(opt)
				for _, o in ipairs(options) do
					if o == opt then
						current = opt
						button.Text = opt
						refresh()
						onSelected(opt)
						return
					end
				end
			end)
		end
	end
	local function createMultiDropdown(parent, posY, labelText, options, stateTable, onChanged, configPrefix)
		local row = Instance.new("Frame")
		row.BackgroundTransparency = 1
		row.BorderSizePixel = 0
		row.Position = UDim2.fromOffset(10, posY)
		row.Size = UDim2.new(1, -20, 0, 22)
		row.ZIndex = 5
		row.Parent = parent
		local label = Instance.new("TextLabel")
		label.Text = labelText
		label.Font = Enum.Font.SourceSansBold
		label.TextSize = 14
		label.TextColor3 = Color3.fromRGB(200, 200, 205)
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, -128, 1, 0)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.ZIndex = 6
		label.Parent = row
		local button = Instance.new("TextButton")
		button.Text = "None"
		button.TextTruncate = Enum.TextTruncate.AtEnd
		button.BackgroundColor3 = Color3.fromRGB(34, 34, 40)
		button.BorderSizePixel = 0
		button.AnchorPoint = Vector2.new(1, 0)
		button.Position = UDim2.new(1, 0, 0, 0)
		button.Size = UDim2.fromOffset(120, 22)
		button.AutoButtonColor = false
		button.Active = true
		button.Font = Enum.Font.SourceSansBold
		button.TextSize = 13
		button.TextColor3 = Color3.fromRGB(220, 220, 225)
		button.ZIndex = 6
		button.Parent = row
		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(0, 6)
		bc.Parent = button
		local bs = Instance.new("UIStroke")
		bs.Color = Color3.fromRGB(58, 58, 66)
		bs.Thickness = 1
		bs.Parent = button
		local menuH = #options * 26 + 10
		local menu = Instance.new("Frame")
		menu.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
		menu.BorderSizePixel = 0
		menu.Size = UDim2.fromOffset(130, menuH)
		menu.ZIndex = 40
		menu.Visible = false
		menu.Active = true
		menu.Parent = main
		table.insert(floatMenus, menu)
		local mc = Instance.new("UICorner")
		mc.CornerRadius = UDim.new(0, 8)
		mc.Parent = menu
		local ms = Instance.new("UIStroke")
		ms.Color = Color3.fromRGB(50, 50, 58)
		ms.Thickness = 1
		ms.Parent = menu
		local optButtons = {}
		local function refresh()
			local selected = {}
			for _, opt in ipairs(options) do
				if stateTable[opt] then table.insert(selected, opt) end
				local btn = optButtons[opt]
				if btn then
					local sel = stateTable[opt] and true or false
					pcall(function()
						btn.BackgroundTransparency = sel and 0 or 1
						btn.TextColor3 = sel and accentShade("text") or Color3.fromRGB(200, 200, 205)
					end)
				end
			end
			local text = "None"
			if #selected == #options then text = "All"
			elseif #selected > 0 then text = table.concat(selected, ", ") end
			pcall(function() button.Text = text end)
		end
		registerAccent(refresh)
		for i, opt in ipairs(options) do
			local ob = Instance.new("TextButton")
			ob.Text = opt
			ob.BackgroundColor3 = Color3.fromRGB(34, 34, 40)
			ob.BackgroundTransparency = 1
			ob.BorderSizePixel = 0
			ob.Position = UDim2.fromOffset(5, 5 + (i - 1) * 26)
			ob.Size = UDim2.new(1, -10, 0, 24)
			ob.AutoButtonColor = false
			ob.Active = true
			ob.Font = Enum.Font.SourceSansBold
			ob.TextSize = 13
			ob.TextColor3 = Color3.fromRGB(200, 200, 205)
			ob.TextXAlignment = Enum.TextXAlignment.Left
			ob.ZIndex = 41
			ob.Parent = menu
			local oc = Instance.new("UICorner")
			oc.CornerRadius = UDim.new(0, 6)
			oc.Parent = ob
			local op = Instance.new("UIPadding")
			op.PaddingLeft = UDim.new(0, 8)
			op.Parent = ob
			optButtons[opt] = ob
			connect(ob.MouseButton1Click, function()
				stateTable[opt] = not stateTable[opt]
				refresh()
				if onChanged then onChanged(opt, stateTable[opt]) end
			end)
			if configPrefix then
				registerConfig(configPrefix .. opt, "bool", function() return stateTable[opt] and true or false end, function(v)
					stateTable[opt] = v and true or false
					refresh()
					if onChanged then onChanged(opt, stateTable[opt]) end
				end)
			end
		end
		refresh()
		connect(button.MouseButton1Click, function()
			if menu.Visible then menu.Visible = false return end
			closeFloatMenus(menu)
			local scale = uiTheme.scale
			local bAbs, bSize = button.AbsolutePosition, button.AbsoluteSize
			local mAbs, mSize = main.AbsolutePosition, main.AbsoluteSize
			local mw, mh, pad = 130 * scale, menuH * scale, 8 * scale
			local x = bAbs.X - mAbs.X
			local y = bAbs.Y - mAbs.Y + bSize.Y + 4 * scale
			if y + mh > mSize.Y - pad then y = bAbs.Y - mAbs.Y - mh - 4 * scale end
			x = math.clamp(x, pad, math.max(pad, mSize.X - mw - pad))
			y = math.clamp(y, pad, math.max(pad, mSize.Y - mh - pad))
			menu.Position = UDim2.fromOffset(x / scale, y / scale)
			menu.Visible = true
		end)
	end
	do
		local espSection = createSection(visualsContent, "ESP", 322)
		createCheckbox(espSection, 30, "Enable", function(s) espEnabled = s end, "espEnable")
		createCheckbox(espSection, 56, "Team Check", function(s) teamCheckEnabled = s end, "espTeamCheck")
		createCheckbox(espSection, 82, "Box", function(s) espBoxEnabled = s end, "espBox")
		createColorPicker(espSection, 108, "Box Color", boxColor, function(c) boxColor = c end, "espBoxColor")
		createCheckbox(espSection, 134, "Names", function(s) espNamesEnabled = s end, "espNames")
		createCheckbox(espSection, 160, "Skeleton", function(s) espSkeletonEnabled = s end, "espSkeleton")
		createColorPicker(espSection, 186, "Skeleton Color", skeletonColor, function(c) skeletonColor = c end, "espSkeletonColor")
		createCheckbox(espSection, 212, "Flags", function(s) flagsEnabled = s end, "espFlags")
		createMultiDropdown(espSection, 238, "Flags Options", {"ForceField", "Money", "Ping"}, flagOptions, nil, "flag")
		createCheckbox(espSection, 264, "Weapon Name", function(s) espWeaponEnabled = s end, "espWeapon")
		createCheckbox(espSection, 290, "Fly Ragdoll", function(s) flyRagdollEnabled = s end, "espFlyRagdoll")
	end
	do
		local glowSection = createSection(visualsContent, "Glow", 192)
		glowSection.Position = UDim2.fromOffset(272, 0)
		createCheckbox(glowSection, 30, "Glow Enemy", function(s) glowEnemyEnabled = s end, "glowEnemy")
		createColorPicker(glowSection, 56, "Glow Enemy Colour", glowEnemyColor, function(c) glowEnemyColor = c end, "glowEnemyColor")
		createCheckbox(glowSection, 82, "Glow Enemy Full", function(s) glowFull.Enemy = s end, "glowEnemyFull")
		createCheckbox(glowSection, 108, "Local Glow", function(s) localGlowEnabled = s end, "localGlow")
		createColorPicker(glowSection, 134, "Local Glow Colour", localGlowColor, function(c) localGlowColor = c end, "localGlowColor")
		createCheckbox(glowSection, 160, "Local Glow Full", function(s) glowFull.Local = s end, "localGlowFull")
	end
	do
		local worldSection = createSection(visualsContent, "World", 166)
		worldSection.Position = UDim2.fromOffset(0, 334)
		createCheckbox(worldSection, 30, "World Ambience", function(s) setWorldAmbience(s) end, "worldAmbience")
		createCheckbox(worldSection, 56, "Full Ambience", function(s) setFullAmbience(s) end, "fullAmbience")
		createColorPicker(worldSection, 82, "World Color", worldColor, function(c) worldColor = c end, "worldColor")
		createDropdown(worldSection, 108, "Sky", {"Twilight", "Classic Night", "Red Day", "None"}, skyOption, function(o) skyOption = o applySky(o) end, "sky")
		createCheckbox(worldSection, 134, "Bullet Traccers", function(s) setBulletTracers(s) end, "bulletTracers")
	end
	do
		local aimSection = createSection(aimContent, "Aimbot", 306)
		createCheckbox(aimSection, 30, "Enable", function(s) aimEnabled = s end, "aimEnable")
		createDropdown(aimSection, 56, "Bone", {"Head", "Torso", "Both"}, aimBoneMode, function(o) aimBoneMode = o end, "aimBone")
		createSlider(aimSection, 82, "FOV", 5, 360, aimFOV, function(v) aimFOV = v end, "aimFOV")
		createColorPicker(aimSection, 120, "FOV Color", aimFOVColor, function(c) aimFOVColor = c end, "aimFOVColor")
		createCheckbox(aimSection, 146, "Team Check", function(s) aimTeamCheck = s end, "aimTeamCheck")
		createCheckbox(aimSection, 172, "ForceField Check", function(s) aimForceFieldCheck = s end, "aimForceFieldCheck")
		createSlider(aimSection, 198, "Speed", 1, 10, aimSpeed, function(v) aimSpeed = v end, "aimSpeed")
		createSlider(aimSection, 236, "Smooth", 0, 10, aimSmooth, function(v) aimSmooth = v end, "aimSmooth")
		createCheckbox(aimSection, 274, "Wall Check", function(s) aimWallCheck = s end, "aimWallCheck")
		pcall(function()
			local c = DrawLib.new("Circle")
			c.Filled = false
			c.Thickness = 1.5
			c.Transparency = 1
			c.Visible = false
			pcall(function() c.NumSides = 64 end)
			pcall(function() c.ZIndex = 1 end)
			aimFOVCircle = c
		end)
		local antiSection = createSection(aimContent, "Anti-Aim", 140)
		antiSection.Position = UDim2.fromOffset(272, 0)
		createCheckbox(antiSection, 30, "Enable", function(s) antiAimEnabled = s end, "antiEnable")
		createDropdown(antiSection, 56, "Yaw", {"Left", "Right", "Forward", "Backward", "None"}, antiYaw, function(o) antiYaw = o end, "antiYaw")
		createDropdown(antiSection, 82, "Yaw Mode", {"At Camera", "At Targets"}, antiYawMode, function(o) antiYawMode = o end, "antiYawMode")
		createCheckbox(antiSection, 108, "Spinning", function(s) antiSpinEnabled = s end, "antiSpin")
	end
	local function setFly(state)
		flyEnabled = state
		if state then
			local char = Players.LocalPlayer and Players.LocalPlayer.Character
			if char then setupFly(char) end
		else
			stopFly()
		end
	end
	local function setNoclip(state)
		noclipEnabled = state
		if not state then restoreNoclip() end
	end
	local function setAutoStrafer(state)
		autoStraferEnabled = state
		local char = Players.LocalPlayer and Players.LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if state then
			if hum then savedWalkSpeed = hum.WalkSpeed end
		else
			if hum and savedWalkSpeed ~= nil then pcall(function() hum.WalkSpeed = savedWalkSpeed end) end
			savedWalkSpeed = nil
		end
	end
	do
		local lpSection = createSection(miscContent, "L. Player", 264)
		createCheckbox(lpSection, 30, "Fly", function(s) setFly(s) end, "fly")
		createCheckbox(lpSection, 56, "Noclip", function(s) setNoclip(s) end, "noclip")
		createCheckbox(lpSection, 82, "Auto Strafer", function(s) setAutoStrafer(s) end, "autoStrafer")
		createCheckbox(lpSection, 108, "Fast Stop", function(s)
			fastStopEnabled = s
			if not s then
				fastStopActive = false
				local char = Players.LocalPlayer and Players.LocalPlayer.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if hum then pcall(function() hum.WalkSpeed = 16 end) end
			end
		end, "fastStop")
		createSlider(lpSection, 134, "Strafe Speed", 18, 85, strafeSpeed, function(v) strafeSpeed = v end, "strafeSpeed")
		createDropdown(lpSection, 176, "Custom Model", {"None", "Patriot", "FPV Drone", "Block", "Putin"}, customModelOption, function(o) setCustomModel(o) end, "customModel")
		createCheckbox(lpSection, 206, "No Smoke", function(s) setNoSmoke(s) end, "noSmoke")
		createCheckbox(lpSection, 232, "No Flash", function(s) noFlashEnabled = s applyNoFlash(s) end, "noFlash")
		local rageSection = createSection(miscContent, "Rage", 172)
		rageSection.Position = UDim2.fromOffset(272, 0)
		createCheckbox(rageSection, 30, "Infinite Ammo", function(s) setInfiniteAmmo(s) end, "infiniteAmmo")
		createCheckbox(rageSection, 56, "Rapid Fire", function(s) setRapidFire(s) end, "rapidFire")
		createCheckbox(rageSection, 82, "Remove Recoil", function(s) setRemoveRecoil(s) end, "removeRecoil")
		createCheckbox(rageSection, 108, "Remove Spread", function(s) setRemoveSpread(s) end, "removeSpread")
		createCheckbox(rageSection, 134, "Fast Crouch", function(s) setFastCrouch(s) end, "fastCrouch")
	end
	local function buildCameraSection()
		local cameraSection = createSection(miscContent, "Camera", 88)
		cameraSection.Position = UDim2.fromOffset(272, 194)
		applyCameraSettings = function()
			if not thirdpersonEnabled then return end
			local lp = Players.LocalPlayer
			if not lp then return end
			applyingCamera = true
			pcall(function()
				if lp.CameraMode ~= Enum.CameraMode.Classic then lp.CameraMode = Enum.CameraMode.Classic end
				if lp.CameraMaxZoomDistance ~= zoomValue then lp.CameraMaxZoomDistance = zoomValue end
				if lp.CameraMinZoomDistance ~= zoomValue then lp.CameraMinZoomDistance = zoomValue end
				if lp.CameraMaxZoomDistance ~= zoomValue then lp.CameraMaxZoomDistance = zoomValue end
			end)
			applyingCamera = false
		end
		local thirdSlider = createSlider(cameraSection, 84, "Distance", 5, 35, zoomValue, function(v)
			zoomValue = v
			applyCameraSettings()
		end, "cameraDistance")
		local fovSlider = createSlider(cameraSection, 84, "FOV", 30, 120, cameraFovValue, function(v)
			cameraFovValue = v
			forceCameraFov()
		end, "cameraFov")
		local function prep(ctrl)
			ctrl.row.Visible = false
			pcall(function()
				ctrl.label.TextTransparency = 1
				ctrl.valueLabel.TextTransparency = 1
				ctrl.track.BackgroundTransparency = 1
				ctrl.fill.BackgroundTransparency = 1
				ctrl.knob.BackgroundTransparency = 1
			end)
		end
		prep(thirdSlider)
		prep(fovSlider)
		local fadeTweens, fadeTokens = {}, {}
		local function setSliderVisible(ctrl, visible, instant)
			local token = (fadeTokens[ctrl] or 0) + 1
			fadeTokens[ctrl] = token
			local old = fadeTweens[ctrl]
			if old then
				for _, t in ipairs(old) do pcall(function() t:Cancel() end) end
				fadeTweens[ctrl] = nil
			end
			local targets = {
				{obj = ctrl.label, prop = "TextTransparency"},
				{obj = ctrl.valueLabel, prop = "TextTransparency"},
				{obj = ctrl.track, prop = "BackgroundTransparency"},
				{obj = ctrl.fill, prop = "BackgroundTransparency"},
				{obj = ctrl.knob, prop = "BackgroundTransparency"}
			}
			local target = visible and 0 or 1
			if visible then ctrl.row.Visible = true end
			if instant then
				for _, e in ipairs(targets) do pcall(function() e.obj[e.prop] = target end) end
				ctrl.row.Visible = visible
			else
				local info = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				local list = {}
				for _, e in ipairs(targets) do
					local ok, t = pcall(function() return TweenService:Create(e.obj, info, {[e.prop] = target}) end)
					if ok and t then table.insert(list, t) t:Play() end
				end
				fadeTweens[ctrl] = list
				if not visible then
					task.delay(0.24, function()
						if fadeTokens[ctrl] == token and ctrl.row and ctrl.row.Parent then ctrl.row.Visible = false end
					end)
				end
			end
		end
		local sectionTween = nil
		updateCameraSection = function(instant)
			local y, n = 84, 0
			if thirdpersonEnabled then
				pcall(function() thirdSlider.row.Position = UDim2.fromOffset(10, y) end)
				y = y + 38
				n = n + 1
			end
			if cameraFovEnabled then
				pcall(function() fovSlider.row.Position = UDim2.fromOffset(10, y) end)
				y = y + 38
				n = n + 1
			end
			local targetSize = UDim2.fromOffset(260, 88 + 38 * n)
			if sectionTween then pcall(function() sectionTween:Cancel() end) sectionTween = nil end
			if instant then
				cameraSection.Size = targetSize
			else
				local ok, t = pcall(function()
					return TweenService:Create(cameraSection, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize})
				end)
				if ok and t then sectionTween = t t:Play() end
			end
			setSliderVisible(thirdSlider, thirdpersonEnabled, instant)
			setSliderVisible(fovSlider, cameraFovEnabled, instant)
		end
		local function setThirdperson(state)
			thirdpersonEnabled = state
			local lp = Players.LocalPlayer
			if state then
				if lp and savedCameraMode == nil then
					savedCameraMode = lp.CameraMode
					savedMinZoom = lp.CameraMinZoomDistance
					savedMaxZoom = lp.CameraMaxZoomDistance
				end
				applyCameraSettings()
			else
				if lp and savedCameraMode ~= nil then
					applyingCamera = true
					pcall(function()
						lp.CameraMode = savedCameraMode
						lp.CameraMinZoomDistance = savedMinZoom
						lp.CameraMaxZoomDistance = savedMaxZoom
					end)
					applyingCamera = false
				end
				savedCameraMode, savedMinZoom, savedMaxZoom = nil, nil, nil
			end
			updateCameraSection(false)
		end
		createCheckbox(cameraSection, 30, "Thirdperson", function(s) setThirdperson(s) end, "thirdperson")
		createCheckbox(cameraSection, 56, "FOV Camera", function(s) setCameraFovEnabled(s) end, "cameraFovEnable")
		for _, camProp in ipairs({"CameraMode", "CameraMinZoomDistance", "CameraMaxZoomDistance"}) do
			connect(Players.LocalPlayer:GetPropertyChangedSignal(camProp), function()
				if thirdpersonEnabled and not applyingCamera then applyCameraSettings() end
			end)
		end
		updateCameraSection(true)
	end
	buildCameraSection()
	local function applyStroke(stroke, visible, instant)
		if not stroke then return end
		strokeVisible[stroke] = visible
		local oldTween = strokeTweens[stroke]
		if oldTween then oldTween:Cancel() strokeTweens[stroke] = nil end
		if instant then
			stroke.Transparency = visible and 0 or 1
		else
			local tween = TweenService:Create(stroke, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = visible and 0 or 1})
			strokeTweens[stroke] = tween
			tween:Play()
		end
	end
	local function buildTabs()
		local tabsFrame = Instance.new("Frame")
		tabsFrame.BackgroundTransparency = 1
		tabsFrame.Position = UDim2.new(0, 14, 1, -44)
		tabsFrame.Size = UDim2.new(1, -28, 0, 30)
		tabsFrame.ZIndex = 2
		tabsFrame.Parent = main
		local tabList = Instance.new("UIListLayout")
		tabList.FillDirection = Enum.FillDirection.Horizontal
		tabList.Padding = UDim.new(0, 8)
		tabList.SortOrder = Enum.SortOrder.LayoutOrder
		tabList.Parent = tabsFrame
		local tabData = {{name = "Visuals", letter = "V"}, {name = "Aimbot", letter = "A"}, {name = "Misc", letter = "M"}}
		local buttons = {}
		for i, data in ipairs(tabData) do
			local button = Instance.new("TextButton")
			button.Name = data.name
			button.Text = data.letter
			button.BackgroundColor3 = Color3.fromRGB(23, 23, 26)
			button.BorderSizePixel = 0
			button.Size = UDim2.fromOffset(72, 28)
			button.AutoButtonColor = false
			button.Active = true
			button.Font = Enum.Font.SourceSansBold
			button.TextSize = 16
			button.TextColor3 = Color3.fromRGB(198, 198, 198)
			button.LayoutOrder = i
			button.ZIndex = 5
			button.Parent = tabsFrame
			local bc = Instance.new("UICorner")
			bc.CornerRadius = UDim.new(0, 7)
			bc.Parent = button
			local stroke = Instance.new("UIStroke")
			stroke.Color = uiTheme.accent
			stroke.Thickness = 1.5
			stroke.Transparency = 1
			stroke.Parent = button
			buttons[i] = button
			strokes[i] = stroke
		end
		registerAccent(function()
			for _, s in ipairs(strokes) do pcall(function() s.Color = uiTheme.accent end) end
		end)
		for i, stroke in ipairs(strokes) do applyStroke(stroke, i == 1, true) end
		local activeTabIndex = 1
		local function hideExtraTabs()
			if configTabActive then
				configTabActive = false
				if configContent then configContent.Visible = false end
				if configStroke then applyStroke(configStroke, false, false) end
			end
			if settingsTabActive then
				settingsTabActive = false
				if settingsContent then settingsContent.Visible = false end
				if settingsStroke then applyStroke(settingsStroke, false, false) end
			end
			if scTabActive then
				scTabActive = false
				if scContent then scContent.Visible = false end
				if scStroke then applyStroke(scStroke, false, false) end
			end
		end
		local function hideAllContent()
			visualsContent.Visible = false
			aimContent.Visible = false
			miscContent.Visible = false
			if scContent then scContent.Visible = false end
			if settingsContent then settingsContent.Visible = false end
			if configContent then configContent.Visible = false end
		end
		local function selectTab(index)
			hideExtraTabs()
			if activeTabIndex ~= index then
				applyStroke(strokes[activeTabIndex], false, false)
				applyStroke(strokes[index], true, false)
				activeTabIndex = index
			else
				applyStroke(strokes[index], true, false)
			end
			visualsContent.Visible = (index == 1)
			aimContent.Visible = (index == 2)
			miscContent.Visible = (index == 3)
			closeFloatMenus(nil)
		end
		selectScTab = function()
			if scTabActive then return end
			hideExtraTabs()
			scTabActive = true
			applyStroke(strokes[activeTabIndex], false, false)
			if scStroke then applyStroke(scStroke, true, false) end
			hideAllContent()
			if scContent then scContent.Visible = true end
			closeFloatMenus(nil)
		end
		selectConfigTab = function()
			if configTabActive then return end
			hideExtraTabs()
			configTabActive = true
			applyStroke(strokes[activeTabIndex], false, false)
			if configStroke then applyStroke(configStroke, true, false) end
			hideAllContent()
			if configContent then configContent.Visible = true end
			if refreshConfigList then refreshConfigList() end
			closeFloatMenus(nil)
		end
		selectSettingsTab = function()
			if settingsTabActive then return end
			hideExtraTabs()
			settingsTabActive = true
			applyStroke(strokes[activeTabIndex], false, false)
			if settingsStroke then applyStroke(settingsStroke, true, false) end
			hideAllContent()
			if settingsContent then settingsContent.Visible = true end
			closeFloatMenus(nil)
		end
		for i, button in ipairs(buttons) do
			connect(button.MouseButton1Click, function() selectTab(i) end)
		end
	end
	buildTabs()
	local function buildDrag()
		local dragging = false
		local dragStart = nil
		local startPos = nil
		local lastToggleTime = 0
		local function toggleMenu()
			if not introFinished then return end
			local now = os.clock()
			if now - lastToggleTime < 0.12 then return end
			lastToggleTime = now
			screenGui.Enabled = not screenGui.Enabled
			if not screenGui.Enabled then
				dragging = false
				closeFloatMenus(nil)
				for _, stroke in ipairs(strokes) do applyStroke(stroke, strokeVisible[stroke] == true, true) end
				if configStroke then applyStroke(configStroke, strokeVisible[configStroke] == true, true) end
				if settingsStroke then applyStroke(settingsStroke, strokeVisible[settingsStroke] == true, true) end
				if scStroke then applyStroke(scStroke, strokeVisible[scStroke] == true, true) end
				if updateCameraSection then updateCameraSection(true) end
			end
		end
		toggleMenuFn = toggleMenu
		local dragFrame = Instance.new("TextButton")
		dragFrame.Text = ""
		dragFrame.BackgroundTransparency = 1
		dragFrame.BorderSizePixel = 0
		dragFrame.Position = UDim2.fromOffset(0, 0)
		dragFrame.Size = UDim2.new(1, 0, 0, 46)
		dragFrame.AutoButtonColor = false
		dragFrame.Active = true
		dragFrame.ZIndex = 4
		dragFrame.Parent = main
		connect(dragFrame.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = main.Position
			end
		end)
		connect(UserInputService.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		connect(UserInputService.InputChanged, function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				if dragStart and startPos then
					local delta = input.Position - dragStart
					main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
				end
			end
		end)
		connect(UserInputService.InputBegan, function(input)
			if input.KeyCode == Enum.KeyCode.Insert then toggleMenu() end
		end)
		if not isTouchDevice then
			local insertWasDown = false
			connect(RunService.Heartbeat, function()
				local ok, isDown = pcall(function() return UserInputService:IsKeyDown(Enum.KeyCode.Insert) end)
				if ok and isDown and not insertWasDown then toggleMenu() end
				insertWasDown = ok and isDown or false
			end)
		end
	end
	buildDrag()
	do
		local localSection = createSection(visualsContent, "Local", 114)
		localSection.Position = UDim2.fromOffset(0, 512)
		createCheckbox(localSection, 30, "Glow Viewmodel", function(s) glowViewmodelEnabled = s end, "glowViewmodel")
		createColorPicker(localSection, 56, "Glow Viewmodel Color", glowViewmodelColor, function(c) glowViewmodelColor = c end, "glowViewmodelColor")
		createCheckbox(localSection, 82, "Glow V.Model Full", function(s) glowViewmodelFull = s end, "glowViewmodelFull")
	end
	do
		local fogSection = createSection(visualsContent, "Fog", 164)
		fogSection.Position = UDim2.fromOffset(0, 638)
		createCheckbox(fogSection, 30, "Enable Fog", function(s) setFogEnabled(s) end, "fogEnable")
		createSlider(fogSection, 56, "Fog Start", 10, 250, fogCfg.fogStart, function(v) fogCfg.fogStart = v applyFog() end, "fogStart")
		createSlider(fogSection, 94, "Fog End", 20, 250, fogCfg.fogEnd, function(v) fogCfg.fogEnd = v applyFog() end, "fogEnd")
		createColorPicker(fogSection, 132, "Fog Color", fogCfg.color, function(c) fogCfg.color = c applyFog() end, "fogColor")
	end
	do
		local lmSection = createSection(visualsContent, "Laser Mines", 182)
		lmSection.Position = UDim2.fromOffset(272, 204)
		createCheckbox(lmSection, 30, "Enable", function(s) laserMinesEnabled = s end, "laserEnable")
		createCheckbox(lmSection, 56, "Glow Laser Mine", function(s) laserMineGlowEnabled = s end, "laserGlow")
		createCheckbox(lmSection, 82, "Glow L.Mine Full", function(s) laserMineGlowFull = s end, "laserGlowFull")
		createColorPicker(lmSection, 108, "Glow L.Mine Color", laserMineGlowColor, function(c) laserMineGlowColor = c end, "laserGlowColor")
		createCheckbox(lmSection, 134, "Box L.Mine", function(s) laserMineBoxEnabled = s end, "laserBox")
		createColorPicker(lmSection, 160, "Box L.Mine Color", laserMineBoxColor, function(c) laserMineBoxColor = c end, "laserBoxColor")
	end
	do
		local grenSection = createSection(visualsContent, "Grenades", 322)
		grenSection.Position = UDim2.fromOffset(272, 398)
		createCheckbox(grenSection, 30, "Enable", function(s) grenadeCfg.enabled = s end, "grenEnable")
		createCheckbox(grenSection, 56, "HE Grenade Glow", function(s) grenadeCfg.heGlow = s end, "grenHe")
		createColorPicker(grenSection, 82, "HE Grenade Color", grenadeCfg.heColor, function(c) grenadeCfg.heColor = c end, "grenHeColor")
		createCheckbox(grenSection, 108, "Flashbang Glow", function(s) grenadeCfg.flashGlow = s end, "grenFlash")
		createColorPicker(grenSection, 134, "Flashbang Glow Color", grenadeCfg.flashColor, function(c) grenadeCfg.flashColor = c end, "grenFlashColor")
		createCheckbox(grenSection, 160, "Smoke Grenade Glow", function(s) grenadeCfg.smokeGlow = s end, "grenSmoke")
		createColorPicker(grenSection, 186, "Smoke Grenade Color", grenadeCfg.smokeColor, function(c) grenadeCfg.smokeColor = c end, "grenSmokeColor")
		createCheckbox(grenSection, 212, "Incendiary Glow", function(s) grenadeCfg.incGlow = s end, "grenInc")
		createColorPicker(grenSection, 238, "Incendiary Grenade Color", grenadeCfg.incColor, function(c) grenadeCfg.incColor = c end, "grenIncColor")
		createCheckbox(grenSection, 264, "Grenade ESP", function(s) grenadeCfg.esp = s end, "grenEsp")
		createCheckbox(grenSection, 290, "Grenade Red Warning", function(s) grenadeCfg.redWarning = s end, "grenRedWarning")
	end
	do
		local knifeSection = createSection(scContent, "Knifechanger", 92)
		knifeSection.Size = UDim2.fromOffset(532, 92)
		createCheckbox(knifeSection, 30, "Enable", function(s) knifeCfg.enabled = s applyKnife() end, "knifeEnable")
		createDropdown(knifeSection, 56, "Knife Type", {"None", "Karambit", "Butterfly", "Skeleton", "M9 Bayonet"}, knifeCfg.option, function(o) knifeCfg.option = o applyKnife() end, "knifeType")
		local scTabButton = Instance.new("TextButton")
		scTabButton.Text = "SC"
		scTabButton.BackgroundColor3 = Color3.fromRGB(23, 23, 26)
		scTabButton.BorderSizePixel = 0
		scTabButton.AnchorPoint = Vector2.new(1, 1)
		scTabButton.Position = UDim2.new(1, -174, 1, -14)
		scTabButton.Size = UDim2.fromOffset(72, 28)
		scTabButton.AutoButtonColor = false
		scTabButton.Active = true
		scTabButton.Font = Enum.Font.SourceSansBold
		scTabButton.TextSize = 16
		scTabButton.TextColor3 = Color3.fromRGB(198, 198, 198)
		scTabButton.ZIndex = 5
		scTabButton.Parent = main
		local sc = Instance.new("UICorner")
		sc.CornerRadius = UDim.new(0, 7)
		sc.Parent = scTabButton
		scStroke = Instance.new("UIStroke")
		scStroke.Color = uiTheme.accent
		scStroke.Thickness = 1.5
		scStroke.Transparency = 1
		scStroke.Parent = scTabButton
		registerAccent(function() scStroke.Color = uiTheme.accent end)
		connect(scTabButton.MouseButton1Click, function() selectScTab() end)
	end
	do
		settingsContent = makeScrollContent("SettingsContent", 170, false)
		local settingsSection = createSection(settingsContent, "Watermark", 56)
		watermarkSetState = createCheckbox(settingsSection, 30, "Watermark", function(s)
			watermarkEnabled = s
			if watermarkGui then watermarkGui.Visible = s end
		end, "watermark")
		local menuSection = createSection(settingsContent, "Menu", 88)
		menuSection.Position = UDim2.fromOffset(0, 68)
		createColorPicker(menuSection, 30, "Accent Color", uiTheme.accent, function(c) uiTheme.accent = c applyAccent() end, "accentColor")
		createDropdown(menuSection, 56, "UI Scale", {"0.5", "0.85", "1.0", "1.25", "1.35", "1.5", "2.0"}, tostring(uiTheme.scale), function(o)
			uiTheme.scale = tonumber(o) or 1
			applyUIScale()
			closeFloatMenus(nil)
		end, "uiScale")
		local wmScreen = Instance.new("ScreenGui")
		wmScreen.Name = "ZeninWatermarkGui"
		wmScreen.ResetOnSpawn = false
		wmScreen.DisplayOrder = 999998
		wmScreen.ZIndexBehavior = Enum.ZIndexBehavior.Global
		wmScreen.Enabled = true
		if syn ~= nil and syn.protect_gui ~= nil then pcall(syn.protect_gui, wmScreen) end
		pcall(function() wmScreen.Parent = screenGui.Parent end)
		watermarkScreenGui = wmScreen
		local container = Instance.new("TextButton")
		container.Name = "ZeninWatermark"
		container.Text = ""
		container.AutoButtonColor = false
		container.BackgroundTransparency = 1
		container.BorderSizePixel = 0
		container.ClipsDescendants = true
		container.Position = UDim2.fromOffset(8, 44)
		container.Size = UDim2.fromOffset(290, 30)
		container.Active = true
		container.ZIndex = 100
		container.Visible = watermarkEnabled
		container.Parent = wmScreen
		local wmScale = Instance.new("UIScale")
		wmScale.Scale = uiTheme.scale
		wmScale.Parent = container
		uiTheme.wmScale = wmScale
		local bg = Instance.new("Frame")
		bg.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
		bg.BorderSizePixel = 0
		bg.Size = UDim2.fromScale(1, 1)
		bg.ZIndex = 101
		bg.Parent = container
		local bgc = Instance.new("UICorner")
		bgc.CornerRadius = UDim.new(0, 15)
		bgc.Parent = bg
		local bgs = Instance.new("UIStroke")
		bgs.Color = Color3.fromRGB(45, 45, 50)
		bgs.Thickness = 1.5
		bgs.Parent = bg
		local content = Instance.new("Frame")
		content.BackgroundTransparency = 1
		content.Size = UDim2.fromScale(1, 1)
		content.ZIndex = 102
		content.Parent = container
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Padding = UDim.new(0, 8)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = content
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 12)
		pad.PaddingRight = UDim.new(0, 12)
		pad.Parent = content
		local function addText(name, text, size, color, width, order)
			local t = Instance.new("TextLabel")
			t.Name = name
			t.Text = text
			t.Font = Enum.Font.SourceSansBold
			t.TextSize = size
			t.TextColor3 = color
			t.BackgroundTransparency = 1
			t.Size = UDim2.fromOffset(width, 30)
			t.TextXAlignment = Enum.TextXAlignment.Left
			t.ZIndex = 103
			t.LayoutOrder = order
			t.Parent = content
			return t
		end
		local zLabel = addText("Z", "Z", 18, uiTheme.accent, 14, 1)
		local zGlow = Instance.new("UIStroke")
		zGlow.Color = uiTheme.accent
		zGlow.Thickness = 2
		zGlow.Transparency = 0.4
		zGlow.Parent = zLabel
		registerAccent(function()
			zLabel.TextColor3 = uiTheme.accent
			zGlow.Color = uiTheme.accent
		end)
		addText("Sep1", "|", 18, Color3.fromRGB(120, 120, 125), 6, 2)
		addText("Zenin", "zenin", 14, Color3.fromRGB(235, 235, 238), 40, 3)
		addText("Sep2", "|", 18, Color3.fromRGB(120, 120, 125), 6, 4)
		addText("Telegram", "t.me/zeninrbx", 14, Color3.fromRGB(235, 235, 238), 85, 5)
		addText("Sep3", "|", 18, Color3.fromRGB(120, 120, 125), 6, 6)
		addText("Internal", "internal", 14, Color3.fromRGB(235, 235, 238), 50, 7)
		local lastClick = 0
		connect(container.MouseButton1Click, function()
			local now = os.clock()
			if now - lastClick < 0.12 then return end
			lastClick = now
			if toggleMenuFn then toggleMenuFn() end
		end)
		watermarkGui = container
		local settingsTabButton = Instance.new("TextButton")
		settingsTabButton.Text = "S"
		settingsTabButton.BackgroundColor3 = Color3.fromRGB(23, 23, 26)
		settingsTabButton.BorderSizePixel = 0
		settingsTabButton.AnchorPoint = Vector2.new(1, 1)
		settingsTabButton.Position = UDim2.new(1, -94, 1, -14)
		settingsTabButton.Size = UDim2.fromOffset(72, 28)
		settingsTabButton.AutoButtonColor = false
		settingsTabButton.Active = true
		settingsTabButton.Font = Enum.Font.SourceSansBold
		settingsTabButton.TextSize = 16
		settingsTabButton.TextColor3 = Color3.fromRGB(198, 198, 198)
		settingsTabButton.ZIndex = 5
		settingsTabButton.Parent = main
		local scc = Instance.new("UICorner")
		scc.CornerRadius = UDim.new(0, 7)
		scc.Parent = settingsTabButton
		settingsStroke = Instance.new("UIStroke")
		settingsStroke.Color = uiTheme.accent
		settingsStroke.Thickness = 1.5
		settingsStroke.Transparency = 1
		settingsStroke.Parent = settingsTabButton
		registerAccent(function() settingsStroke.Color = uiTheme.accent end)
		connect(settingsTabButton.MouseButton1Click, function() selectSettingsTab() end)
	end
	do
		local CONFIG_FOLDER = "ZeninConfigs"
		local selectedConfigName = nil
		local function ensureConfigFolder()
			if isfolder then
				local ok, ex = pcall(isfolder, CONFIG_FOLDER)
				if ok and not ex and makefolder then pcall(makefolder, CONFIG_FOLDER) end
			end
		end
		local function configPath(name) return CONFIG_FOLDER .. "/" .. name .. ".json" end
		local function listConfigNames()
			local names = {}
			if listfiles then
				local ok, files = pcall(listfiles, CONFIG_FOLDER)
				if ok and files then
					for _, f in ipairs(files) do
						local base = f:match("([^/\\]+)$") or f
						if base:sub(-5) == ".json" then table.insert(names, base:sub(1, -6)) end
					end
				end
			end
			table.sort(names)
			return names
		end
		local function isNameTaken(n)
			if isfile then
				local ok, ex = pcall(isfile, configPath(n))
				if ok then return ex == true end
			end
			return false
		end
		local function buildConfigName()
			local t = os.date("*t")
			local base = string.format("Zenin-%02d%02d%02d", t.hour, t.min, t.year % 100)
			if not isNameTaken(base) then return base end
			local i = 2
			while isNameTaken(base .. "-" .. i) do i = i + 1 end
			return base .. "-" .. i
		end
		local function saveConfig(name)
			ensureConfigFolder()
			local data = {}
			for _, e in ipairs(configEntries) do
				local ok, v = pcall(e.get)
				if ok and v ~= nil then
					if e.kind == "color" then data[e.key] = {__c = true, r = v.R, g = v.G, b = v.B}
					else data[e.key] = v end
				end
			end
			local okJ, json = pcall(function() return HttpService:JSONEncode(data) end)
			if okJ and json and writefile then pcall(writefile, configPath(name), json) end
		end
		local function loadConfig(name)
			if not (readfile and isfile) then return end
			local p = configPath(name)
			local okE, ex = pcall(isfile, p)
			if not (okE and ex) then return end
			local okR, json = pcall(readfile, p)
			if not (okR and json) then return end
			local okD, data = pcall(function() return HttpService:JSONDecode(json) end)
			if not (okD and data) then return end
			for _, e in ipairs(configEntries) do
				local v = data[e.key]
				if v ~= nil then
					if e.kind == "color" and type(v) == "table" then
						pcall(e.set, Color3.new(tonumber(v.r) or 1, tonumber(v.g) or 1, tonumber(v.b) or 1))
					else
						pcall(e.set, v)
					end
				end
			end
		end
		local function deleteConfig(name)
			if delfile and isfile then
				local p = configPath(name)
				local okE, ex = pcall(isfile, p)
				if okE and ex then pcall(delfile, p) end
			end
		end
		configContent = Instance.new("Frame")
		configContent.BackgroundTransparency = 1
		configContent.BorderSizePixel = 0
		configContent.Position = UDim2.fromOffset(14, 52)
		configContent.Size = UDim2.new(1, -28, 1, -116)
		configContent.ZIndex = 2
		configContent.Visible = false
		configContent.Parent = main
		local leftList = Instance.new("ScrollingFrame")
		leftList.BackgroundTransparency = 1
		leftList.BorderSizePixel = 0
		leftList.Size = UDim2.new(0, 260, 1, 0)
		leftList.ZIndex = 3
		leftList.Parent = configContent
		leftList.CanvasSize = UDim2.fromOffset(0, 0)
		leftList.ScrollBarThickness = 4
		leftList.ScrollBarImageColor3 = Color3.fromRGB(75, 75, 82)
		leftList.ElasticBehavior = Enum.ElasticBehavior.Never
		leftList.ScrollingDirection = Enum.ScrollingDirection.Y
		leftList.AutomaticCanvasSize = Enum.AutomaticSize.None
		local leftLayout = Instance.new("UIListLayout")
		leftLayout.Padding = UDim.new(0, 6)
		leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
		leftLayout.Parent = leftList
		local rightCol = Instance.new("Frame")
		rightCol.BackgroundTransparency = 1
		rightCol.Position = UDim2.fromOffset(272, 0)
		rightCol.Size = UDim2.new(0, 260, 1, 0)
		rightCol.ZIndex = 3
		rightCol.Parent = configContent
		local function makeConfigButton(posY, text)
			local b = Instance.new("TextButton")
			b.Text = text
			b.BackgroundColor3 = Color3.fromRGB(34, 34, 40)
			b.BorderSizePixel = 0
			b.Position = UDim2.fromOffset(0, posY)
			b.Size = UDim2.new(1, 0, 0, 30)
			b.AutoButtonColor = false
			b.Active = true
			b.Font = Enum.Font.SourceSansBold
			b.TextSize = 14
			b.TextColor3 = Color3.fromRGB(220, 220, 225)
			b.ZIndex = 5
			b.Parent = rightCol
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 6)
			c.Parent = b
			local s = Instance.new("UIStroke")
			s.Color = Color3.fromRGB(58, 58, 66)
			s.Thickness = 1
			s.Parent = b
			return b
		end
		local createBtn = makeConfigButton(0, "Create")
		local updateBtn = makeConfigButton(38, "Update")
		local uploadBtn = makeConfigButton(76, "Upload")
		local deleteBtn = makeConfigButton(114, "Delete")
		refreshConfigList = function()
			for _, ch in ipairs(leftList:GetChildren()) do
				if ch:IsA("TextButton") then ch:Destroy() end
			end
			local names = listConfigNames()
			for i, name in ipairs(names) do
				local btn = Instance.new("TextButton")
				btn.Text = name
				btn.BackgroundColor3 = Color3.fromRGB(34, 34, 40)
				btn.BorderSizePixel = 0
				btn.Size = UDim2.new(1, -10, 0, 26)
				btn.AutoButtonColor = false
				btn.Active = true
				btn.Font = Enum.Font.SourceSansBold
				btn.TextSize = 13
				btn.TextColor3 = (name == selectedConfigName) and accentShade("bright") or Color3.fromRGB(235, 235, 238)
				btn.TextXAlignment = Enum.TextXAlignment.Left
				btn.ZIndex = 5
				btn.LayoutOrder = i
				btn.Parent = leftList
				local c = Instance.new("UICorner")
				c.CornerRadius = UDim.new(0, 6)
				c.Parent = btn
				local p2 = Instance.new("UIPadding")
				p2.PaddingLeft = UDim.new(0, 8)
				p2.Parent = btn
				connect(btn.MouseButton1Click, function()
					selectedConfigName = name
					refreshConfigList()
				end)
			end
			pcall(function() leftList.CanvasSize = UDim2.fromOffset(0, math.max(0, #names * 32)) end)
		end
		registerAccent(function() if refreshConfigList then refreshConfigList() end end)
		connect(createBtn.MouseButton1Click, function()
			local name = buildConfigName()
			saveConfig(name)
			selectedConfigName = name
			refreshConfigList()
		end)
		connect(updateBtn.MouseButton1Click, function() if selectedConfigName then saveConfig(selectedConfigName) end end)
		connect(uploadBtn.MouseButton1Click, function() if selectedConfigName then loadConfig(selectedConfigName) end end)
		connect(deleteBtn.MouseButton1Click, function()
			if selectedConfigName then
				deleteConfig(selectedConfigName)
				selectedConfigName = nil
				refreshConfigList()
			end
		end)
		local configTabButton = Instance.new("TextButton")
		configTabButton.Text = "C"
		configTabButton.BackgroundColor3 = Color3.fromRGB(23, 23, 26)
		configTabButton.BorderSizePixel = 0
		configTabButton.AnchorPoint = Vector2.new(1, 1)
		configTabButton.Position = UDim2.new(1, -14, 1, -14)
		configTabButton.Size = UDim2.fromOffset(72, 28)
		configTabButton.AutoButtonColor = false
		configTabButton.Active = true
		configTabButton.Font = Enum.Font.SourceSansBold
		configTabButton.TextSize = 16
		configTabButton.TextColor3 = Color3.fromRGB(198, 198, 198)
		configTabButton.ZIndex = 5
		configTabButton.Parent = main
		local cc = Instance.new("UICorner")
		cc.CornerRadius = UDim.new(0, 7)
		cc.Parent = configTabButton
		configStroke = Instance.new("UIStroke")
		configStroke.Color = uiTheme.accent
		configStroke.Thickness = 1.5
		configStroke.Transparency = 1
		configStroke.Parent = configTabButton
		registerAccent(function() configStroke.Color = uiTheme.accent end)
		connect(configTabButton.MouseButton1Click, function() selectConfigTab() end)
	end
	do
		local touchGui = Instance.new("ScreenGui")
		touchGui.Name = "ZeninTouchControls"
		touchGui.ResetOnSpawn = false
		touchGui.DisplayOrder = 999997
		touchGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
		touchGui.Enabled = true
		if syn ~= nil and syn.protect_gui ~= nil then pcall(syn.protect_gui, touchGui) end
		pcall(function() touchGui.Parent = screenGui.Parent end)
		local toggle = Instance.new("TextButton")
		toggle.Name = "ZeninToggle"
		toggle.Text = "Z"
		toggle.Font = Enum.Font.SourceSansBold
		toggle.TextSize = 26
		toggle.TextColor3 = uiTheme.accent
		toggle.BackgroundColor3 = Color3.fromRGB(14, 14, 17)
		toggle.BackgroundTransparency = 0.1
		toggle.BorderSizePixel = 0
		toggle.AutoButtonColor = false
		toggle.AnchorPoint = Vector2.new(1, 0)
		toggle.Position = UDim2.new(1, -12, 0, 90)
		toggle.Size = UDim2.fromOffset(52, 52)
		toggle.ZIndex = 200
		toggle.Parent = touchGui
		local tgc = Instance.new("UICorner")
		tgc.CornerRadius = UDim.new(1, 0)
		tgc.Parent = toggle
		local tgs = Instance.new("UIStroke")
		tgs.Color = uiTheme.accent
		tgs.Thickness = 2
		tgs.Transparency = 0.3
		tgs.Parent = toggle
		registerAccent(function()
			toggle.TextColor3 = uiTheme.accent
			tgs.Color = uiTheme.accent
		end)
		local tDrag, tStart, tPos, moved = false, nil, nil, false
		connect(toggle.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				tDrag = true
				moved = false
				tStart = input.Position
				tPos = toggle.Position
			end
		end)
		connect(UserInputService.InputChanged, function(input)
			if tDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local d = input.Position - tStart
				if math.abs(d.X) > 6 or math.abs(d.Y) > 6 then moved = true end
				toggle.Position = UDim2.new(tPos.X.Scale, tPos.X.Offset + d.X, tPos.Y.Scale, tPos.Y.Offset + d.Y)
			end
		end)
		connect(UserInputService.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				tDrag = false
			end
		end)
		connect(toggle.MouseButton1Click, function()
			if moved then return end
			if toggleMenuFn then toggleMenuFn() end
		end)
		local function holdButton(text, posY, onDown, onUp)
			local b = Instance.new("TextButton")
			b.Text = text
			b.Font = Enum.Font.SourceSansBold
			b.TextSize = 18
			b.TextColor3 = Color3.fromRGB(235, 235, 238)
			b.BackgroundColor3 = Color3.fromRGB(14, 14, 17)
			b.BackgroundTransparency = 0.15
			b.BorderSizePixel = 0
			b.AutoButtonColor = false
			b.AnchorPoint = Vector2.new(1, 0)
			b.Position = UDim2.new(1, -12, 0, posY)
			b.Size = UDim2.fromOffset(52, 46)
			b.Visible = false
			b.ZIndex = 200
			b.Parent = touchGui
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 12)
			c.Parent = b
			local s = Instance.new("UIStroke")
			s.Color = Color3.fromRGB(60, 60, 68)
			s.Thickness = 1.5
			s.Parent = b
			connect(b.InputBegan, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					onDown()
				end
			end)
			connect(b.InputEnded, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					onUp()
				end
			end)
			return b
		end
		local upBtn = holdButton("UP", 150, function() mobileUp = true end, function() mobileUp = false end)
		local downBtn = holdButton("DN", 202, function() mobileDown = true end, function() mobileDown = false end)
		connect(RunService.Heartbeat, function()
			local show = isTouchDevice and flyEnabled
			upBtn.Visible = show
			downBtn.Visible = show
			if not show then
				mobileUp = false
				mobileDown = false
			end
		end)
	end
end

buildUI()

local function startRuntime()
	local aimRadius = 0
	local spinX, spinY, spinZ = 0, 0, 0
	local function getTeamName(player)
		if not player then return nil end
		local ok, attr = pcall(function() return player:GetAttribute("Team") end)
		if ok and type(attr) == "string" then return attr end
		local ok2, team = pcall(function() return player.Team end)
		if ok2 and team ~= nil then
			if typeof(team) == "Instance" then return team.Name
			elseif type(team) == "string" then return team end
		end
		return nil
	end
	local function hasForceField(character)
		if not character then return false end
		local ok, ff = pcall(function() return character:FindFirstChildOfClass("ForceField") end)
		return ok and ff ~= nil
	end
	local cornerSigns = {}
	for x = -1, 1, 2 do
		for y = -1, 1, 2 do
			for z = -1, 1, 2 do
				table.insert(cornerSigns, Vector3.new(x, y, z))
			end
		end
	end
	local skeletonBones = {
		{"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
		{"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
		{"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
		{"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
		{"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
	}
	local function createEsp(player)
		local obj = {}
		pcall(function()
			local d = DrawLib.new("Square")
			d.Filled = false
			d.Color = Color3.new(1, 1, 1)
			d.Thickness = 1
			d.Transparency = 1
			d.Visible = false
			pcall(function() d.ZIndex = 2 end)
			obj.Box = d
		end)
		pcall(function()
			local bg = DrawLib.new("Square")
			bg.Filled = true
			bg.Color = Color3.new(0, 0, 0)
			bg.Thickness = 1
			bg.Transparency = 0.55
			bg.Visible = false
			pcall(function() bg.ZIndex = 1 end)
			obj.NameBg = bg
		end)
		pcall(function()
			local t = DrawLib.new("Text")
			t.Text = player.Name
			t.Size = 13
			t.Color = Color3.new(1, 1, 1)
			t.Center = false
			t.Outline = false
			t.Transparency = 1
			t.Visible = false
			pcall(function() t.Font = 2 end)
			pcall(function() t.ZIndex = 3 end)
			obj.Name = t
		end)
		pcall(function()
			local bg = DrawLib.new("Square")
			bg.Filled = true
			bg.Color = Color3.new(0, 0, 0)
			bg.Thickness = 1
			bg.Transparency = 0.55
			bg.Visible = false
			pcall(function() bg.ZIndex = 1 end)
			obj.WeaponBg = bg
		end)
		pcall(function()
			local t = DrawLib.new("Text")
			t.Text = ""
			t.Size = 13
			t.Color = Color3.new(1, 1, 1)
			t.Center = false
			t.Outline = false
			t.Transparency = 1
			t.Visible = false
			pcall(function() t.Font = 2 end)
			pcall(function() t.ZIndex = 3 end)
			obj.Weapon = t
		end)
		pcall(function()
			local t = DrawLib.new("Text")
			t.Text = "ForceField"
			t.Size = 13
			t.Color = Color3.fromRGB(0, 120, 255)
			t.Center = false
			t.Outline = true
			t.Transparency = 1
			t.Visible = false
			pcall(function() t.Font = 2 end)
			pcall(function() t.ZIndex = 3 end)
			obj.ForceField = t
		end)
		pcall(function()
			local t = DrawLib.new("Text")
			t.Text = ""
			t.Size = 13
			t.Color = Color3.fromRGB(60, 220, 90)
			t.Center = false
			t.Outline = true
			t.Transparency = 1
			t.Visible = false
			pcall(function() t.Font = 2 end)
			pcall(function() t.ZIndex = 3 end)
			obj.Money = t
		end)
		pcall(function()
			local t = DrawLib.new("Text")
			t.Text = ""
			t.Size = 13
			t.Color = Color3.new(1, 1, 1)
			t.Center = false
			t.Outline = true
			t.Transparency = 1
			t.Visible = false
			pcall(function() t.Font = 2 end)
			pcall(function() t.ZIndex = 3 end)
			obj.Ping = t
		end)
		for i = 1, #skeletonBones do
			pcall(function()
				local l = DrawLib.new("Line")
				l.Thickness = 1
				l.Color = Color3.new(1, 1, 1)
				l.Transparency = 1
				l.Visible = false
				pcall(function() l.ZIndex = 2 end)
				obj["Bone" .. i] = l
			end)
		end
		espObjects[player] = obj
		return obj
	end
	local function removeEsp(player)
		local obj = espObjects[player]
		if obj then
			for _, drawing in pairs(obj) do
				if drawing then
					pcall(function() drawing.Visible = false end)
					pcall(function() drawing:Remove() end)
				end
			end
		end
		espObjects[player] = nil
	end
	local function hideEsp(obj)
		for _, drawing in pairs(obj) do
			if drawing then pcall(function() drawing.Visible = false end) end
		end
	end
	local function createGlowHighlight(character, color, full)
		local ok, h = pcall(function()
			local highlight = Instance.new("Highlight")
			highlight.Name = "ZeninGlow"
			highlight.FillColor = color
			highlight.OutlineColor = color
			highlight.FillTransparency = full and 0 or 1
			highlight.OutlineTransparency = 0
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.Adornee = character
			highlight.Parent = character
			return highlight
		end)
		if ok then return h end
		return nil
	end
	local function destroyGlowHighlight(h)
		if h then pcall(function() h:Destroy() end) end
	end
	local function updateViewmodel()
		if not glowViewmodelEnabled then
			for key, h in pairs(viewmodelHighlights) do
				if h then pcall(function() h:Destroy() end) end
				viewmodelHighlights[key] = nil
			end
			return
		end
		local camera = workspace.CurrentCamera
		if not camera then return end
		local arms = camera:FindFirstChild("Arms")
		if not arms then return end
		local cssArms = arms:FindFirstChild("CSSArms")
		if not cssArms then return end
		local viewmodelParts = {
			{key = "LeftArm", name = "Left Arm"},
			{key = "RightArm", name = "Right Arm"},
			{key = "LGlove", name = "LGlove"},
			{key = "RGlove", name = "RGlove"}
		}
		for _, partInfo in ipairs(viewmodelParts) do
			local part = cssArms:FindFirstChild(partInfo.name)
			if part then
				local h = viewmodelHighlights[partInfo.key]
				if not h or h.Parent ~= part then
					if h then pcall(function() h:Destroy() end) end
					h = createGlowHighlight(part, glowViewmodelColor, glowViewmodelFull)
					viewmodelHighlights[partInfo.key] = h
				end
				if h then
					pcall(function()
						h.FillColor = glowViewmodelColor
						h.OutlineColor = glowViewmodelColor
						h.FillTransparency = glowViewmodelFull and 0 or 1
					end)
				end
			else
				local h = viewmodelHighlights[partInfo.key]
				if h then
					pcall(function() h:Destroy() end)
					viewmodelHighlights[partInfo.key] = nil
				end
			end
		end
	end
	local function updateLaserMines()
		if not laserMinesEnabled then
			for mine, h in pairs(laserMineHighlights) do
				if h then pcall(function() h:Destroy() end) end
				laserMineHighlights[mine] = nil
			end
			for mine, box in pairs(laserMineBoxes) do
				if box then pcall(function() box.Visible = false box:Remove() end) end
				laserMineBoxes[mine] = nil
			end
			return
		end
		local destroyable = workspace:FindFirstChild("Destroyable")
		if not destroyable then return end
		local allMines = {}
		for _, child in ipairs(destroyable:GetDescendants()) do
			if child.Name == "Laser Mine" then table.insert(allMines, child) end
		end
		if laserMineGlowEnabled then
			for _, mine in ipairs(allMines) do
				local h = laserMineHighlights[mine]
				if not h or h.Parent ~= mine then
					if h then pcall(function() h:Destroy() end) end
					h = createGlowHighlight(mine, laserMineGlowColor, laserMineGlowFull)
					laserMineHighlights[mine] = h
				end
				if h then
					pcall(function()
						h.FillColor = laserMineGlowColor
						h.OutlineColor = laserMineGlowColor
						h.FillTransparency = laserMineGlowFull and 0 or 1
					end)
				end
			end
			for mine, h in pairs(laserMineHighlights) do
				if mine.Parent == nil then
					if h then pcall(function() h:Destroy() end) end
					laserMineHighlights[mine] = nil
				end
			end
		else
			for mine, h in pairs(laserMineHighlights) do
				if h then pcall(function() h:Destroy() end) end
				laserMineHighlights[mine] = nil
			end
		end
		local camera = workspace.CurrentCamera
		if laserMineBoxEnabled and camera then
			for _, mine in ipairs(allMines) do
				local box = laserMineBoxes[mine]
				if not box then
					pcall(function()
						box = DrawLib.new("Square")
						box.Filled = false
						box.Thickness = 2
						box.Transparency = 1
						box.Visible = false
						pcall(function() box.ZIndex = 2 end)
						laserMineBoxes[mine] = box
					end)
				end
				if box then
					local cf, size = nil, nil
					if mine:IsA("Model") then
						local ok, okcf, oksize = pcall(mine.GetBoundingBox, mine)
						if ok and okcf and oksize then cf, size = okcf, oksize end
					elseif mine:IsA("BasePart") then
						cf, size = mine.CFrame, mine.Size
					end
					if cf and size then
						local half = size * 0.5
						local minX, minY = math.huge, math.huge
						local maxX, maxY = -math.huge, -math.huge
						local allFront = true
						for _, s in ipairs(cornerSigns) do
							local worldPos = cf:PointToWorldSpace(Vector3.new(half.X * s.X, half.Y * s.Y, half.Z * s.Z))
							local vp = camera:WorldToViewportPoint(worldPos)
							if vp.Z <= 0 then allFront = false break end
							if vp.X < minX then minX = vp.X end
							if vp.Y < minY then minY = vp.Y end
							if vp.X > maxX then maxX = vp.X end
							if vp.Y > maxY then maxY = vp.Y end
						end
						if allFront and maxX > minX and maxY > minY then
							pcall(function()
								box.Position = Vector2.new(minX, minY)
								box.Size = Vector2.new(maxX - minX, maxY - minY)
								box.Color = laserMineBoxColor
								box.Visible = true
							end)
						else
							pcall(function() box.Visible = false end)
						end
					else
						pcall(function() box.Visible = false end)
					end
				end
			end
			for mine, box in pairs(laserMineBoxes) do
				if mine.Parent == nil then
					if box then pcall(function() box.Visible = false box:Remove() end) end
					laserMineBoxes[mine] = nil
				end
			end
		else
			for mine, box in pairs(laserMineBoxes) do
				if box then pcall(function() box.Visible = false box:Remove() end) end
				laserMineBoxes[mine] = nil
			end
		end
	end
	local grenadeTypes = {["HE Grenade"] = "he", ["Flashbang"] = "flash", ["Smoke Grenade"] = "smoke", ["Incendiary Grenade"] = "inc"}
	local grenadeHighlights = {}
	local grenadeCards = {}
	local grenadeBaseNameColor = Color3.fromRGB(235, 235, 238)
	local grenadeBaseStrokeColor = Color3.fromRGB(40, 40, 45)
	local grenadeDangerColor = Color3.fromRGB(255, 0, 0)
	grenadeEspScreenGui = Instance.new("ScreenGui")
	grenadeEspScreenGui.Name = "ZeninGrenadeEsp"
	grenadeEspScreenGui.ResetOnSpawn = false
	grenadeEspScreenGui.IgnoreGuiInset = true
	grenadeEspScreenGui.DisplayOrder = 999996
	grenadeEspScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	grenadeEspScreenGui.Enabled = true
	pcall(function() grenadeEspScreenGui.Parent = screenGui.Parent end)
	local function grenadeColorFor(kind)
		if kind == "he" then return grenadeCfg.heColor end
		if kind == "flash" then return grenadeCfg.flashColor end
		if kind == "smoke" then return grenadeCfg.smokeColor end
		return grenadeCfg.incColor
	end
	local function grenadeGlowOn(kind)
		if kind == "he" then return grenadeCfg.heGlow end
		if kind == "flash" then return grenadeCfg.flashGlow end
		if kind == "smoke" then return grenadeCfg.smokeGlow end
		return grenadeCfg.incGlow
	end
	local function makeGrenadeCard(inst)
		local frame = Instance.new("Frame")
		frame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
		frame.BackgroundTransparency = 0.15
		frame.BorderSizePixel = 0
		frame.Size = UDim2.fromOffset(140, 36)
		frame.AnchorPoint = Vector2.new(0.5, 0)
		frame.ZIndex = 50
		frame.Parent = grenadeEspScreenGui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = frame
		local stroke = Instance.new("UIStroke")
		stroke.Color = grenadeBaseStrokeColor
		stroke.Thickness = 1
		stroke.Parent = frame
		local z = Instance.new("TextLabel")
		z.Text = "Z"
		z.Font = Enum.Font.SourceSansBold
		z.TextSize = 16
		z.TextColor3 = Color3.fromRGB(255, 0, 0)
		z.BackgroundTransparency = 1
		z.Position = UDim2.fromOffset(8, 2)
		z.Size = UDim2.fromOffset(12, 16)
		z.TextXAlignment = Enum.TextXAlignment.Left
		z.ZIndex = 51
		z.Parent = frame
		local nameL = Instance.new("TextLabel")
		nameL.Text = inst.Name
		nameL.Font = Enum.Font.SourceSansBold
		nameL.TextSize = 13
		nameL.TextColor3 = grenadeBaseNameColor
		nameL.BackgroundTransparency = 1
		nameL.Position = UDim2.fromOffset(24, 2)
		nameL.Size = UDim2.fromOffset(110, 16)
		nameL.TextXAlignment = Enum.TextXAlignment.Left
		nameL.ZIndex = 51
		nameL.Parent = frame
		local ownerL = Instance.new("TextLabel")
		ownerL.Text = tostring(inst:GetAttribute("Owner") or "?")
		ownerL.Font = Enum.Font.SourceSans
		ownerL.TextSize = 12
		ownerL.TextColor3 = Color3.fromRGB(180, 180, 185)
		ownerL.BackgroundTransparency = 1
		ownerL.Position = UDim2.fromOffset(8, 18)
		ownerL.Size = UDim2.fromOffset(124, 14)
		ownerL.TextXAlignment = Enum.TextXAlignment.Left
		ownerL.ZIndex = 51
		ownerL.Parent = frame
		return {frame = frame, z = z, name = nameL, owner = ownerL, stroke = stroke, fading = false}
	end
	local function fadeGrenadeCard(card)
		if card.fading then return end
		card.fading = true
		local info = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tweens = {
			TweenService:Create(card.frame, info, {BackgroundTransparency = 1}),
			TweenService:Create(card.z, info, {TextTransparency = 1}),
			TweenService:Create(card.name, info, {TextTransparency = 1}),
			TweenService:Create(card.owner, info, {TextTransparency = 1}),
			TweenService:Create(card.stroke, info, {Transparency = 1})
		}
		for _, t in ipairs(tweens) do t:Play() end
		task.delay(0.28, function() pcall(function() card.frame:Destroy() end) end)
	end
	local function updateGrenades()
		local active = grenadeCfg.enabled
		local debris = workspace:FindFirstChild("Debris")
		local seen = {}
		if active and debris then
			for _, child in ipairs(debris:GetChildren()) do
				local kind = grenadeTypes[child.Name]
				if kind then
					seen[child] = kind
					if grenadeGlowOn(kind) then
						local h = grenadeHighlights[child]
						if not h or h.Parent == nil then
							if h then pcall(function() h:Destroy() end) end
							local ok, nh = pcall(function()
								local highlight = Instance.new("Highlight")
								highlight.Name = "ZeninGrenadeGlow"
								highlight.FillColor = grenadeColorFor(kind)
								highlight.OutlineColor = grenadeColorFor(kind)
								highlight.FillTransparency = 0.6
								highlight.OutlineTransparency = 0
								highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
								highlight.Adornee = child
								highlight.Parent = grenadeEspScreenGui
								return highlight
							end)
							h = ok and nh or nil
							grenadeHighlights[child] = h
						end
						if h then
							pcall(function()
								h.FillColor = grenadeColorFor(kind)
								h.OutlineColor = grenadeColorFor(kind)
							end)
						end
					else
						local h = grenadeHighlights[child]
						if h then pcall(function() h:Destroy() end) grenadeHighlights[child] = nil end
					end
					if grenadeCfg.esp then
						local card = grenadeCards[child]
						if not card then
							card = makeGrenadeCard(child)
							grenadeCards[child] = card
						end
						if not card.fading then
							local pos = nil
							if child:IsA("BasePart") then
								pos = child.Position
							elseif child:IsA("Model") then
								local ok, cf = pcall(child.GetPivot, child)
								if ok and cf then pos = cf.Position end
							end
							local camera = workspace.CurrentCamera
							if pos and camera then
								local vp = camera:WorldToViewportPoint(pos)
								if vp.Z > 0 then
									card.frame.Visible = true
									card.frame.Position = UDim2.fromOffset(vp.X, vp.Y + 18)
									card.owner.Text = tostring(child:GetAttribute("Owner") or "?")
								else
									card.frame.Visible = false
								end
								if grenadeCfg.redWarning then
									local lp = Players.LocalPlayer
									local lchar = lp and lp.Character
									local lhrp = lchar and lchar:FindFirstChild("HumanoidRootPart")
									local myPos = lhrp and lhrp.Position or camera.CFrame.Position
									local dist = (pos - myPos).Magnitude
									local nameAlpha = math.clamp((30 - dist) / 25, 0, 1)
									local strokeAlpha = math.clamp((10 - dist) / 5, 0, 1)
									local targetName = grenadeBaseNameColor:Lerp(grenadeDangerColor, nameAlpha)
									local targetStroke = grenadeBaseStrokeColor:Lerp(grenadeDangerColor, strokeAlpha)
									pcall(function()
										card.name.TextColor3 = card.name.TextColor3:Lerp(targetName, 0.2)
										card.stroke.Color = card.stroke.Color:Lerp(targetStroke, 0.2)
										card.stroke.Transparency = 0
									end)
								else
									pcall(function()
										card.name.TextColor3 = grenadeBaseNameColor
										card.stroke.Color = grenadeBaseStrokeColor
										card.stroke.Transparency = 0
									end)
								end
							end
						end
					end
				end
			end
		end
		for inst, h in pairs(grenadeHighlights) do
			local kind = grenadeTypes[inst.Name]
			if not active or not seen[inst] or not kind or not grenadeGlowOn(kind) then
				if h then pcall(function() h:Destroy() end) end
				grenadeHighlights[inst] = nil
			end
		end
		for inst, card in pairs(grenadeCards) do
			local keep = active and grenadeCfg.esp and seen[inst] ~= nil
			if not keep then
				fadeGrenadeCard(card)
				grenadeCards[inst] = nil
			end
		end
	end
	local function updateFlyRagdoll(dt)
		if not flyRagdollEnabled then return end
		local debris = workspace:FindFirstChild("Debris")
		if not debris then return end
		local lp = Players.LocalPlayer
		if not lp then return end
		local oppositeTeam = nil
		if teamCheckEnabled then
			local myTeam = getTeamName(lp)
			if myTeam == "T" then oppositeTeam = "CT"
			elseif myTeam == "CT" then oppositeTeam = "T" end
		end
		for _, debrisObj in ipairs(debris:GetChildren()) do
			local targetPlayer = nil
			for _, player in ipairs(Players:GetPlayers()) do
				if player.Name == debrisObj.Name then targetPlayer = player break end
			end
			if targetPlayer and targetPlayer ~= lp then
				local targetTeam = getTeamName(targetPlayer)
				local teamOk = (targetTeam ~= "Spectator")
				if teamOk and teamCheckEnabled then teamOk = (oppositeTeam ~= nil and targetTeam == oppositeTeam) end
				if teamOk then
					for _, descendant in ipairs(debrisObj:GetDescendants()) do
						if descendant:IsA("BasePart") then
							pcall(function()
								local velOk, currentVel = pcall(function() return descendant.AssemblyLinearVelocity end)
								if velOk and currentVel then
									descendant.AssemblyLinearVelocity = Vector3.new(currentVel.X, 100, currentVel.Z)
								else
									descendant.CFrame = descendant.CFrame + Vector3.new(0, 20 * dt, 0)
								end
							end)
						end
					end
				end
			end
		end
	end
	local function updateAimbot()
		local camera = workspace.CurrentCamera
		if aimFOVCircle and camera then
			pcall(function()
				local vp = camera.ViewportSize
				aimFOVCircle.Position = Vector2.new(vp.X / 2, vp.Y / 2)
				aimFOVCircle.Color = aimFOVColor
				local f = (vp.Y / 2) / math.tan(math.rad(camera.FieldOfView / 2))
				local r
				if aimFOV >= 179 then r = vp.X + vp.Y else r = math.tan(math.rad(aimFOV / 2)) * f end
				r = math.min(r, vp.X + vp.Y)
				aimRadius = r
				aimFOVCircle.Radius = r
				aimFOVCircle.Visible = aimEnabled
			end)
		end
		if not aimEnabled or not camera then return end
		local lp = Players.LocalPlayer
		if not lp then return end
		if getTeamName(lp) == "Spectator" then return end
		local oppositeTeam = nil
		if aimTeamCheck then
			local myTeam = getTeamName(lp)
			if myTeam == "T" then oppositeTeam = "CT"
			elseif myTeam == "CT" then oppositeTeam = "T"
			else return end
		end
		local wp = workspace:FindFirstChild("Players")
		if not wp then return end
		local center = camera.ViewportSize / 2
		local bestPart, bestDist = nil, math.huge
		local function isBlocked(pos)
			local origin = camera.CFrame.Position
			local dir = pos - origin
			local dist = dir.Magnitude
			if dist < 0.001 then return false end
			local params = RaycastParams.new()
			pcall(function() params.FilterType = Enum.RaycastFilterType.Exclude end)
			local bl = {wp}
			local lc = lp.Character
			if lc then table.insert(bl, lc) end
			if customModelFolder then table.insert(bl, customModelFolder) end
			pcall(function() params.FilterDescendantsInstances = bl end)
			local hit = workspace:Raycast(origin, dir, params)
			if hit and hit.Distance < dist - 0.5 then return true end
			return false
		end
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= lp then
				local t = getTeamName(player)
				local teamOk = (t ~= "Spectator")
				if teamOk and aimTeamCheck then teamOk = (oppositeTeam ~= nil and t == oppositeTeam) end
				if teamOk and aimForceFieldCheck and hasForceField(player.Character) then teamOk = false end
				if teamOk then
					local model = wp:FindFirstChild(player.Name)
					local hb = model and model:FindFirstChild("Hitboxes")
					if hb then
						local h, to = hb:FindFirstChild("H"), hb:FindFirstChild("T")
						local cands = {}
						if aimBoneMode == "Head" then
							if h then table.insert(cands, h) end
						elseif aimBoneMode == "Torso" then
							if to then table.insert(cands, to) end
						else
							if h then table.insert(cands, h) end
							if to then table.insert(cands, to) end
						end
						local chosen = nil
						for _, part in ipairs(cands) do
							if not (aimWallCheck and isBlocked(part.Position)) then chosen = part break end
						end
						if chosen then
							local svp = camera:WorldToViewportPoint(chosen.Position)
							if svp.Z > 0 then
								local d = (Vector2.new(svp.X, svp.Y) - center).Magnitude
								if d <= aimRadius and d < bestDist then
									bestDist = d
									bestPart = chosen
								end
							end
						end
					end
				end
			end
		end
		if bestPart then
			local goal = CFrame.lookAt(camera.CFrame.Position, bestPart.Position)
			local alpha = math.clamp((aimSpeed / 10) / (1 + aimSmooth * 0.5), 0.02, 1)
			camera.CFrame = camera.CFrame:Lerp(goal, alpha)
		end
	end
	local function updateAntiAim(dt)
		if not antiAimEnabled then return end
		local lp = Players.LocalPlayer
		local char = lp and lp.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local camera = workspace.CurrentCamera
		if not hrp or not hum or not camera then return end
		if hum.Health <= 0 then return end
		if antiSpinEnabled then
			if char ~= antiChar then
				antiChar = char
				savedRootC0 = nil
				local firstJoint = hrp:FindFirstChildOfClass("Motor6D")
				if firstJoint then savedRootC0 = firstJoint.C0 end
			end
			spinX = (spinX + dt * 21) % (math.pi * 2)
			spinY = (spinY + dt * 30) % (math.pi * 2)
			spinZ = (spinZ + dt * 17) % (math.pi * 2)
			pcall(function() hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, spinY, 0) end)
			local rootJoint = hrp:FindFirstChildOfClass("Motor6D")
			if rootJoint and savedRootC0 then
				pcall(function() rootJoint.C0 = savedRootC0 * CFrame.Angles(spinX, 0, spinZ) end)
			end
			return
		else
			if savedRootC0 then
				local rootJoint = hrp:FindFirstChildOfClass("Motor6D")
				if rootJoint then pcall(function() rootJoint.C0 = savedRootC0 end) end
				savedRootC0 = nil
				antiChar = nil
			end
		end
		if antiYaw == "None" then return end
		local dir = nil
		if antiYawMode == "At Targets" then
			local myPos = hrp.Position
			local bestD = math.huge
			local oppositeTeam = nil
			if aimTeamCheck then
				local myTeam = getTeamName(lp)
				if myTeam == "T" then oppositeTeam = "CT"
				elseif myTeam == "CT" then oppositeTeam = "T" end
			end
			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= lp then
					local t = getTeamName(player)
					local ok = (t ~= "Spectator")
					if ok and aimTeamCheck then ok = (oppositeTeam ~= nil and t == oppositeTeam) end
					if ok then
						local pchar = player.Character
						local phrp = pchar and pchar:FindFirstChild("HumanoidRootPart")
						if phrp then
							local d = (phrp.Position - myPos).Magnitude
							if d < bestD then bestD = d dir = phrp.Position - myPos end
						end
					end
				end
			end
		end
		if not dir then
			local look = camera.CFrame.LookVector
			dir = Vector3.new(look.X, 0, look.Z)
		else
			dir = Vector3.new(dir.X, 0, dir.Z)
		end
		if dir.Magnitude < 0.001 then dir = Vector3.new(0, 0, -1) end
		dir = dir.Unit
		local off = 0
		if antiYaw == "Left" then off = -math.pi / 2
		elseif antiYaw == "Right" then off = math.pi / 2
		elseif antiYaw == "Backward" then off = math.pi end
		pcall(function() hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + dir) * CFrame.Angles(0, off, 0) end)
	end
	connect(UserInputService.JumpRequest, function()
		jumpRequestAt = os.clock()
	end)
	connect(Players.PlayerRemoving, function(player)
		removeEsp(player)
		destroyGlowHighlight(enemyHighlights[player])
		enemyHighlights[player] = nil
	end)
	connect(Players.LocalPlayer.CharacterAdded, function(char)
		noclipOriginal = {}
		customHidden = {}
		destroyCustomModel()
		antiChar = nil
		savedRootC0 = nil
		local hum = char:WaitForChild("Humanoid", 10)
		char:WaitForChild("HumanoidRootPart", 10)
		if flyEnabled then setupFly(char) end
		if autoStraferEnabled and hum then savedWalkSpeed = hum.WalkSpeed end
	end)
	connect(Players.LocalPlayer.CharacterRemoving, function()
		noclipOriginal = {}
		destroyGlowHighlight(localHighlight)
		localHighlight = nil
		destroyCustomModel()
		customHidden = {}
		antiChar = nil
		savedRootC0 = nil
	end)
	connect(RunService.Stepped, function()
		if not noclipEnabled then return end
		local char = Players.LocalPlayer and Players.LocalPlayer.Character
		if not char then return end
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				if noclipOriginal[part] == nil then noclipOriginal[part] = part.CanCollide end
				if part.CanCollide then pcall(function() part.CanCollide = false end) end
			end
		end
	end)
	connect(RunService.RenderStepped, function(dt)
		local lp = Players.LocalPlayer
		local char = lp and lp.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local camera = workspace.CurrentCamera
		local focused = UserInputService:GetFocusedTextBox() ~= nil
		local jumpHeld = (not focused and UserInputService:IsKeyDown(Enum.KeyCode.Space)) or (os.clock() - jumpRequestAt < 0.3)
		local moveDir = hum and hum.MoveDirection or Vector3.zero
		if flyEnabled and char and hrp and hum and camera then
			if not flyVelocity or flyVelocity.Parent ~= hrp then setupFly(char) end
			if flyVelocity and flyGyro and flyVelocity.Parent == hrp then
				if not hum.PlatformStand then pcall(function() hum.PlatformStand = true end) end
				local look = camera.CFrame.LookVector
				local flat = Vector3.new(look.X, 0, look.Z)
				if flat.Magnitude > 0.001 then flyGyro.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + flat.Unit) end
				local move = Vector3.zero
				if not focused then
					if isTouchDevice then
						if moveDir.Magnitude > 0.05 then move += moveDir end
					else
						local cf = camera.CFrame
						if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cf.LookVector end
						if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cf.LookVector end
						if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cf.RightVector end
						if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cf.RightVector end
						if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0, 1, 0) end
					end
					if jumpHeld or mobileUp then move += Vector3.new(0, 1, 0) end
					if mobileDown then move -= Vector3.new(0, 1, 0) end
				end
				if move.Magnitude > 0 then flyVelocity.Velocity = move.Unit * flySpeed else flyVelocity.Velocity = Vector3.zero end
			end
		end
		if autoStraferEnabled and hum and hum.Health > 0 then
			if not focused and jumpHeld then
				if hum.WalkSpeed ~= strafeSpeed then pcall(function() hum.WalkSpeed = strafeSpeed end) end
				if hum.FloorMaterial ~= Enum.Material.Air and not hum.Sit then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
			elseif savedWalkSpeed ~= nil and hum.WalkSpeed ~= savedWalkSpeed then
				pcall(function() hum.WalkSpeed = savedWalkSpeed end)
			end
		end
		if fastStopEnabled and hum and hrp and hum.Health > 0 and not flyEnabled then
			local moving = moveDir.Magnitude > 0.05
			if not isTouchDevice then
				moving = moving or UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.D)
			end
			if not moving and not (autoStraferEnabled and jumpHeld) and hum.FloorMaterial ~= Enum.Material.Air then
				if not fastStopActive then
					fastStopActive = true
					pcall(function()
						local v = hrp.AssemblyLinearVelocity
						hrp.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0)
					end)
				end
			else
				fastStopActive = false
			end
		end
		if hum then lastFloorMaterial = hum.FloorMaterial end
		if thirdpersonEnabled and lp then
			if lp.CameraMode ~= Enum.CameraMode.Classic or lp.CameraMinZoomDistance ~= zoomValue or lp.CameraMaxZoomDistance ~= zoomValue then applyCameraSettings() end
		end
		if cameraFovEnabled then
			hookCameraFov()
			forceCameraFov()
		end
		if worldAmbienceEnabled then
			pcall(function()
				if Lighting.Ambient ~= worldColor then Lighting.Ambient = worldColor end
				if fullAmbienceEnabled and Lighting.OutdoorAmbient ~= worldColor then Lighting.OutdoorAmbient = worldColor end
			end)
		end
		if skyOption ~= "None" then
			local key = skyKeyByOption[skyOption]
			local preset = key and skyPresets[key]
			if preset then
				if not customSky or customSky.Parent ~= Lighting then applySky(skyOption) end
				pcall(function()
					for _, obj in ipairs(Lighting:GetChildren()) do
						if obj:IsA("Sky") then
							if obj ~= customSky then obj:Destroy() end
						elseif obj:IsA("Atmosphere") then
							if not fogCfg.enabled then obj:Destroy() end
						end
					end
					if customSky and customSky.Parent == Lighting then
						if customSky.SkyboxBk ~= preset.SkyboxBk then customSky.SkyboxBk = preset.SkyboxBk end
						if customSky.SkyboxDn ~= preset.SkyboxDn then customSky.SkyboxDn = preset.SkyboxDn end
						if customSky.SkyboxFt ~= preset.SkyboxFt then customSky.SkyboxFt = preset.SkyboxFt end
						if customSky.SkyboxLf ~= preset.SkyboxLf then customSky.SkyboxLf = preset.SkyboxLf end
						if customSky.SkyboxRt ~= preset.SkyboxRt then customSky.SkyboxRt = preset.SkyboxRt end
						if customSky.SkyboxUp ~= preset.SkyboxUp then customSky.SkyboxUp = preset.SkyboxUp end
						if preset.StarCount and customSky.StarCount ~= preset.StarCount then customSky.StarCount = preset.StarCount end
						if customSky.SunAngularSize ~= preset.SunAngularSize then customSky.SunAngularSize = preset.SunAngularSize end
						if customSky.MoonAngularSize ~= preset.MoonAngularSize then customSky.MoonAngularSize = preset.MoonAngularSize end
					end
					if Lighting.ClockTime ~= preset.ClockTime then Lighting.ClockTime = preset.ClockTime end
					if Lighting.Brightness ~= preset.Brightness then Lighting.Brightness = preset.Brightness end
					if not fogCfg.enabled then
						if Lighting.FogStart ~= 100000 then Lighting.FogStart = 100000 end
						if Lighting.FogEnd ~= 100000 then Lighting.FogEnd = 100000 end
					end
				end)
			end
		end
		applyFog()
		updateCustomModel(char, hrp, dt)
		updateAimbot()
		updateAntiAim(dt)
		updateFlyRagdoll(dt)
		updateViewmodel()
		updateLaserMines()
		updateGrenades()
		updateNoSmoke()
		updateNoFlash()
		applyKnife()
		if localGlowEnabled and char then
			if not localHighlight or localHighlight.Parent ~= char then
				destroyGlowHighlight(localHighlight)
				localHighlight = createGlowHighlight(char, localGlowColor, glowFull.Local)
			end
			if localHighlight then
				pcall(function()
					localHighlight.FillColor = localGlowColor
					localHighlight.OutlineColor = localGlowColor
					localHighlight.FillTransparency = glowFull.Local and 0 or 1
				end)
			end
		elseif localHighlight then
			destroyGlowHighlight(localHighlight)
			localHighlight = nil
		end
		local glowOppositeTeam = nil
		if teamCheckEnabled then
			local myTeam = getTeamName(lp)
			if myTeam == "T" then glowOppositeTeam = "CT"
			elseif myTeam == "CT" then glowOppositeTeam = "T" end
		end
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= lp then
				local h = enemyHighlights[player]
				local want = false
				if glowEnemyEnabled then
					local t = getTeamName(player)
					want = (t ~= "Spectator")
					if want and teamCheckEnabled then want = (glowOppositeTeam ~= nil and t == glowOppositeTeam) end
				end
				local pchar = player.Character
				if want and pchar then
					if not h or h.Parent ~= pchar then
						destroyGlowHighlight(h)
						h = createGlowHighlight(pchar, glowEnemyColor, glowFull.Enemy)
						enemyHighlights[player] = h
					end
					if h then
						pcall(function()
							h.FillColor = glowEnemyColor
							h.OutlineColor = glowEnemyColor
							h.FillTransparency = glowFull.Enemy and 0 or 1
						end)
					end
				elseif h then
					destroyGlowHighlight(h)
					enemyHighlights[player] = nil
				end
			end
		end
		if not espEnabled or not (espBoxEnabled or espNamesEnabled or espSkeletonEnabled or flagsEnabled or espWeaponEnabled) or not camera then
			for _, obj in pairs(espObjects) do hideEsp(obj) end
			return
		end
		local wp = workspace:FindFirstChild("Players")
		local oppositeTeam = nil
		if teamCheckEnabled then
			local myTeam = getTeamName(lp)
			if myTeam == "T" then oppositeTeam = "CT"
			elseif myTeam == "CT" then oppositeTeam = "T" end
		end
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= lp then
				local obj = espObjects[player]
				if obj == nil then obj = createEsp(player) end
				local boxShown, nameShown, ffShown, moneyShown, pingShown, weaponShown = false, false, false, false, false, false
				local targetTeam = getTeamName(player)
				local teamOk = (targetTeam ~= "Spectator")
				if teamOk and teamCheckEnabled then teamOk = (oppositeTeam ~= nil and targetTeam == oppositeTeam) end
				if teamOk then
					local pchar = player.Character
					local phrp = pchar and pchar:FindFirstChild("HumanoidRootPart")
					local phum = pchar and pchar:FindFirstChildOfClass("Humanoid")
					if pchar and phrp and phum and phum.Health > 0 then
						local ok, cf, size = pcall(pchar.GetBoundingBox, pchar)
						if ok and cf and size then
							local half = size * 0.5
							if espBoxEnabled and obj.Box then
								local minX, minY = math.huge, math.huge
								local maxX, maxY = -math.huge, -math.huge
								local allFront = true
								for _, s in ipairs(cornerSigns) do
									local worldPos = cf:PointToWorldSpace(Vector3.new(half.X * s.X, half.Y * s.Y, half.Z * s.Z))
									local vp = camera:WorldToViewportPoint(worldPos)
									if vp.Z <= 0 then allFront = false break end
									if vp.X < minX then minX = vp.X end
									if vp.Y < minY then minY = vp.Y end
									if vp.X > maxX then maxX = vp.X end
									if vp.Y > maxY then maxY = vp.Y end
								end
								if allFront and maxX > minX and maxY > minY then
									pcall(function()
										obj.Box.Position = Vector2.new(minX, minY)
										obj.Box.Size = Vector2.new(maxX - minX, maxY - minY)
										obj.Box.Color = boxColor
									end)
									boxShown = true
								end
							end
							if espNamesEnabled and obj.Name and obj.NameBg then
								local topWorld = cf.Position + Vector3.new(0, half.Y + 0.5, 0)
								local vp = camera:WorldToViewportPoint(topWorld)
								if vp.Z > 0 then
									local bounds = obj.Name.TextBounds
									if not bounds or bounds.X <= 0 or bounds.Y <= 0 then bounds = Vector2.new(#player.Name * 7, 14) end
									local pos = Vector2.new(vp.X - bounds.X / 2, vp.Y - bounds.Y - 2)
									pcall(function()
										obj.NameBg.Position = pos
										obj.NameBg.Size = bounds
										obj.Name.Position = pos
									end)
									nameShown = true
								end
							end
							if flagsEnabled and flagOptions.ForceField and obj.ForceField and hasForceField(pchar) then
								local topWorld = cf.Position + Vector3.new(0, half.Y + 0.5, 0)
								local vp = camera:WorldToViewportPoint(topWorld)
								if vp.Z > 0 then
									local bounds = obj.ForceField.TextBounds
									if not bounds or bounds.X <= 0 or bounds.Y <= 0 then bounds = Vector2.new(60, 14) end
									local yOffset = 2
									if nameShown then
										local nb = obj.Name.TextBounds
										if not nb or nb.Y <= 0 then nb = Vector2.new(0, 14) end
										yOffset = nb.Y + 4
									end
									pcall(function() obj.ForceField.Position = Vector2.new(vp.X - bounds.X / 2, vp.Y - bounds.Y - yOffset) end)
									ffShown = true
								end
							end
							if flagsEnabled and flagOptions.Money and obj.Money then
								local okM, moneyVal = pcall(function() return player:GetAttribute("Money") end)
								if okM and moneyVal ~= nil then
									local camRight = camera.CFrame.RightVector
									local leftWorld = cf.Position - camRight * (half.X + 0.6)
									local vp = camera:WorldToViewportPoint(leftWorld)
									if vp.Z > 0 then
										pcall(function() obj.Money.Text = "$" .. tostring(moneyVal) end)
										local bounds = obj.Money.TextBounds
										if not bounds or bounds.X <= 0 or bounds.Y <= 0 then bounds = Vector2.new(40, 14) end
										pcall(function() obj.Money.Position = Vector2.new(vp.X - bounds.X, vp.Y - bounds.Y / 2) end)
										moneyShown = true
									end
								end
							end
							if flagsEnabled and flagOptions.Ping and obj.Ping then
								local okP, pingVal = pcall(function() return player:GetAttribute("Ping") end)
								if okP and pingVal ~= nil then
									local camRight = camera.CFrame.RightVector
									local rightWorld = cf.Position + camRight * (half.X + 0.6)
									local vp = camera:WorldToViewportPoint(rightWorld)
									if vp.Z > 0 then
										pcall(function() obj.Ping.Text = tostring(pingVal) end)
										local bounds = obj.Ping.TextBounds
										if not bounds or bounds.X <= 0 or bounds.Y <= 0 then bounds = Vector2.new(24, 14) end
										pcall(function() obj.Ping.Position = Vector2.new(vp.X, vp.Y - bounds.Y / 2) end)
										pingShown = true
									end
								end
							end
							if espWeaponEnabled and obj.Weapon and obj.WeaponBg then
								local weaponName = nil
								local wmodel = wp and wp:FindFirstChild(player.Name)
								if wmodel then
									local okAttr, attr = pcall(function() return wmodel:GetAttribute("WhatGun") end)
									if okAttr and attr ~= nil then weaponName = tostring(attr) end
								end
								if weaponName and weaponName ~= "" then
									local bottomWorld = cf.Position - Vector3.new(0, half.Y + 0.5, 0)
									local vp = camera:WorldToViewportPoint(bottomWorld)
									if vp.Z > 0 then
										pcall(function() obj.Weapon.Text = weaponName end)
										local bounds = obj.Weapon.TextBounds
										if not bounds or bounds.X <= 0 or bounds.Y <= 0 then bounds = Vector2.new(#weaponName * 7, 14) end
										local pos = Vector2.new(vp.X - bounds.X / 2, vp.Y + 2)
										pcall(function()
											obj.WeaponBg.Position = pos
											obj.WeaponBg.Size = bounds
											obj.Weapon.Position = pos
										end)
										weaponShown = true
									end
								end
							end
						end
					end
				end
				local skeletonOn = false
				if espSkeletonEnabled and teamOk then
					local sc = player.Character
					local sh = sc and sc:FindFirstChildOfClass("Humanoid")
					if sc and sh and sh.Health > 0 then
						skeletonOn = true
						for i, bone in ipairs(skeletonBones) do
							local line = obj["Bone" .. i]
							if line then
								local a, b = sc:FindFirstChild(bone[1]), sc:FindFirstChild(bone[2])
								local shown = false
								if a and b then
									local va = camera:WorldToViewportPoint(a.Position)
									local vb = camera:WorldToViewportPoint(b.Position)
									if va.Z > 0 and vb.Z > 0 then
										pcall(function()
											line.From = Vector2.new(va.X, va.Y)
											line.To = Vector2.new(vb.X, vb.Y)
											line.Color = skeletonColor
										end)
										shown = true
									end
								end
								pcall(function() line.Visible = shown end)
							end
						end
					end
				end
				if not skeletonOn then
					for i = 1, #skeletonBones do
						local line = obj["Bone" .. i]
						if line then pcall(function() line.Visible = false end) end
					end
				end
				pcall(function()
					if obj.Box then obj.Box.Visible = boxShown end
					if obj.Name then obj.Name.Visible = nameShown end
					if obj.NameBg then obj.NameBg.Visible = nameShown end
					if obj.ForceField then obj.ForceField.Visible = ffShown end
					if obj.Money then obj.Money.Visible = moneyShown end
					if obj.Ping then obj.Ping.Visible = pingShown end
					if obj.Weapon then obj.Weapon.Visible = weaponShown end
					if obj.WeaponBg then obj.WeaponBg.Visible = weaponShown end
				end)
			end
		end
	end)
end

startRuntime()

do
	local introGui = Instance.new("ScreenGui")
	introGui.Name = "ZeninIntro"
	introGui.ResetOnSpawn = false
	introGui.IgnoreGuiInset = true
	introGui.DisplayOrder = 1000000
	introGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	introGui.Enabled = true
	if syn ~= nil and syn.protect_gui ~= nil then pcall(syn.protect_gui, introGui) end
	pcall(function() introGui.Parent = screenGui.Parent end)
	introGuiRef = introGui
	local box = Instance.new("Frame")
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.Position = UDim2.new(0.5, 0, 0.5, 0)
	box.Size = UDim2.fromOffset(0, 0)
	box.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
	box.BorderSizePixel = 0
	box.ClipsDescendants = true
	box.ZIndex = 10
	box.Parent = introGui
	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 18)
	boxCorner.Parent = box
	local boxStroke = Instance.new("UIStroke")
	boxStroke.Color = Color3.fromRGB(95, 95, 102)
	boxStroke.Thickness = 2
	boxStroke.Parent = box
	local introZ = Instance.new("TextLabel")
	introZ.Text = "Z"
	introZ.Font = Enum.Font.SourceSansBold
	introZ.TextSize = 54
	introZ.TextColor3 = uiTheme.accent
	introZ.BackgroundTransparency = 1
	introZ.AnchorPoint = Vector2.new(0.5, 0.5)
	introZ.Position = UDim2.new(0.5, 0, 0.5, 0)
	introZ.Size = UDim2.fromOffset(96, 96)
	introZ.ZIndex = 11
	introZ.Parent = box
	registerAccent(function() introZ.TextColor3 = uiTheme.accent end)
	local introTitle = Instance.new("TextLabel")
	introTitle.Text = "ZENIN"
	introTitle.Font = Enum.Font.SourceSansBold
	introTitle.TextSize = isTouchDevice and 44 or 64
	introTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
	introTitle.BackgroundTransparency = 1
	introTitle.TextTransparency = 1
	introTitle.AnchorPoint = Vector2.new(0, 0.5)
	introTitle.Position = UDim2.new(0.5, -56, 0.5, 0)
	introTitle.Size = UDim2.fromOffset(320, 96)
	introTitle.TextXAlignment = Enum.TextXAlignment.Left
	introTitle.ZIndex = 10
	introTitle.Parent = introGui
	local function finishIntro()
		if introFinished then return end
		introFinished = true
		pcall(function() introGui:Destroy() end)
		introGuiRef = nil
		screenGui.Enabled = true
		if watermarkSetState then
			pcall(function() watermarkSetState(true, true) end)
		else
			watermarkEnabled = true
			if watermarkGui then watermarkGui.Visible = true end
		end
	end
	task.spawn(function()
		pcall(function()
			local t1 = TweenService:Create(box, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(96, 96)})
			t1:Play()
			t1.Completed:Wait()
			task.wait(0.25)
			local t2 = TweenService:Create(box, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Position = UDim2.new(0.5, -120, 0.5, 0)})
			local t3 = TweenService:Create(introTitle, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})
			t2:Play()
			t3:Play()
			t2.Completed:Wait()
			task.wait(0.7)
			local t4 = TweenService:Create(introTitle, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1})
			t4:Play()
			t4.Completed:Wait()
			local t5 = TweenService:Create(box, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 320, 0.5, 0), Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1})
			local t6 = TweenService:Create(introZ, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1})
			local t7 = TweenService:Create(boxStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1})
			t5:Play()
			t6:Play()
			t7:Play()
			t5.Completed:Wait()
		end)
		finishIntro()
	end)
	task.delay(7, function() finishIntro() end)
end
