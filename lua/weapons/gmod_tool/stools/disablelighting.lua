TOOL.Category		= "Render"
TOOL.Name			= "Disable Lighting"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar["lighting"] = 1
TOOL.ClientConVar["shadow"] = 0
TOOL.ClientConVar["mode"] = 0
TOOL.ClientConVar["spawn"] = 0
TOOL.ClientConVar["r"] = 255
TOOL.ClientConVar["g"] = 255
TOOL.ClientConVar["b"] = 255
TOOL.ClientConVar["a"] = 255

if CLIENT then
	language.Add("Tool.disablelighting.name", "Disable Lighting")
	language.Add("Tool.disablelighting.desc", "Edit lighting and shadows on entities")
	language.Add("Tool.disablelighting.left", "Disable Lighting")
	language.Add("Tool.disablelighting.right", "Copy Lighting")
	language.Add("Tool.disablelighting.reload", "Enable Lighting")
	language.Add("disablelighting_name", "Name:")
	TOOL.Information = {"left", "right", "reload"}

	-- default "apply on spawn" to off in case they forgot they turned it on
	hook.Add("InitPostEntity", "disablelighting_disablespawn", function()
		local spawnconvar = GetConVar("disablelighting_spawn")
		if spawnconvar then
			spawnconvar:SetBool(false)
		end
	end)
end

if SERVER then
	util.AddNetworkString("EntityLightingChange")
end

local function applyOnSpawn(ply, model, ent)
	if ply:GetInfoNum("disablelighting_spawn", 0) != 1 then return end
	
	local r = ply:GetInfoNum("disablelighting_r", 255)
	local g = ply:GetInfoNum("disablelighting_g", 255)
	local b = ply:GetInfoNum("disablelighting_b", 255)
	local a = ply:GetInfoNum("disablelighting_a", 255)

	local data = {}
	data.Color = {r = r, g = g, b = b, a = a}

	if a < 255 then
		data.RenderMode = RENDERMODE_TRANSCOLOR
		ent:SetRenderMode(data.RenderMode)
	end

	ent:SetColor(Color(r, g, b, a))
	
	duplicator.StoreEntityModifier(ent, "colour", data) -- this should already be registered by the color tool

	local lightingDisabled = ply:GetInfoNum("disablelighting_lighting", 1) == 1 and true or false
	local lightingMode = ply:GetInfoNum("disablelighting_mode", 1)
	local shadowDisabled = ply:GetInfoNum("disablelighting_shadow", 0) == 1 and true or false

	DisableEntityLighting(ent, lightingDisabled, lightingMode, shadowDisabled)
end
hook.Add("PlayerSpawnedProp", "disablelighting_spawnapply", applyOnSpawn)
hook.Add("PlayerSpawnedRagdoll", "disablelighting_spawnapply", applyOnSpawn)

function DisableEntityLighting(ent, toggleLighting, lightingMode, toggleShadow)
	toggleLighting = toggleLighting == true and true or false
	lightingMode = math.Round(math.Clamp(lightingMode or 0, 0, 2))
	toggleShadow = toggleShadow == true and true or false
	if not IsValid(ent) then return end

	if IsValid(ent.AttachedEntity) then
		ent = ent.AttachedEntity
	end

	ent:DrawShadow(not toggleShadow)
		
	if SERVER then
		net.Start("EntityLightingChange")
			net.WriteBool(toggleLighting)
			net.WriteInt(lightingMode, 3)
			net.WriteBool(toggleShadow)
			net.WriteEntity(ent)
		net.Broadcast()

		ent:SetNWBool("disablelighting", toggleLighting)
		ent:SetNWInt("disablelighting_lightingmode", lightingMode)
		ent:SetNWBool("disableshadow", toggleShadow)

		duplicator.StoreEntityModifier(ent, "DisableEntityLighting", {toggleLighting, lightingMode, toggleShadow})
	end

	if CLIENT then
		if toggleLighting then
			ent.RenderOverride = function(self)
				render.SuppressEngineLighting(toggleLighting)
				render.SetLightingMode(lightingMode)
				self:DrawModel(STUDIO_RENDER + STUDIO_STATIC_LIGHTING)
				render.SetLightingMode(0)
				render.SuppressEngineLighting(false)
			end
		else
			ent.RenderOverride = nil
		end
	end
end

