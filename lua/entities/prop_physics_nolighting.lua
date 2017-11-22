AddCSLuaFile()

DEFINE_BASECLASS("base_anim")
ENT.PrintName = "no lighting prop"
ENT.Author = "Iced Coffee"
ENT.Purpose = "remove blacks"
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:Initialize()
	if not SERVER then return end
	self:DrawShadow(true)
	self:GetParent():SetNoDraw(true)
end

function ENT:Draw()
	if not IsValid(self) then return end
	if not IsValid(self:GetParent()) then self:Remove() return end
	self:SetColor(self:GetParent():GetColor())
	self:SetMaterial(self:GetParent():GetMaterial())
	self.RenderGroup = RENDERGROUP_BOTH

	render.SuppressEngineLighting(true)
	self:DrawModel()
	render.SuppressEngineLighting(false)

end
