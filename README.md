# Monutilities
A bundle of helper scripts for Aseprite that streamline creating Custom Item Textures (CIT) assets for Minecraft, with a focus on the CIT Resewn pipeline. Each script automates small but repetitive steps so you can stay inside Aseprite while building packs.
Developed by OurStoRi.

## Features
- Setup sprite sheet environment for specific files like armor, bows, crossbows, for easier file management and experience.
- Export image files, properties and mcmeta automatically, easier implementation and testing.

## Installation
1. Locate your Aseprite scripts directory (`File` -> `Scripts` -> `Open Script Folder`).
2. Copy the `Monutilities` folder into that directory.
3. Rescan the folder with `File` -> `Scripts` -> `Rescan Script Folder` so the new entries appear under `Scripts -> Monutilities`.

## Usage Highlights
### General Item Export (`generic/export_item.lua`)
1. Open and save the `.aseprite` file you want to export. The script needs the path to determine the export folder.
2. Run `Scripts -> Monutilities -> generic -> export_item`.
3. Fill in the dialog:
   - `Base item` - for example `minecraft:stick`.
   - `Item name` - text shown in game; written to the `.properties` file.
   - `Model (optional)` - relative path under `optifine/cit/source_models/` if you use a custom model.
   - `Include animation` - when enabled, exports a vertical sprite sheet and generates a `.png.mcmeta` with tick timings derived from frame durations.
   - `Display export` - produces a 600% preview PNG (static) or GIF (animated) for showcasing.
   - `Output folder` - defaults to the sprite directory; pick another location if needed.
4. Confirm. The script creates:
   - `<sprite>.properties`
   - `<sprite>.png`
   - `<sprite>.png.mcmeta` (when animation is enabled)
   - `<sprite>_display.png` or `<sprite>_display.gif` when display export is toggled
   A summary dialog lists the written files.

### Workspace Setup
- `armor/setup.lua` - Generates a ready-to-paint armor file (80x32) with layer blend modes already set to Multiply where dyes belong. Includes `icon` and `armor` slices.

## Roadmap
- Flesh out the bow and crossbow setup and export workflows.
- Refine output directory option (there's 1 for folder and 1 for file which is weird)
- potentially More workspace setups.

## Contributing
Issues, ideas, and pull requests are welcome. If you add new scripts, keep them ASCII-only and prefer short inline comments when behaviour is not obvious, matching the existing style.

Enjoy faster CIT iteration!
