-- Export armor & icon PNGs from slices and write CIT .properties (item + armor)
-- Changes per spec:
--    Select "part" (helmet/chestplate/leggings/boots); internally leggings => layer_2, others => layer_1
--    Always export icon; always export overlays for leather (may be empty)
--    Filenames: <title>_icon(.png/_overlay.png), <title>_armor(.png/_overlay.png)
--    Exclude DefaultDye/CustomDye from all exports
--    Properties:
--      - <title>_item.properties  (type=item, texture=<title>_icon)
--      - <title>_armor.properties (type=armor, texture.<vanilla_key>=<title>_armor[, _overlay])
--
-- Requires an open/saved .aseprite built like the init template:
--  slices: "icon", "armor" ; layers: Base, DefaultDye (x), CustomDye (x), Override
-- (Template reference.)  <-- matches your armor_file_init.lua
-- 
-- If material= "turtle", only "helmet" is supported.

do
  local spr = app.sprite
  if not spr then return app.alert("Open your armor .aseprite first.") end
  if not spr.filename or spr.filename == "" then
    return app.alert("Please save this sprite to disk first (needed to pick an output folder).")
  end

  -- ---------- Helpers ----------
  local function trim(s) return (s or ""):gsub("^%s+",""):gsub("%s+$","") end

  local function findSliceByName(s, name)
    for _, sl in ipairs(s.slices) do
      if sl.name == name then return sl end
    end
    return nil
  end

  local function setOnlyTheseLayersVisible(s, namesSet)
    for _, L in ipairs(s.layers) do
      L.isVisible = (namesSet[L.name] == true)
    end
  end

  local function exportRegionPng(sourceSpr, rect, visibleLayerNames, outPath)
    -- Duplicate so we don't alter user's doc
    local tmp = Sprite(sourceSpr)
    app.activeSprite = tmp

    -- Build a visibility set: include only requested layers
    local vis = {}
    for _, n in ipairs(visibleLayerNames or {}) do vis[n] = true end
    -- Exclude DefaultDye/CustomDye regardless
    vis["DefaultDye"] = false
    vis["CustomDye"]  = false

    setOnlyTheseLayersVisible(tmp, vis)

    app.command.CropSprite{ x=rect.x, y=rect.y, width=rect.width, height=rect.height }
    -- tmp:flatten() -- no need to flatten, just export visible layers
    tmp:saveCopyAs(outPath)
    tmp:close()
  end

  local function writeFile(path, text)
    local f, err = io.open(path, "w")
    if not f then error("Cannot write file:\n"..path.."\n"..tostring(err)) end
    f:write(text)
    f:close()
  end

  -- ---------- Slices ----------
  local slIcon  = findSliceByName(spr, "icon")
  local slArmor = findSliceByName(spr, "armor")
  if not slIcon  then return app.alert("Missing slice named 'icon'.") end
  if not slArmor then return app.alert("Missing slice named 'armor'.") end

  local title   = app.fs.fileTitle(spr.filename)
  local defDir  = app.fs.filePath(spr.filename)

  -- ---------- Material/Part presets ----------
  local MAT = {
    leather   = {
      itemsByPart = {
        helmet="leather_helmet", chestplate="leather_chestplate",
        leggings="leather_leggings", boots="leather_boots"
      },
      keys  = {
        layer_1="leather_layer_1", layer_2="leather_layer_2",
        ov1="leather_layer_1_overlay", ov2="leather_layer_2_overlay"
      },
      supports = {helmet=true, chestplate=true, leggings=true, boots=true},
      hasOverlay = true
    },
    chainmail = {
      itemsByPart = {
        helmet="chainmail_helmet", chestplate="chainmail_chestplate",
        leggings="chainmail_leggings", boots="chainmail_boots"
      },
      keys  = { layer_1="chainmail_layer_1", layer_2="chainmail_layer_2" },
      supports = {helmet=true, chestplate=true, leggings=true, boots=true},
      hasOverlay = false
    },
    iron      = {
      itemsByPart = {
        helmet="iron_helmet", chestplate="iron_chestplate",
        leggings="iron_leggings", boots="iron_boots"
      },
      keys  = { layer_1="iron_layer_1", layer_2="iron_layer_2" },
      supports = {helmet=true, chestplate=true, leggings=true, boots=true},
      hasOverlay = false
    },
    golden    = {
      itemsByPart = {
        helmet="golden_helmet", chestplate="golden_chestplate",
        leggings="golden_leggings", boots="golden_boots"
      },
      keys  = { layer_1="gold_layer_1", layer_2="gold_layer_2" },
      supports = {helmet=true, chestplate=true, leggings=true, boots=true},
      hasOverlay = false
    },
    diamond   = {
      itemsByPart = {
        helmet="diamond_helmet", chestplate="diamond_chestplate",
        leggings="diamond_leggings", boots="diamond_boots"
      },
      keys  = { layer_1="diamond_layer_1", layer_2="diamond_layer_2" },
      supports = {helmet=true, chestplate=true, leggings=true, boots=true},
      hasOverlay = false
    },
    netherite = {
      itemsByPart = {
        helmet="netherite_helmet", chestplate="netherite_chestplate",
        leggings="netherite_leggings", boots="netherite_boots"
      },
      keys  = { layer_1="netherite_layer_1", layer_2="netherite_layer_2" },
      supports = {helmet=true, chestplate=true, leggings=true, boots=true},
      hasOverlay = false
    },
    turtle    = {
      itemsByPart = { helmet="turtle_helmet" }, -- MC only
      keys  = { layer_1="turtle_layer_1", layer_2="turtle_layer_2" },
      supports = {helmet=true, chestplate=false, leggings=false, boots=false},
      hasOverlay = false
    },
  }

  -- ---------- Dialog ----------
  local dlg = Dialog{ title="CIT: Export Armor" }
  dlg:combobox{
        id="material", label="Material",
        option="leather",
        options={"leather","chainmail","iron","golden","diamond","netherite","turtle"}
      }
     :combobox{
        id="part", label="Part",
        option="helmet",
        options={"helmet","chestplate","leggings","boots"}
      }
     :entry{ id="item_name", label="Match Name (optional)", text=title }
     :file { id="out_path", label="Output location (pick/enter file)", save=true, entry=true, filename=app.fs.joinPath(defDir, title .. "_armor.png") }
     :button{ id="ok", text="Export" }
     :button{ id="cancel", text="Cancel" }
     :show()

  local data = dlg.data
  if not data.ok then return end

  local material = data.material
  local part     = data.part
  local matInfo  = MAT[material]
  if not matInfo then return app.alert("Unsupported material: "..tostring(material)) end
  if not matInfo.supports[part] then
    return app.alert("Material '"..material.."' does not support part '"..part.."'.")
  end

  -- Resolve which layer by part: leggings => layer_2, others => layer_1
  local layerSel = (part == "leggings") and "layer_2" or "layer_1"

  -- Output folder (derived from file picker)
  local chosenPath = trim(data.out_path or "")
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

  -- Items list derived from material/part presets
  local itemsList = matInfo.itemsByPart[part]
  if not itemsList then
    return app.alert("No default item id for " .. material .. " " .. part)
  end


  -- ---------- Paths ----------
  local iconPng           = app.fs.joinPath(outDir, title .. "_icon.png")
  local iconOverlayPng    = app.fs.joinPath(outDir, title .. "_icon_overlay.png")
  local armorPng          = app.fs.joinPath(outDir, title .. "_armor.png")
  local armorOverlayPng   = app.fs.joinPath(outDir, title .. "_armor_overlay.png")

  local itemPropsPath     = app.fs.joinPath(outDir, title .. "_icon.properties")
  local armorPropsPath    = app.fs.joinPath(outDir, title .. "_armor.properties")

  -- ---------- Export ICON ----------
  -- Base icon:
  --   * leather -> Base only (tinted in your pipeline), overlay separate
  --   * others  -> Base + Override
  if material == "leather" then
    exportRegionPng(spr, slIcon.bounds,  { "Base" }, iconPng)
    -- Always export overlay for leather (may be empty)
    exportRegionPng(spr, slIcon.bounds,  { "Override" }, iconOverlayPng)
  else
    exportRegionPng(spr, slIcon.bounds,  { "Base", "Override" }, iconPng)
    -- No overlay for non-leather
  end

  -- ---------- Export ARMOR ----------
  if material == "leather" then
    exportRegionPng(spr, slArmor.bounds, { "Base" }, armorPng)
    exportRegionPng(spr, slArmor.bounds, { "Override" }, armorOverlayPng)
  else
    exportRegionPng(spr, slArmor.bounds, { "Base", "Override" }, armorPng)
    -- No overlay for non-leather
  end

  -- ---------- Properties ----------
  -- Item icon (type=item) - references <title>_icon
  do
    local lines = {
      "type=item",
      "items=" .. itemsList,
    }
    local itemNameMatch = trim(data.item_name)
    if material == "leather" then
      table.insert(lines, ("texture.leather_%s=%s"):format(part, title .. "_icon"))
      table.insert(lines, ("texture.leather_%s_overlay=%s"):format(part, title .. "_icon_overlay"))
    else
      table.insert(lines, "texture=" .. (title .. "_icon"))
    end
    if itemNameMatch ~= "" then
      table.insert(lines, "nbt.plain.display.Name=" .. itemNameMatch)
    end
    writeFile(itemPropsPath, table.concat(lines, "\n") .. "\n")
  end

