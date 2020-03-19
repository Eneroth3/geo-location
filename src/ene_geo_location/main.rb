module Eneroth
  module GeoLocation
    Sketchup.require "#{PLUGIN_ROOT}/math_helper.rb"

    # Get terrain group.
    #
    # @return [Sketchup::Group]
    def self.group
      @group ||= Sketchup.active_model.entities.find do |entity|
        entity.is_a?(Sketchup::Group) && entity.name == "Terrain"
      end
    end

    # Get group holding terrain data.
    #
    # For now there is no mapping service, but the terrain gets cropped from a
    # larger, hidden group.
    #
    # @return [Sketchup::Group]
    def self.data_group
      @data_group ||= Sketchup.active_model.entities.find do |entity|
        entity.is_a?(Sketchup::Group) && entity.name == "Terrain Data"
      end
    end

    # Get the change in transformation of an instance since last call.
    #
    # Should be called within an operation.
    # Requires 'init_transform_tracking' to have been called first.
    #
    # @param instance [Sketchup::Group, Sketchup::ComponentInstance]
    #
    # @return [Transformation]
    def self.transformation_change(instance)
      old_array = instance.get_attribute(self.to_s, "tr_ary")
      new_array = instance.transformation.to_a
      instance.set_attribute(self.to_s, "tr_ary", new_array)

      instance.transformation * Geom::Transformation.new(old_array).inverse
    end

    # Prepare instance for having changes in it transformation tracked.
    #
    # Should be called within an operation.
    #
    # @param instance [Sketchup::Group, Sketchup::ComponentInstance]
    def self.init_transform_tracking(instance)
      instance.set_attribute(self.to_s, "tr_ary", instance.transformation.to_a)
    end

    # Called when the terrain entity is changed.
    def self.on_change
      model = Sketchup.active_model
      model.start_operation("_Update Terrain", true, false, true)
      change = transformation_change(group)
      unless MathHelper.identity_transformation?(change)
        MathHelper.scaled?(change) ? on_scale(change) : on_move(change)
      end
      model.commit_operation
    end

    # Called when the terrain is scaled.
    # Redraws terrain to fill up its new horizontal bounds.
    #
    # @param scaling [Geom::Transformation]
    def self.on_scale(scaling)
      # Remember current bounds.
      bounds = group.definition.bounds

      group.entities.clear!
      copy_into(data_group, group)

      # Extend bounds vertically to fit terrain. Terrain should only be
      # cropped horizontally.
      reference_bounds = data_group.definition.bounds
      bounds.add(bounds.min.tap { |pt| pt.z = reference_bounds.min.z })
      bounds.add(bounds.max.tap { |pt| pt.z = reference_bounds.max.z })

      crop(group.entities, bounds)
    end

    # Called when the terrain is moved (rotated or translated).
    # Updates model geo location to match terrain.
    #
    # @param movement [Geom::Transformation]
    def self.on_move(movement)
      self.north_angle =
        MathHelper.angle_in_plane(group.transformation.yaxis, Y_AXIS)

      # TODO: setting NorthAngle is not a transaction (not included in the
      # operator) and therefore isn't reset when user undo. Use a ModelObserver
      # to fetch north angle from terrain group on undo and redo.

      # TODO: update lat and long based on the origin point of movement.

      # The hidden terrain group is moved to match the new geo location.
      data_group.transform!(movement)
    end

    # Get the model north angle.
    #
    # @return [Numeric] Radians cc from model Y axis.
    def self.north_angle
      Sketchup.active_model.shadow_info["NorthAngle"].degrees
    end

    # Set the model north angle.
    #
    # @param north_angle [Numeric] Radians cc from model Y axis.
    def self.north_angle=(north_angle)
      Sketchup.active_model.shadow_info["NorthAngle"] = north_angle.radians
    end

    # Move entities from one container to another.
    def self.copy_into(source, target)
      transformation = target.transformation.inverse * source.transformation
      copy = target.entities.add_instance(source.definition, transformation)
      copy.explode
    end

    # Crop entities to a new bounding box.
    #
    # @param entities [Sketchup::Entities]
    # @param bounds [Geom::BoundingBox]
    def self.crop(entities, bounds)
      box = entities.add_group
      pts = [
        bounds.min,
        [bounds.max.x, bounds.min.y, bounds.min.z],
        [bounds.max.x, bounds.max.y, bounds.min.z],
        [bounds.min.x, bounds.max.y, bounds.min.z]
      ]
      face = box.entities.add_face(pts)
      face.reverse! unless face.normal.samedirection?(Z_AXIS)
      face.pushpull(bounds.max.z)

      entities.intersect_with(false, IDENTITY, entities, IDENTITY, true, box)

      outside = entities.select do |edge|
        next unless edge.is_a?(Sketchup::Edge)
        midpoint = Geom.linear_combination(0.5, edge.start.position, 0.5,
                                           edge.end.position)
        !box.bounds.contains?(midpoint)
      end
      entities.erase_entities(outside)

      box.erase!
    end

    # Attach the required observer.
    def self.attach_observer
      if group
        # REVIEW: Should be called when first inserting the terrain.
        # Now adds to the undo stack simply from loading this script.
        init_transform_tracking(group)
        group.add_observer(TerrainObserver.new)
      else
        raise "This script  must run in the attached model."
      end
    end

    # @private
    class TerrainObserver < Sketchup::EntityObserver
      @@disabled = false

      def onChangeEntity(*_args)
        return if @@disabled
        UI.start_timer(0) do
          @@disabled = true
          GeoLocation.on_change
          @@disabled = false
        end
      end
    end

    unless @loaded
      @loaded = true

      attach_observer
    end
  end
end
