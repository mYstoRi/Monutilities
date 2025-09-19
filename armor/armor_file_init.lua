local sprite = Sprite(80, 32)

-- layers

local LBase = sprite:newLayer()
local LDefaultDye = sprite:newLayer()
local LCustomDye = sprite:newLayer()
local LOverride = sprite:newLayer()

LBase.name = "Base"
LDefaultDye.name = "DefaultDye"
LCustomDye.name = "CustomDye"
LOverride.name = "Override"

LDefaultDye.blendMode = BlendMode.MULTIPLY
LCustomDye.blendMode = BlendMode.MULTIPLY

sprite:deleteLayer("Layer 1")

-- Slices

local SArmor = sprite:newSlice{16, 0, 64, 32}
local SIcon = sprite:newSlice{0, 0, 16, 16}

SArmor.name = "armor"
SIcon.name = "icon"
