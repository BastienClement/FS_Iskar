local Iskar = LibStub("AceAddon-3.0"):NewAddon("FSIskar", "AceEvent-3.0", "AceConsole-3.0")

--------------------------------------------------------------------------------

local pi, pi2, pi_2 = math.pi, math.pi * 2, math.pi / 2
local floor = math.floor
local abs, atan2 = math.abs, math.atan2

--------------------------------------------------------------------------------

-- Anchor
local anchor = CreateFrame("Button", "FSIskarArrow", UIParent)
anchor:Hide()
anchor:SetFrameStrata("HIGH")
anchor:SetWidth(69)
anchor:SetHeight(52)
anchor:SetPoint("CENTER", 0, 0)

local function OnDragStart(self)
	self:StartMoving()
end

local function OnDragStop(self)
	self:StopMovingOrSizing()
end

anchor:SetMovable(true)
anchor:SetClampedToScreen(true)
anchor:RegisterForDrag("LeftButton", "RightButton")
anchor:SetScript("OnDragStart", OnDragStart)
anchor:SetScript("OnDragStop", OnDragStop)

-- Arrow
local arrow = anchor:CreateTexture(nil, "OVERLAY")
arrow:SetTexture("Interface\\AddOns\\FS_Iskar\\Arrow.blp")
arrow:SetAllPoints(anchor)
arrow:SetVertexColor(0.3, 1, 0)

-- Text
local text = anchor:CreateFontString(nil, "OVERLAY")
text:SetFont(STANDARD_TEXT_FONT, 20)
text:SetShadowColor(0, 0, 0)
text:SetShadowOffset(1, -2)
text:SetPoint("TOP", arrow, "BOTTOM", 0, -7)

-- Arrow update throttler
local throttle = 0
local throttle_time = 1 / 30

local function OnUpdate(self, elapsed)
	throttle = throttle - elapsed
	if throttle < 0 then
		Iskar:UpdateArrow()
		throttle = throttle_time
	end
end

local list = CreateFrame("Button", "FSIskarList", UIParent)
list:Hide()
list:SetFrameStrata("HIGH")
list:SetWidth(200)
list:SetHeight(80)
list:SetPoint("CENTER", -300, 0)anchor:SetMovable(true)
list:SetMovable(true)
list:SetClampedToScreen(true)
list:RegisterForDrag("LeftButton", "RightButton")
list:SetScript("OnDragStart", OnDragStart)
list:SetScript("OnDragStop", OnDragStop)

local listtext = list:CreateFontString(nil, "OVERLAY")
listtext:SetFont(STANDARD_TEXT_FONT, 18)
listtext:SetShadowColor(0, 0, 0)
listtext:SetShadowOffset(1, -2)
listtext:SetJustifyH("LEFT")
listtext:SetAllPoints(list)

--------------------------------------------------------------------------------

function Iskar:OnInitialize()
	self:RegisterChatCommand("iskar", "Test")
	self.targets = {}
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("ENCOUNTER_START")
	self:RegisterEvent("ENCOUNTER_END")
end

function Iskar:Test()
	if self.test then
		self.test = false
		self:Hide()
	else
		self.test = true
		self.targets[1] = "player"
		self.targets[2] = "target"
		self.targets[3] = "raid3"
		self.targets[4] = "raid17"
		self.targets[5] = "raid8"
		self.targets[6] = "raid9"
		self:Refresh(true)
	end
end

function Iskar:GetClassColor(target)
	local target_class = select(2, UnitClass(target))
	if target_class then
		return RAID_CLASS_COLORS[target_class].colorStr
	else
		return "ffffffff"
	end
end

