eagleRemapper
=============

Converts GTA: San Andreas map data (gta.dat -> IDE / IPL / IMG / COL) into MTA
map files (.map placements + .definition model definitions) that the companion
"eagleLoader" resource can stream in. Designed to take maps exported from
Blender and get them running in MTA with minimal manual work.


1. INPUT FILES
--------------
Put your source data inside this resource's "in" folder:

    in/data/gta.dat              <- the data list (IDE / IPL / IMG / COLFILE ...)
    in/data/water.dat            <- optional, copied to the output if present
    in/<paths referenced by gta.dat>   e.g. in/data/maps/LA/lae2.IDE
    in/resources/                <- all .dff, .col and .txd files go here

Paths inside gta.dat may use Windows-style backslashes; they are handled
automatically. NOTE: on a Linux server the "in" folder name is case-sensitive.


2. CONFIGURATION
----------------
All configuration now lives in the <settings> block of meta.xml. Edit it there
(or live from the server admin panel under Resources > Settings):

    mapName     name of the generated output map/resource   (default: Output)
    author      author written into the generated meta.xml   (default: Blue Eagle)
    IMGSupport  "true" to pack assets into .img containers    (default: false)
    offsetX/Y/Z world offset added to every placement         (default: 0)


3. RUNNING
----------
Start the eagleRemapper resource:

    start eagleRemapper

It reads the "in" folder and writes the finished map into the resource's "out"
folder (named after mapName). Copy that output into your server's resources,
then:

    start eagleLoader
    start <your map>

The map should now load.


4. TROUBLESHOOTING
------------------
Processing writes a log to debug.txt in this resource folder. It lists any
issues, such as:

    Invalid ID: <name>          a placement references a model with no definition
    skipping IDE object ...     a definition's .dff/.col/.txd was not found in
                                in/resources

Use it to find missing assets or unreferenced models.
