-- Bow animation template: 6 frames with named tags and preset timing.
do
  local spr = Sprite(16, 16) -- default canvas; adjust as needed

  -- Ensure only one layer and name it for clarity
  local baseLayer = spr.layers[1]
  baseLayer.name = "Base"

  -- Build frame stack (Sprite starts with 1 frame)
  for _ = 2, 6 do
    spr:newFrame()
  end

  -- Assign frame durations (seconds)
  spr.frames[1].duration = 1.0
  for i = 2, 6 do
    spr.frames[i].duration = 0.2
  end

  -- Tag each frame individually for quick reference
  spr:newTag{ from = 1, to = 1, name = "standby" }
  for i = 0, 4 do
    spr:newTag{ from = i + 2, to = i + 2, name = "pulling_" .. i }
  end

  app.alert{
    title = "Bow Template",
    text = {
      "16x16 (you can resize later) bow template with 6 frames.",
      "Frame 1 tag: standby (1.0s)",
      "Frames 2-6 tags: pulling_0-4 (0.2s each)",
      "All frames share a single 'Base' layer."
    }
  }
end
