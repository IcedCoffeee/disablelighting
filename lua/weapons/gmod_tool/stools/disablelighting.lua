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

function DisableEntityLighting(ent, toggle)
	if not IsValid(ent) then return end

	if ent:GetClass() == "prop_effect" and IsValid(ent.AttachedEntity) then
		ent = ent.AttachedEntity
	end
		
	if SERVER then
		net.Start("EntityLightingChange")
			net.WriteBool(toggle)
			net.WriteEntity(ent)
		net.Broadcast()
		
		ent:SetNWBool("disablelighting", toggle)
		duplicator.StoreEntityModifier(ent, "DisableEntityLighting", {toggle})
	else
		if toggle then
			ent.RenderOverride = function(ent)
				render.SuppressEngineLighting(true)
				render.SetLightingMode(1)
				ent:DrawModel()
				render.SetLightingMode(0)
				render.SuppressEngineLighting(false)
			end
		else
			ent.RenderOverride = nil
		end
	end
end

hook.Add("OnEntityCreated", "lightingcheck", function(ent)
	local toggle = ent:GetNWBool("disablelighting", false)
	
	if toggle then
		timer.Simple(0.05, function()
			DisableEntityLighting(ent, true)
		end)
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
		DisableEntityLighting(ent, data[1])
	end)
end
duplicator.RegisterEntityModifier("DisableEntityLighting", DupeLighting)

function TOOL:LeftClick(trace)
	local entity = trace.Entity
	if entity:IsWorld() then return false end
	if CLIENT then return true end
	
	DisableEntityLighting(entity, true)
	return true
end

function TOOL:RightClick(trace)
	local entity = trace.Entity
	if entity:IsWorld() then return false end
	if CLIENT then return true end
	
	DisableEntityLighting(entity, false)
	return true
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool.disablelighting.name", Description = "#Tool.disablelighting.desc" })
end
