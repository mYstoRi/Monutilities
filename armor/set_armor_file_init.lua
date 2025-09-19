local sprite = Sprite(80, 64)

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

local SArmorLayer1 = sprite:newSlice{16, 0, 64, 32}
local SArmorLayer2 = sprite:newSlice{16, 32, 64, 32}
local SIconHelmet = sprite:newSlice{0, 0, 16, 16}
local SIconChestplate = sprite:newSlice{0, 16, 16, 16}
local SIconLeggings = sprite:newSlice{0, 32, 16, 16}
local SIconBoots = sprite:newSlice{0, 48, 16, 16}

SArmorLayer1.name = "layer_1"
SArmorLayer2.name = "layer_2"

local dlg = Dialog()
dlg:entry{id="SuffixHelmet", label="Enter helmet suffix:"}
dlg:entry{id="SuffixChestplate", label="Enter chestplate suffix:"}
dlg:entry{id="SuffixLeggings", label="Enter leggings suffix:"}
dlg:entry{id="SuffixBoots", label="Enter boots suffix:"}
dlg:button{id="Confirm", text="Confirm"}
dlg:show()

local data = dlg.data

SIconHelmet.name = data.SuffixHelmet .. "_icon"
SIconChestplate.name = data.SuffixChestplate .. "_icon"
SIconLeggings.name = data.SuffixLeggings .. "_icon"
SIconBoots.name = data.SuffixBoots .. "_icon"