-- Armor (type=armor) - references texture.<vanilla_key>=<title>_armor
  do
    local lines = {
      "type=armor",
      "items=" .. itemsList,
    }
    local keys = matInfo.keys
    if layerSel == "layer_1" then
      table.insert(lines, ("texture.%s=%s"):format(keys.layer_1, title .. "_armor"))
      if matInfo.hasOverlay then
        table.insert(lines, ("texture.%s=%s"):format(keys.ov1,     title .. "_armor_overlay"))
      end
    else -- layer_2
      table.insert(lines, ("texture.%s=%s"):format(keys.layer_2, title .. "_armor"))
      if matInfo.hasOverlay then
        table.insert(lines, ("texture.%s=%s"):format(keys.ov2,     title .. "_armor_overlay"))
      end
    end
    local itemNameMatch = trim(data.item_name)
    if itemNameMatch ~= "" then
      table.insert(lines, "nbt.plain.display.Name=" .. itemNameMatch)
    end
    writeFile(armorPropsPath, table.concat(lines, "\n") .. "\n")
  end

  -- ---------- Done (newline-safe alert) ----------
  local outLines = {
    "Export complete:",
    "* Icon base: " .. iconPng
  }
  if material == "leather" then
    outLines[#outLines+1] = "* Icon overlay: " .. iconOverlayPng
  end
  outLines[#outLines+1] = "* Armor base: " .. armorPng
  if material == "leather" then
    outLines[#outLines+1] = "* Armor overlay: " .. armorOverlayPng
  end
  outLines[#outLines+1] = "* Item .properties: " .. itemPropsPath
  outLines[#outLines+1] = "* Armor .properties: " .. armorPropsPath

  app.alert{ title="CIT Armor Export", text=outLines }
end

