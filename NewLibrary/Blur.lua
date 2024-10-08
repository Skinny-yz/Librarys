local Blur = {};

local Lighting = game:GetService("Lighting");
local RunService = game:GetService("RunService");

Blur.BlurEnabled = {}

function Blur.new(frame, blurIntensity)
	local self = setmetatable({
		blurIntensity = blurIntensity or 0.5;
		depthOfField = Instance.new("DepthOfFieldEffect");
		root = Instance.new("Folder");

		parts = {};
		parents = {};

		camera = workspace.CurrentCamera;
		bindId = "neon:blur_effect";

		frame = Instance.new("Frame");
		folder = Instance.new("Folder");
		owner = frame;

	}, Blur);

	table.insert(Blur.BlurEnabled, frame)

	self.depthOfField.Name = "";
	self.depthOfField.Parent = Lighting;
	self.depthOfField.FarIntensity = 0;
	self.depthOfField.FocusDistance = 51.6;
	self.depthOfField.InFocusRadius = 50;
	self.depthOfField.NearIntensity = self.blurIntensity;

	self.root.Name = "blurSnox";
	self.root.Parent = self.camera;

	self.frame.Name = "blurEffect";
	self.frame.Parent = frame;
	self.frame.Size = UDim2.new(0.95, 0, 0.95, 0);
	self.frame.Position = UDim2.new(0.5, 0, 0.5, 0);
	self.frame.AnchorPoint = Vector2.new(0.5, 0.5);
	self.frame.BackgroundTransparency = 1;

	self.folder.Parent = self.root;
	self.folder.Name = self.frame.Name;
	self.parents[#self.parents + 1] = self.frame;

	local continue = self:isNotNaN(self.camera:ScreenPointToRay(0, 0).Origin.x);
	while (not continue) do
		RunService.RenderStepped:Wait();
		continue = self:isNotNaN(self.camera:ScreenPointToRay(0, 0).Origin.x);
	end;

	self:bindToRenderStep();

	return self;
end;

function Blur:isNotNaN(x)
	return x == x;
end;

function Blur:updateOrientation(fetchProperties)
	local properties = {
		Transparency = 0.98;
		BrickColor = BrickColor.new('Institutional white');
	};

	local zIndex = (1 - 0.05 * self.frame.ZIndex);

	local tl, br = self.frame.AbsolutePosition, self.frame.AbsolutePosition + self.frame.AbsoluteSize
	local tr, bl = Vector2.new(br.x, tl.y), Vector2.new(tl.x, br.y)

	local rot = 0;

	for _, v in ipairs(self.parents) do
		rot = rot + v.Rotation
	end

	if rot ~= 0 and rot%180 ~= 0 then
		local mid, s, c, vec = tl:lerp(br, 0.5), math.sin(math.rad(rot)), math.cos(math.rad(rot)), tl;
		tl = Vector2.new(c*(tl.x - mid.x) - s*(tl.y - mid.y), s*(tl.x - mid.x) + c*(tl.y - mid.y)) + mid;
		tr = Vector2.new(c*(tr.x - mid.x) - s*(tr.y - mid.y), s*(tr.x - mid.x) + c*(tr.y - mid.y)) + mid;
		bl = Vector2.new(c*(bl.x - mid.x) - s*(bl.y - mid.y), s*(bl.x - mid.x) + c*(bl.y - mid.y)) + mid;
		br = Vector2.new(c*(br.x - mid.x) - s*(br.y - mid.y), s*(br.x - mid.x) + c*(br.y - mid.y)) + mid;
	end

	self:drawQuad(
		self.camera:ScreenPointToRay(tl.x, tl.y, zIndex).Origin,
		self.camera:ScreenPointToRay(tr.x, tr.y, zIndex).Origin,
		self.camera:ScreenPointToRay(bl.x, bl.y, zIndex).Origin,
		self.camera:ScreenPointToRay(br.x, br.y, zIndex).Origin,
		self.parts
	);

	if (fetchProperties) then
		for _, pt in pairs(self.parts) do
			pt.Parent = self.folder
		end;

		for propName, propValue in pairs(properties) do
			for _, pt in pairs(self.parts) do
				pt[propName] = propValue;
			end;
		end;
	end;
end;

function Blur:drawQuad(v1, v2, v3, v4, parts)
	parts[1], parts[2] = self:drawTriangle(v1, v2, v3, parts[1], parts[2]);
	parts[3], parts[4] = self:drawTriangle(v3, v2, v4, parts[3], parts[4]);
end;

function Blur:drawTriangle(v1, v2, v3, p0, p1)
	local s1 = (v1 - v2).magnitude;
	local s2 = (v2 - v3).magnitude;
	local s3 = (v3 - v1).magnitude;

	local smax = math.max(s1, s2, s3);

	local A, B, C
	if (s1 == smax) then
		A, B, C = v1, v2, v3;
	elseif (s2 == smax) then
		A, B, C = v2, v3, v1;
	elseif (s3 == smax) then
		A, B, C = v3, v1, v2;
	end;

	local para = ((B - A).x * (C - A).x + (B - A).y * (C - A).y + (B - A).z * (C - A).z) / (A - B).magnitude;
	local perp = math.sqrt((C - A).magnitude ^ 2 - para * para);
	local dif_para = (A - B).magnitude - para;

	local st = CFrame.new(B, A);
	local za = CFrame.Angles(math.pi / 2, 0, 0);

	local cf0 = st;

	local Top_Look = (cf0 * za).lookVector;
	local Mid_Point = A + CFrame.new(A, B).lookVector * para;
	local Needed_Look = CFrame.new(Mid_Point, C).lookVector;
	local dot = (Top_Look.x * Needed_Look.x + Top_Look.y * Needed_Look.y + Top_Look.z * Needed_Look.z);

	local ac = CFrame.Angles(0, 0, math.acos(dot))

	cf0 = (cf0 * ac)

	if ((cf0 * za).lookVector - Needed_Look).magnitude > 0.01 then
		cf0 = cf0 * CFrame.Angles(0, 0, -2 * math.acos(dot))
	end

	cf0 = (cf0 * CFrame.new(0, perp / 2, -(dif_para + para / 2)));

	local cf1 = st * ac * CFrame.Angles(0, math.pi, 0)
	if (((cf1 * za).lookVector - Needed_Look).magnitude > 0.01) then
		cf1 = cf1 * CFrame.Angles(0, 0, 2 * math.acos(dot))
	end

	cf1 = cf1 * CFrame.new(0, perp / 2, dif_para / 2);

	if (not p0) then
		p0 = Instance.new('Part');
		p0.FormFactor = "Custom";
		p0.TopSurface = 0;
		p0.BottomSurface = 0;
		p0.Anchored = true;
		p0.CanCollide = false;
		p0.CastShadow = false;
		p0.Material = Enum.Material.Glass;
		p0.Size = Vector3.new(0.2, 0.2, 0.2);

		local mesh = Instance.new("SpecialMesh", p0);
		mesh.MeshType = 2;
		mesh.Name = "WedgeMesh"
	end;

	p0.WedgeMesh.Scale = Vector3.new(0, perp / 0.2, para / 0.2);
	p0.CFrame = cf0;

	if (not p1) then
		p1 = p0:clone();
	end;

	p1.WedgeMesh.Scale = Vector3.new(0, perp / 0.2, dif_para / 0.2);
	p1.CFrame = cf1;

	return p0, p1;
end;

function Blur:setBlurIntensity(intensity)
	self.blurIntensity = intensity;
	self.depthOfField.NearIntensity = intensity;
end;

function Blur:bindToRenderStep()
	self:updateOrientation(true);
	RunService:BindToRenderStep(self.bindId, 2000, function()
		self:updateOrientation(true);
	end);
end;

Blur.__index = Blur;
return Blur;
