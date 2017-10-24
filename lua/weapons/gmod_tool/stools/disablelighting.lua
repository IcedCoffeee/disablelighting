TOOL.Category		= "Render"
TOOL.Name			= "Disable Lighting"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
	language.Add( "Tool.disablelighting.name", "Disable Lighting" )
	language.Add( "Tool.disablelighting.desc", "Disables lighting on props." )
	language.Add( "Tool.disablelighting.left", "Disable Lighting" )
	language.Add( "Tool.disablelighting.right", "Enable Lighting" )
	language.Add( "disablelighting_name", "Name:" )
	TOOL.Information = { "left", "right" }
end

local function IsLightingDisabled(ent)
	for k,v in pairs(ent:GetChildren()) do
		if v:GetClass() == "prop_physics_nolighting" then
			return true
		end
	end
	return false
end

function TOOL:LeftClick(trace)
	local entity = trace.Entity
	if entity:IsWorld() or entity:IsPlayer() then return false end
	if SERVER then
		if IsLightingDisabled(entity) then return true end
		local ent = ents.Create("prop_physics_nolighting")
		ent:SetPos(entity:GetPos())
		ent:SetAngles(entity:GetAngles())
		ent:SetModel(entity:GetModel())
		ent:SetParent(entity)
		ent:SetRenderMode(RENDERMODE_TRANSALPHA)
		ent:Spawn()
	end
	return true
end


function TOOL:RightClick(trace)
	local entity = trace.Entity
	if entity:IsWorld() or entity:IsPlayer() then return false end
	if CLIENT then
		entity:SetNoDraw(false)
	else
		entity:SetNoDraw(false)
		for k,v in pairs(entity:GetChildren()) do
			if v:GetClass() == "prop_physics_nolighting" then
				v:Remove()
			end
		end
	end
	return true
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool.disablelighting.name", Description = "#Tool.disablelighting.desc" })
end
