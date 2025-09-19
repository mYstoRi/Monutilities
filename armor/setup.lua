-- Armor file template: 80x32 (icon 16x16 at left, armor 64x32 at right)
-- Layers: Base, DefaultDye (Multiply), CustomDye (Multiply), Override
-- Slices: "icon" and "armor"
-- Based on your previous spec.  :contentReference[oaicite:1]{index=1}

do
  local spr = Sprite(80, 32) -- RGBA by default

  -- Layers
  local LBase        = spr:newLayer()
  local LDefaultDye  = spr:newLayer()
  local LCustomDye   = spr:newLayer()
  local LOverride    = spr:newLayer()

  LBase.name        = "Base"
  LDefaultDye.name  = "DefaultDye"
  LCustomDye.name   = "CustomDye"
  LOverride.name    = "Override"

  LDefaultDye.blendMode = BlendMode.MULTIPLY
  LCustomDye.blendMode  = BlendMode.MULTIPLY

  -- Remove the auto-created "Layer 1"
  spr:deleteLayer("Layer 1")

  -- Slices
  local SArmor = spr:newSlice{16, 0, 64, 32}
  local SIcon  = spr:newSlice{0, 0, 16, 16}
  SArmor.name = "armor"
  SIcon.name  = "icon"

  app.alert{
    title="Armor Template",
    text={
      "Created new 80x32 sprite with:",
      "• Layers: Base, DefaultDye (×), CustomDye (×), Override",
      "• Slices: icon (16×16), armor (64×32)",
      "",
      "Tip: Put the dyeable (white) pixels on Base.",
      "Put untinted detail on Override."
    }
  }
end
