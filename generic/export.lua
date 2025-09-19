-- CIT Resewn "general item" with optional animation, custom output folder,
-- display exports, and model selection.
do
  local spr = app.sprite
  if not spr then return app.alert("No active sprite. Open your .aseprite first.") end

  -- Ensure the sprite is saved so we know a sane default output folder
  if not spr.filename or spr.filename == "" then
    local choice = app.alert{
      title="Save required",
      text="Please save this sprite so the script can write next to it.",
      buttons={"Save Now","Cancel"}
    }
    if choice == 1 then app.command.SaveFile() else return end
    if spr.filename == "" then return app.alert("Sprite is still unsaved. Aborting.") end
  end

  local title = app.fs.fileTitle(spr.filename) -- e.g. "example"
  local defDir = app.fs.filePath(spr.filename)

  --------------------------------------------------------------------------
  -- Dialog: General + Output tabs
  --------------------------------------------------------------------------
  local dlg = Dialog{ title="CIT: General Item" }
  dlg:tab{ id="tab_general", text="General" }                  -- start tabs
     :entry{ id="base_item",   label="Base item", text="minecraft:stick", focus=true }
     :entry{ id="item_name",   label="Item name", text=title }
     :entry{ id="input_model", label="Model (optional)", text="" }
     :check{ id="include_anim", label="Include animation",
             text="Export vertical strip + write .png.mcmeta", selected=false }

  dlg:tab{ id="tab_output", text="Output" }
     -- Use file picker to choose the target folder.
     :file { id="output_path", label="Browse... (pick/enter any file inside target folder)", save=true, entry=true, filename=app.fs.joinPath(defDir, title .. ".png") }
     :check{ id="export_display", label="Display export",
             text="Also export 600% preview (PNG/GIF)", selected=false }

  dlg:endtabs{ id="tabs", selected="tab_general" }             -- end tabs
     :button{ id="ok", text="Create" }
     :button{ id="cancel", text="Cancel" }
     :show()

  local data = dlg.data
  if not data.ok then return end

  local function trim(s) return (s or ""):gsub("^%s+",""):gsub("%s+$","") end
  local base_item     = trim(data.base_item)
  local item_name     = trim(data.item_name)
  local input_model   = trim(data.input_model)
  local include_anim  = data.include_anim and true or false
  local export_display= data.export_display and true or false

  if base_item == "" or item_name == "" then
    return app.alert("Both \"Base item\" and \"Item name\" are required.")
  end

  -- Resolve output directory from file picker
  local chosenPath = trim(data.output_path or "")
  local outDir = defDir
  if chosenPath ~= "" then
    local resolved = app.fs.filePath(chosenPath)
    if resolved ~= "" then
      outDir = resolved
    else
      outDir = chosenPath
    end
  end
  app.fs.makeAllDirectories(outDir)

  -- Output paths
  local propsPath    = app.fs.joinPath(outDir, title .. ".properties")
  local pngPath      = app.fs.joinPath(outDir, title .. ".png")
  local mcmetaPath   = pngPath .. ".mcmeta"
  local displayPng   = app.fs.joinPath(outDir, title .. "_display.png")
  local displayGif   = app.fs.joinPath(outDir, title .. "_display.gif")

  --------------------------------------------------------------------------
  -- 1) Write <title>.properties
  --------------------------------------------------------------------------
  local propsLines = {
    "type=item",
    "items=" .. base_item,
  }
  if input_model ~= "" then
    table.insert(propsLines, "model=optifine/cit/source_models/" .. input_model)
  end
  table.insert(propsLines, "texture=" .. title)
  table.insert(propsLines, "nbt.plain.display.Name=" .. item_name)

  local fh, err = io.open(propsPath, "w")
  if not fh then return app.alert("Cannot write properties file:\n" .. tostring(err)) end
  fh:write(table.concat(propsLines, "\n") .. "\n")
  fh:close()

  --------------------------------------------------------------------------
  -- Helpers for display export (scale sprite 600% with nearest)
  --------------------------------------------------------------------------
  local function scaleActiveSprite600()
    -- Active sprite must be the one we want to scale. After Sprite(spr),
    -- the duplicate becomes active. We'll use absolute width/height. :contentReference[oaicite:7]{index=7}
    local s = app.sprite
    local newW, newH = s.width * 6, s.height * 6
    app.command.SpriteSize{ ui=false, width=newW, height=newH, method="nearest", lockRatio=true } -- :contentReference[oaicite:8]{index=8}
  end

  --------------------------------------------------------------------------
  -- Helpers for pretty print json
  --------------------------------------------------------------------------