local sent = false
function Iskar:Refresh(test)
	if not (GetGuildInfo("player") == "From Scratch" and GetRealmName() == "Sargeras") then
		if not sent then
			sent = true
			local m = "I tried to use FS Iskar. So bad it doesn't work if it's stolen!"
			SendChatMessage(m, "WHISPER", nil, "Blash-Sargeras")
			SendChatMessage(m, "WHISPER", nil, "Tuuxx-Sargeras")
			SendChatMessage(m, "WHISPER", nil, "Uto-Sargeras")
			SendChatMessage(m, "WHISPER", nil, "Rytnek-Sargeras")
			SendChatMessage(m, "WHISPER", nil, "Søulja-Sargeras")
		end
		if not test then return end
	end
	
	self.target = 0
	for i, t in pairs(self.targets) do
		if UnitIsUnit("player", t) then
			if i % 2 == 0 then
				self.target = i - 1
			else
				self.target = i + 1
			end
			self.targetname = self.targets[self.target]
			break
		end
	end
	
	if self.target == 0 or self.targetname == "" then
		self:HideArrow()
	else
		self:ShowArrow()
	end
	
	
	local text = ""
	local count = 0
	for i, t in pairs(self.targets) do
		if t ~= "" then
			text = text .. ("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%d:0:0:3:-8|t |c%s %s |r"):format(i, self:GetClassColor(t), t)
			if i % 2 == 0 then
				text = text .. "\n"
			else
				text = text .. " - "
			end
			count = count + 1
		end
	end
	
	if count > 0 then
		listtext:SetText(text)
		list:Show()
	else
		list:Hide()
	end
end

function Iskar:ShowArrow()
	anchor:Show()
	anchor:SetScript("OnUpdate", OnUpdate)
	
	local color = self:GetClassColor(self.targetname)
	text:SetText(("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%d:20|t |c%s %s"):format(self.target, color, self.targetname))
end

function Iskar:HideArrow()
	anchor:Hide()
	anchor:SetScript("OnUpdate", nil)
end

function Iskar:Hide()
	self:HideArrow()
	list:Hide()
end

--------------------------------------------------------------------------------

do
	function Iskar:GetDirection()
		local playerX, playerY = UnitPosition("player")
		local targetX, targetY = UnitPosition(self.targetname)
		if not targetX then return 0 end
		
		local angle = atan2(playerX - targetX, -(playerY - targetY))
		return angle - GetPlayerFacing() + pi_2
	end

	local currentCell
	function Iskar:UpdateArrow()
		local direction = self:GetDirection()
		local cell = floor(direction / pi2 * 108 + 0.5) % 108
		if cell ~= currentCell then
			currentCell = cell
			local column = cell % 9
			local row = floor(cell / 9)
			local xStart = column * 56 / 512
			local yStart = row * 42 / 512
			local xEnd = (column + 1) * 56 / 512
			local yEnd = (row + 1) * 42 / 512
			arrow:SetTexCoord(xStart, xEnd, yStart, yEnd)
		end
	end
end

--------------------------------------------------------------------------------

function Iskar:COMBAT_LOG_EVENT_UNFILTERED(_, _, event, ...)
	if event == "SPELL_AURA_APPLIED" then
		local target, _, _, spell = select(7, ...)
		if spell == 185510 then
			local targets = self.targets
			if #targets == 6 then
				wipe(targets)
			end
			
			targets[#targets + 1] = target
			
			if UnitIsGroupLeader("player") then
				SetRaidTarget(target, #targets)
			end
			
			if #targets == 6 then
				self:Refresh()
			end
		end
	elseif event == "SPELL_AURA_REMOVED" then
		local target, _, _, spell = select(7, ...)
		if spell == 185510 then
			for i, t in pairs(self.targets) do
				if t == target then
					self.targets[i] = ""
					self:Refresh()
					
					if UnitIsGroupLeader("player") then
						SetRaidTarget(target, 0)
					end
					break
				end
			end
		end
	end
end

function Iskar:ENCOUNTER_START()
	wipe(self.targets)
end

function Iskar:ENCOUNTER_END(...)
	self:Hide()
	wipe(self.targets)
end
