# Eagle Map Processor

A workflow for exporting, processing, and loading custom maps using Blender and Lua scripts for MTA:SA.

---

## Quick Start

1. **Extract your mod directly into the `In` folder**  
   Place your entire map export or mod package into the `In` directory.  
   - If you don't have the IMG files, simply create a `resources` folder inside `In` and place your `.dff`, `.col`, and `.txd` files there.

2. **Configure the Map**

   Open the `Config.lua` file in the root of your project and edit the following options as needed:

   ```lua
   mapName = 'Output'
   mAuthor = 'Blue Eagle'
   metaSpacing = 2
   IMGSupport = false

   mapOffset = {0,0,0} -- {-8268.021, -9166.558, 0}
   ```

   **Config Options Explained:**

   - **mapName**  
     The name of your output map folder.  
     Example: `'Output'`

   - **mAuthor**  
     Author name for metadata or tracking.  
     Example: `'Blue Eagle'`

   - **metaSpacing**  
     Controls how frequently metadata is inserted in the output files.  
     Example: `2` (higher = more spacing, lower = less)

   - **IMGSupport**  
     Set to `true` if you are using IMG archives, or `false` if you are placing your models directly in the `resources` folder.  
     Example: `false`

   - **mapOffset**  
     Offsets your map in 3D space (useful for moving the entire map or correcting coordinates).  
     Example: `{0,0,0}` or `{ -8268.021, -9166.558, 0 }`

3. **Run the Resource**

   - Start the `eagleMapProcessor` resource.
   - The processor will export your map into the folder named by `mapName` (default: `Output`).

4. **Load the Map**

   - Place the exported map folder in your server's `resources` directory.
   - Start the `eagleLoader` resource.
   - Then start your map resource.

---

## Troubleshooting

- If you encounter issues, read the output log `debug.txt`.  
  It will show any errors or issues that occurred during map processing.

---

## Notes

- If you do **not** have IMG files, make sure you create a `resources` folder inside your `In` directory and place your `.dff`, `.col`, and `.txd` files there.
- All files must follow the folder structure above.
- For custom workflows or scripts, ensure they output the correct file formats and structure.

---

