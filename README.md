# Eneroth Geo Location Mockup

Mockup for feature request for improved SketchUp Geo Location UX.

Shows how the terrain could be interactive and respond to Scale, Move and Rotate
rather than being a dumb locked component.

To run the mockup, open one of the attached example models.

## Creating your own example model.

As of now no external service for geographic data is plugged in. Instead a model
must be prepared to contain the terrain data.

Start by adding enough terrain to your model to cover the area you want to use,
e.g. by using SKetchUp's native Geo Location and Add More Imagery functionality.
Stich together all this terrain to one large mesh and place it in a group named
"Terrain Data". This group must contain only the geometry, not nested groups or
components. Hide this group.

Create a smaller group to represent the currently visible terrain patch, e.g.
based on a rectangle. This group should be named "Terrain" and be within the
bounding box of the "Terrain Data" group, but not inside of the group.

Save and reload the model, and start moving or scaling the "Terrain" group to
populate it with terrain.
