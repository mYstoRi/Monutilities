-- Export bow animation frames into individual PNGs and write CIT properties.
do
  local spr = app.sprite
  if not spr then return app.alert("No active sprite. Open your bow .aseprite first.") end

  if not spr.filename or spr.filename == "" then
    local choice = app.alert{
      title = "Save required",
      text = "Please save this sprite so the exporter knows where to write files.",
      buttons = { "Save Now", "Cancel" }
    }
    if choice == 1 then app.command.SaveFile() else return end
    if spr.filename == "" then return app.alert("Sprite is still unsaved. Aborting export.") end
  end

  local function trim(s)
    return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
  end

  local title = app.fs.fileTitle(spr.filename)
  local defDir = app.fs.filePath(spr.filename)

  local dlg = Dialog{ title = "CIT: Bow Export" }
  dlg:entry{ id = "item_name", label = "Display name", text = title, focus = true }
     :entry{ id = "input_model", label = "Model (optional)", text = "" }
     :file { id = "output_path", label = "Output location (pick/enter file)", save = true, entry = true, filename = app.fs.joinPath(defDir, title .. ".png") }
     :check{ id = "export_display", label = "Display GIF", text = "Also export 600% animated preview", selected = false }
     :button{ id = "ok", text = "Export" }
     :button{ id = "cancel", text = "Cancel" }
     :show()

  local data = dlg.data
  if not data.ok then return end

  local item_name = trim(data.item_name)
  if item_name == "" then
    return app.alert("Display name cannot be empty.")
  end
  local input_model = trim(data.input_model)
  local export_display = data.export_display and true or false

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
  if outDir == "" then outDir = defDir end
  app.fs.makeAllDirectories(outDir)

  if #spr.frames < 6 then
    return app.alert("Expected at least 6 frames (standby + pulling_0-4).")
  end

  local function exportFramePng(sourceSpr, frameIndex, outPath)
    local tmp = Sprite(sourceSpr)
    app.activeSprite = tmp
    for i = #tmp.frames, 1, -1 do
      if i ~= frameIndex then
        tmp:deleteFrame(tmp.frames[i])
      end
    end
    tmp:flatten()
    tmp:saveCopyAs(outPath)
    tmp:close()
  end

  local function scaleActiveSprite600()
    local s = app.sprite
    local newW, newH = s.width * 6, s.height * 6
    app.command.SpriteSize{ ui = false, width = newW, height = newH, method = "nearest", lockRatio = true }
  end

  local frameFiles = {
    { index = 1, filename = app.fs.joinPath(outDir, title .. ".png") },
    { index = 2, filename = app.fs.joinPath(outDir, title .. "_pulling_0.png") },
    { index = 3, filename = app.fs.joinPath(outDir, title .. "_pulling_1.png") },
    { index = 4, filename = app.fs.joinPath(outDir, title .. "_pulling_2.png") },
    { index = 5, filename = app.fs.joinPath(outDir, title .. "_pulling_3.png") },
    { index = 6, filename = app.fs.joinPath(outDir, title .. "_pulling_4.png") }
  }

  for _, spec in ipairs(frameFiles) do
    exportFramePng(spr, spec.index, spec.filename)
  end

  local propsPath = app.fs.joinPath(outDir, title .. ".properties")
  local propsLines = {
    "type=item",
    "items=bow",
    "texture=" .. title
  }
  for i = 0, 4 do
    table.insert(propsLines, ("texture.bow_pulling_%d=%s"):format(i, title .. "_pulling_" .. i))
  end
  if input_model ~= "" then
    table.insert(propsLines, "model=optifine/cit/source_models/" .. input_model)
  end
  table.insert(propsLines, "nbt.plain.display.Name=" .. item_name)

  local fh, err = io.open(propsPath, "w")
  if not fh then return app.alert("Cannot write properties file:\n" .. tostring(err)) end
  fh:write(table.concat(propsLines, "\n") .. "\n")
  fh:close()

  local displayGif = app.fs.joinPath(outDir, title .. "_display.gif")
  if export_display then
    local tmp = Sprite(spr)
    app.activeSprite = tmp
    tmp:flatten()
    scaleActiveSprite600()
    tmp:saveCopyAs(displayGif)
    tmp:close()
  end

  local report = {
    "Export complete:",
    "  Frame 1: " .. frameFiles[1].filename,
    "  Frame 2: " .. frameFiles[2].filename,
    "  Frame 3: " .. frameFiles[3].filename,
    "  Frame 4: " .. frameFiles[4].filename,
    "  Frame 5: " .. frameFiles[5].filename,
    "  Frame 6: " .. frameFiles[6].filename,
    "  Properties: " .. propsPath
  }
  if export_display then
    report[#report + 1] = "  Display GIF: " .. displayGif
  end

  app.alert{ title = "Bow Export", text = report }
end
