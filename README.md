# Eagle Map Processor

A workflow for exporting, processing, and loading custom maps using Blender and Lua scripts for MTA:SA. The `eagleRemapper` resource converts GTA:SA map data (`gta.dat` → IDE / IPL / IMG / COL) into MTA map files (`.map` placements + `.definition` model definitions) that the companion `eagleLoader` resource streams in.

---

## Quick Start

1. **Extract your mod into the `in` folder**  
   Place your entire map export or mod package into the `in` directory.
   - If you don't have IMG files, create a `resources` folder inside `in` and place your `.dff`, `.col`, and `.txd` files there.
   - Expected layout:
     ```
     in/data/gta.dat            the data list (IDE / IPL / IMG / COLFILE ...)
     in/data/water.dat          optional, copied to the output if present
     in/resources/              your .dff, .col and .txd files
     ```
   - **Note:** on a Linux server the `in` folder name is case-sensitive.

2. **Configure the Map**

   All configuration now lives in the `<settings>` block of `meta.xml`. Edit it there, or change it live from the server admin panel under **Resources → Settings**:

   ```xml
   <settings>
       <setting name="*mapName"    value="Output" />
       <setting name="*author"     value="Blue Eagle" />
       <setting name="*IMGSupport" value="false" />
       <setting name="*offsetX"    value="0" />
       <setting name="*offsetY"    value="0" />
       <setting name="*offsetZ"    value="0" />
   </settings>
   ```

   **Config Options Explained:**

   - **mapName** — name of the generated output map/resource. Example: `Output`
   - **author** — author written into the generated `meta.xml`. Example: `Blue Eagle`
   - **IMGSupport** — set to `true` to pack assets into `.img` containers, or `false` to place models directly in the `resources` folder.
   - **offsetX / offsetY / offsetZ** — world offset added to every placement (useful for moving the entire map or correcting coordinates). Example: `0` / `0` / `0`, or `-8268.021` / `-9166.558` / `0`.

3. **Run the Resource**

   ```
   start eagleRemapper
   ```
   The processor reads the `in` folder and writes your map into the `out` folder, named by `mapName` (default: `Output`).

4. **Load the Map**

   - Copy the exported map folder into your server's `resources` directory.
   - Start the `eagleLoader` resource.
   - Then start your map resource.
     ```
     start eagleLoader
     start <your map>
     ```

---

## Troubleshooting

Processing writes a log to `debug.txt` in the resource folder. It lists any issues, such as:

- `Invalid ID: <name>` — a placement references a model with no definition.
- `skipping IDE object ...` — a definition's `.dff`/`.col`/`.txd` was not found in `in/resources`.

Use it to find missing assets or unreferenced models.

---

## Notes

- If you do **not** have IMG files, make sure you create a `resources` folder inside your `in` directory and place your `.dff`, `.col`, and `.txd` files there.
- All files must follow the folder structure above.
- For custom workflows or scripts, ensure they output the correct file formats and structure.