hook.Add("OnEntityCreated", "lightingcheck", function(ent)
	timer.Simple(0.05, function()
		if not IsValid(ent) then return end
		local toggleLighting = ent:GetNWBool("disablelighting", false)
		local lightingMode = ent:GetNWInt("disablelighting_lightingmode", 0)
		local toggleShadow = ent:GetNWBool("disableshadow", false)

		if toggleLighting or toggleShadow then
			DisableEntityLighting(ent, toggleLighting, lightingMode, toggleShadow)
		end
	end)

end)

net.Receive("EntityLightingChange", function()
	local toggleLighting = net.ReadBool()
	local lightingMode = net.ReadInt(3)
	local toggleShadow = net.ReadBool()
	local ent = net.ReadEntity()
	
	DisableEntityLighting(ent, toggleLighting, lightingMode, toggleShadow)
end)

local function DupeLighting(ply, ent, data)
	local disableLighting = data[1] == true and true or false
	local lightingMode = data[2] or 1 -- im defaulting this to 1 here so it doesnt affect dupes from older versions of the tool
	local disableShadow = data[3] == true and true or false

	DisableEntityLighting(ent, disableLighting, lightingMode, disableShadow)
end
duplicator.RegisterEntityModifier("DisableEntityLighting", DupeLighting)

function TOOL:LeftClick(trace)
	local entity = trace.Entity
	if entity:IsWorld() then return false end
	if CLIENT then return true end

	local r = self:GetClientNumber("r", 255)
	local g = self:GetClientNumber("g", 255)
	local b = self:GetClientNumber("b", 255)
	local a = self:GetClientNumber("a", 255)

	local data = {}
	data.Color = {r = r, g = g, b = b, a = a}

	if a < 255 then
		data.RenderMode = RENDERMODE_TRANSCOLOR
		entity:SetRenderMode(data.RenderMode)
	end

	entity:SetColor(Color(r, g, b, a))
	
	duplicator.StoreEntityModifier(entity, "colour", data) -- this should already be registered by the color tool

	local lightingDisabled = self:GetClientNumber("lighting", 1) == 1 and true or false
	local lightingMode = self:GetClientNumber("mode", 1)
	local shadowDisabled = self:GetClientNumber("shadow", 0) == 1 and true or false

	DisableEntityLighting(entity, lightingDisabled, lightingMode, shadowDisabled)
	return true
end

function TOOL:RightClick(trace)
	local entity = trace.Entity
	if entity:IsWorld() then return false end
	if CLIENT then return true end
	
	local clr = entity:GetColor()
	self:GetOwner():ConCommand("disablelighting_r " .. clr.r)
	self:GetOwner():ConCommand("disablelighting_g " .. clr.g)
	self:GetOwner():ConCommand("disablelighting_b " .. clr.b)
	self:GetOwner():ConCommand("disablelighting_a " .. clr.a)
	self:GetOwner():ConCommand("disablelighting_mode " .. entity:GetNWInt("disablelighting_lightingmode", 0))
	self:GetOwner():ConCommand("disablelighting_shadow " .. (entity:GetNWBool("disableshadow", false) == true and "1" or "0"))
	
	return true
end

function TOOL:Reload(trace)
	local entity = trace.Entity
	if entity:IsWorld() then return false end
	if CLIENT then return true end

	entity:SetColor(Color(255,255,255,255))

	local data = {}
	data.Color = {r = 255, g = 255, b = 255, a = 255}
	data.RenderMode = RENDERMODE_NORMAL

	entity:SetColor(Color(255,255,255,255))
	entity:SetRenderMode(data.RenderMode)

	duplicator.StoreEntityModifier(entity, "colour", data)
	
	DisableEntityLighting(entity, false, 0, false)
	return true
end

function TOOL.BuildCPanel(CPanel)
	CPanel:AddControl("Header", { Text = "#Tool.disablelighting.name", Description = "#Tool.disablelighting.desc" })
	CPanel:CheckBox("Disable entity lighting", "disablelighting_lighting")
	CPanel:CheckBox("Disable entity shadows", "disablelighting_shadow")
	CPanel:CheckBox("Automatically apply on entity spawn", "disablelighting_spawn")
	CPanel:ColorPicker("Color", "disablelighting_r", "disablelighting_g", "disablelighting_b", "disablelighting_a")
	CPanel:AddControl( "ListBox", { Label = "Lighting Mode", Options = list.Get( "LightingModes" ) } )
end

list.Set("LightingModes", "Default", {disablelighting_mode = 0})
list.Set("LightingModes", "mat_fullbright", {disablelighting_mode = 1})
list.Set("LightingModes", "mat_fullbright + boost", {disablelighting_mode = 2})
