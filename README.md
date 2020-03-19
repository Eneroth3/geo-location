# Eneroth Geo Location Mockup

This script is created as a  mock up for a feature request about an improved
Geo Location UX that better fits into SketchUp's intuitive design.
The mock up shows how modifying a terrain already present in the model could
be used to update the Geo Location and extend the visible terrain, instead of
simply having a locked dumb component.

The mock up can't load any terrain data from external sources but relies on
a group in model, meaning it can only be used with specifically prepared
models.

To create a custom example model, create a group named "Terrain".
This group representants the terrain visible to the user.
To start with this group can contain just a rectangle.
Create another group named "Terrain Data".
Add a large terrain (as large as you want the example to have) into this
group.
The terrain must consist of loose edges and faces and must not contain any
groups or components.
Make sure the groups overlap horizontally; typically the Terrain group
covers a small part somewhere in the center of the Terrain Data group.
Hide the Terrain Data group.
Load this script (if it has been loaded before the previous steps SU needs to
be restarted).
Scale the Terrain group at least once to populate it with terrain.