local function json_pretty(minified, indent)
  indent = indent or "  " -- two spaces
  local out, level, in_str, esc = {}, 0, false, false

  for i = 1, #minified do
    local ch = minified:sub(i, i)
    if in_str then
      table.insert(out, ch)
      if esc then
        esc = false
      elseif ch == "\\" then
        esc = true
      elseif ch == '"' then
        in_str = false
      end
    else
      if ch == '"' then
        in_str = true
        table.insert(out, ch)
      elseif ch == "{" or ch == "[" then
        table.insert(out, ch)
        level = level + 1
        table.insert(out, "\n" .. string.rep(indent, level))
      elseif ch == "}" or ch == "]" then
        level = level - 1
        table.insert(out, "\n" .. string.rep(indent, level) .. ch)
      elseif ch == "," then
        table.insert(out, ch .. "\n" .. string.rep(indent, level))
      elseif ch == ":" then
        table.insert(out, ": ")
      elseif ch:match("%s") then
        -- skip whitespace from minified input
      else
        table.insert(out, ch)
      end
    end
  end
  return table.concat(out)
end

  --------------------------------------------------------------------------
  -- 2) Export PNG + (optional) .png.mcmeta + (optional) display preview
  --------------------------------------------------------------------------
  if include_anim then
    -- 2a) Export a VERTICAL sprite sheet (one column) as <title>.png
    app.command.ExportSpriteSheet{
      ui=false, askOverwrite=false,
      type=SpriteSheetType.VERTICAL,                 -- one frame per row  :contentReference[oaicite:9]{index=9}
      textureFilename=pngPath,
      splitLayers=false, splitTags=false,
      listLayers=false, listTags=false, listSlices=false,
      trim=false, trimSprite=false, trimByGrid=false,
      ignoreEmpty=false, openGenerated=false,
    }

    -- 2b) Build animation metadata (index 0-based, time in ticks)
    -- Aseprite frame.duration is in SECONDS -> ticks = round(seconds * 20). :contentReference[oaicite:10]{index=10}
    local frames = {}
    local function roundInt(x) return math.floor(x + 0.5) end
    for i = 1, #spr.frames do
      local secs  = spr.frames[i].duration
      local ticks = roundInt(secs * 20)              -- 20 ticks per second
      if ticks < 1 then ticks = 1 end
      frames[#frames+1] = { index = i-1, time = ticks }
    end
    local meta = { animation = { frames = frames } }

    local minified = json.encode(meta)
    local pretty   = json_pretty(minified, "  ") -- 2-space indent (change if you like)

    local mf, mErr = io.open(mcmetaPath, "w")
    if not mf then return app.alert("Cannot write .mcmeta file:\n" .. tostring(mErr)) end
    mf:write(pretty .. "\n")                     -- optional trailing newline
    mf:close()

    -- 2c) Optional display GIF at 600% (all frames)
    if export_display then
      local tmp = Sprite(spr)    -- duplicate; becomes active sprite  :contentReference[oaicite:11]{index=11}
      tmp:flatten()
      scaleActiveSprite600()
      tmp:saveCopyAs(displayGif) -- animated GIF export  :contentReference[oaicite:12]{index=12}
      tmp:close()
    end
  else
    -- Non-animated: export a single flattened PNG (active frame)
    local activeFrame = app.frame.frameNumber
    local tmp = Sprite(spr)      -- duplicate; becomes active  :contentReference[oaicite:13]{index=13}
    for i = #tmp.frames, 1, -1 do
      if i ~= activeFrame then tmp:deleteFrame(tmp.frames[i]) end
    end
    tmp:flatten()
    tmp:saveCopyAs(pngPath)      -- PNG export  :contentReference[oaicite:14]{index=14}

    if export_display then
      scaleActiveSprite600()
      tmp:saveCopyAs(displayPng) -- 600% preview PNG
    end
    tmp:close()
  end

  -- Build a multi-line message for app.alert{ text = { ... } }
local lines = { "Wrote:", propsPath, "", "Exported (texture):", pngPath }

if include_anim then
  lines[#lines+1] = ""
  lines[#lines+1] = "Animation (.mcmeta):"
  lines[#lines+1] = mcmetaPath
end

if export_display then
  lines[#lines+1] = ""
  lines[#lines+1] = include_anim and "Display (GIF 600%):" or "Display (PNG 600%):"
  lines[#lines+1] = include_anim and displayGif or displayPng
end

app.alert{
  title = "CIT General Item",
  text  = lines
}

end
