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
     :entry{ id="output_dir", label="Output folder", text=defDir }
     -- The file widget is used here just to *choose a folder*; we take its directory.
     :file { id="output_dir_picker", label="Browse… (pick/enter any file inside target folder)",
             save=true, entry=true, filename=app.fs.joinPath(defDir, title .. ".png") }
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
    return app.alert("Both “Base item” and “Item name” are required.")
  end

  -- Resolve output directory:
  local outDir = trim(data.output_dir)
  if data.output_dir_picker and data.output_dir_picker ~= "" then
    outDir = app.fs.filePath(data.output_dir_picker)
  end
  if outDir == "" then outDir = defDir end
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
    local mf, mErr = io.open(mcmetaPath, "w")
    if not mf then return app.alert("Cannot write .mcmeta file:\n" .. tostring(mErr)) end
    mf:write(json.encode(meta))
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

  app.alert{
    title="CIT General Item",
    text=(include_anim and
      ("Wrote:\n" .. propsPath ..
       "\n\nExported (texture):\n" .. pngPath ..
       "\nAnimation (.mcmeta):\n" .. mcmetaPath ..
       (export_display and ("\nDisplay (GIF 600%):\n" .. displayGif) or "")) or
      ("Wrote:\n" .. propsPath ..
       "\n\nExported (texture):\n" .. pngPath ..
       (export_display and ("\nDisplay (PNG 600%):\n" .. displayPng) or "")))
  }
end
