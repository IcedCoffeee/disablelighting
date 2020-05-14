TOOL.Category		= "Render"
TOOL.Name			= "Disable Lighting"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if CLIENT then
	language.Add("Tool.disablelighting.name", "Disable Lighting")
	language.Add("Tool.disablelighting.desc", "Disables lighting on props.")
	language.Add("Tool.disablelighting.left", "Disable Lighting")
	language.Add("Tool.disablelighting.right", "Enable Lighting")
	language.Add("disablelighting_name", "Name:")
	TOOL.Information = {"left", "right"}
else
	util.AddNetworkString("EntityLightingChange")
end

local function DisableEntityLighting(ent, toggle)
	if not IsValid(ent) then return end
	
	if toggle then
		ent.RenderOverride = function(ent)
			render.SuppressEngineLighting(true)
			ent:DrawModel()
			render.SuppressEngineLighting(false)
		end
		
		ent.LightingDisabled = true
	else
		ent.RenderOverride = nil
		ent.LightingDisabled = false
	end
end

hook.Add("OnEntityCreated", "lightingcheck", function(ent)
	local toggle = ent:GetNWBool("disablelighting", false)
	
	if CLIENT and toggle then
		DisableEntityLighting(ent, true)
	end
end)

net.Receive("EntityLightingChange", function()
	local toggle = net.ReadBool()
	local ent = net.ReadEntity()
	if not IsValid(ent) then return end
	
	if toggle then
		DisableEntityLighting(ent, true)
	else
		DisableEntityLighting(ent, false)
	end
end)

local function DupeLighting(ply, ent, data)
	timer.Simple(0.05, function()
		net.Start("EntityLightingChange")
			net.WriteBool(data[1])
			net.WriteEntity(ent)
		net.Broadcast()
	end)
	
	ent:SetNWBool("disablelighting", true)
end
duplicator.RegisterEntityModifier("DisableEntityLighting", DupeLighting)

function TOOL:LeftClick(trace)
	local entity = trace.Entity
	if entity:IsWorld() or entity:IsPlayer() then return false end
	
	if SERVER then
		net.Start("EntityLightingChange")
			net.WriteBool(true)
			net.WriteEntity(entity)
		net.Broadcast()
		
		entity:SetNWBool("disablelighting", true)
		duplicator.StoreEntityModifier(entity, "DisableEntityLighting", {true})
	end
	return true
end


function TOOL:RightClick(trace)
	local entity = trace.Entity
	if entity:IsWorld() or entity:IsPlayer() then return false end
	
	if SERVER then
		net.Start("EntityLightingChange")
			net.WriteBool(false)
			net.WriteEntity(entity)
		net.Broadcast()
		
		entity:SetNWBool("disablelighting", false)
		duplicator.StoreEntityModifier(entity, "DisableEntityLighting", {false})
	end
	return true
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool.disablelighting.name", Description = "#Tool.disablelighting.desc" })
end
