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
      bb  = group.definition.bounds
      min = bb.min
      max = bb.max

      group.entities.clear!

      # Copy terrain from data_group into the same location in the
      # group.
      d  = data_group.definition
      tr = group.transformation.inverse * data_group.transformation
      terrain_copy = group.entities.add_instance(d, tr)
      terrain_copy.explode

      # Extend saved bounds vertically to fit terrain. Terrain should only be
      # cropped horizontally.
      bb    = group.definition.bounds
      min.z = bb.min.z
      max.z = bb.max.z

      # Draw box according to the desired bounds and crop terrain to it.

      cut_box = group.entities.add_group
      pts = [
        min,
        [max.x, min.y, min.z],
        [max.x, max.y, min.z],
        [min.x, max.y, min.z]
      ]
      face = cut_box.entities.add_face(pts)
      face.reverse! unless face.normal.samedirection?(Z_AXIS)
      face.pushpull(max.z)

      group.entities.intersect_with(false, IDENTITY, group.entities, IDENTITY, true, cut_box)

      group.entities.erase_entities(
        group.entities.select { |e|
          next unless e.is_a?(Sketchup::Edge)
          midpoint = Geom.linear_combination(0.5, e.start.position, 0.5, e.end.position)
          !cut_box.bounds.contains?(midpoint)
        }
      )

      cut_box.erase!
    end

    # Called when the terrain is moved (rotated or translated).
    # Updates model geo location to match terrain.
    #
    # @param movement [Geom::Transformation]
    def self.on_move(movement)
      Sketchup.active_model.shadow_info["NorthAngle"] = MathHelper.angle_in_plane(group.transformation.yaxis, Y_AXIS).radians

      # TODO: setting NorthAngle is not a transaction (not included in the
      # operator) and therefore isn't reset when user undo. Use a ModelObserver
      # to fetch north angle from terrain group on undo and redo.

      # TODO: update lat and long based on the origin point of movement.

      # The hidden terrain group is moved to match the new geo location.
      data_group.transform!(movement)
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
