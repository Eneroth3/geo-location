# Copyright Julia Christina Eneroth (Eneroth3) 2016.

# This script is created as a  mock up for a feature request about an improved
# geo-location UI that better fits into SketchUp's intuitive design.
# The mock up shows how modifying a terrain already present in the model could
# work, instead of simply having a locked component.

# The mock up can't load any terrain data from external sources but relies on
# a group in model, meaning it can only be used with the attached SketchUp
# model.

module EneGeoLocation

  # Project vector to plane.
  #
  # vector - Vector3d to project.
  # normal - Normal of plane to project vector to (default: Z_AXIS).
  #
  # Returns vector.
  def self.project_vector(vector, normal = Z_AXIS)

    normal * vector * normal

  end

  # Find counter clockwise angles in plane between vector.
  #
  # vector0 - First Vector3d to test.
  # vector1 - Second Vector3d to test.
  # normal  - Normal of the plane to find angle in (default: Z_AXIS).
  #
  # Returns angle in radians as Float.
  def self.angle_in_plane(vector0, vector1, normal = Z_AXIS)

    vector0 = project_vector(vector0, normal)
    vector1 = project_vector(vector1, normal)

    a = vector0.angle_between(vector1)
    return 0 if a == 0
    a *= -1 if (vector1 * vector0).samedirection? normal

    a

  end

  # Check if a transformation involves scaling in any axis.
  #
  # transformation - A Transformation object to test.
  #
  # Returns true or false.
  def self.scaled?(transformation)

    coords = [
      Geom::Vector3d.new(1, 0, 0),
      Geom::Vector3d.new(0, 1, 0),
      Geom::Vector3d.new(0, 0, 1)
    ]

    !coords.all? { |c| c.transform(transformation).length == 1.to_l }

  end

  # Check if a transformation is the identity matrix (within some tolerance).
  # The native Transformation#identity? is broken and returns false for all
  # transformations that has been modified since created from Transformation#new.
  #
  # transformation - A Transformation object.
  #
  # Returns true or false.
  def self.identity_transformation?(transformation)

    ary0 = transformation.to_a
    ary1 = Geom::Transformation.new.to_a

    ary0.each_with_index { |v, i| return(false) if v != ary1[i].to_l }

    true

  end

  # Get the transformation that has been applied to instance since this method
  # was last called. The first time times method runs for an instance it's
  # initializing and don't return a transformation.
  #
  # instance - A ComponentInstance or Group object.
  #
  # Returns Transformation object or nil.
  def self.last_transformation(instance)

    old_tr_ary = instance.get_attribute("ene_geo_location_mockup", "tr_ary")
    new_tr_ary = instance.transformation.to_a
    instance.set_attribute("ene_geo_location_mockup", "tr_ary", new_tr_ary)

    return unless old_tr_ary

    old_tr = Geom::Transformation.new(old_tr_ary)

    instance.transformation * old_tr.inverse

  end

  # Updates the group terrain is drawn to to. Called from observer when the group
  # containing the terrain is modified (e.g. moved, rotated or scaled by the
  # user).
  #
  # Returns nothin.
  def self.update_terrain

    model      = Sketchup.active_model
    entities   = model.entities
    shadowinfo = model.shadow_info

    model.start_operation("TRANSPARENT", true, false, true)

    terrain_group = entities.find { |e| e.is_a?(Sketchup::Group) && e.name == "Terrain" }

    # For the mock up terrain data is simply defined in a hidden group in the
    # model. To "draw" to the visible terrain group the content of this hidden
    # group is copied into it and cropped to the visible group's horizontal
    # bounds.
    terrain_data_group = entities.find { |e| e.is_a?(Sketchup::Group) && e.name == "Terrain Data" }

    tr_change = last_transformation(terrain_group)
    if identity_transformation?(tr_change)
      model.commit_operation
      return
    end

    if scaled?(tr_change)
      # Scaling the terrain group is used for extending and cropping the terrain.

      # get horizontal bounds...
      bb = terrain_group.bounds
      p bb.width  # x
      p bb.height # y
      p bb.depth  # x
      # copy from terrain_data_group...
      # crop...

    else
      # Moving or rotating the terrain group is used to change the model
      # geo-location information.

      a = angle_in_plane(terrain_group.transformation.yaxis, Y_AXIS)
      shadowinfo["NorthAngle"] = a.radians

      # TODO: setting NorthAngle is not a transaction (not included in the
      # operator) and therefore isn't reset when user undo. Use a ModelObserver
      # to fetch north angle from terrain group on undo and redo.

      # TODO: update lat and long based on the origin point of tr_change.

      # The hidden terrain group is moved to match the new geo location.
      terrain_data_group.transform!(tr_change)

    end

    model.commit_operation

  end

  class MyEntityObserver < Sketchup::EntityObserver

    @@disabled = false

    def onChangeEntity(_)
      return if @@disabled
      @@disabled = true
      EneGeoLocation.update_terrain
      @@disabled = false
    end

  end

  unless defined?(INITALIZED)
    INITALIZED = true

    model         = Sketchup.active_model
    entities      = model.entities
    terrain_group = entities.find { |e| e.is_a?(Sketchup::Group) && e.name = "Terrain" }

    if terrain_group
      terrain_group.add_observer(MyEntityObserver.new)
    else
      raise "This script  must run in the attached model."
    end

  end

end
