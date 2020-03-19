# frozen_string_literal: true

module Eneroth
  module GeoLocation
    # Functionality related to model Geo Location.
    module Geo
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

      # Get model origin height.
      #
      # @return [Length]
      def self.height
        # REVIEW: Document height over what? Height over Earth ellipsoid?
        # HACK: Internal dictionary. Ideally SketchUp should have public API.
        model = Sketchup.active_model
        model.get_attribute("GeoReference", "ModelTranslationZ", 0).to_l
      end

      # Set model origin height.
      #
      # @param height [Length]
      def self.height=(height)
        # REVIEW: Document height over what? Height over Earth ellipsoid?
        # HACK: Internal dictionary. Ideally SketchUp should have public API.
        model = Sketchup.active_model
        model.set_attribute("GeoReference", "ModelTranslationZ", height.to_f)
      end

      # Get the height of a point.
      #
      # @return [Length]
      def self.point_to_height(point)
        # REVIEW: Document height over what? Height over Earth ellipsoid?
        (point.z + height).to_l
      end

      # Convert point to latLong.
      # Takes north direction into account, unlike the native API as of now.
      #
      # @param point [Geom::Point3d]
      #
      # @return [Geom::latLong]
      def self.point_to_latlong(point)
        # Don't use native point_to_latlong as it is stupid.
        # https://github.com/SketchUp/api-issue-tracker/issues/448
        point_to_utm(point).to_latlong
      end

      # Convert point to UTM.
      # Takes north direction correctly into account, unlike the native API as
      # of now.
      #
      # @param point [Geom::Point3d]
      #
      # @return [Geom::UTM]
      def self.point_to_utm(point)
        model = Sketchup.active_model

        ### return model.point_to_utm(point) if Sketchup.version.to_i >= 2020

        # Counter for https://github.com/SketchUp/api-issue-tracker/issues/447.
        angle = 2 * model.shadow_info["NorthAngle"].degrees
        point = point.transform(Geom::Transformation.new(ORIGIN, Z_AXIS, angle))

        model.point_to_utm(point)
      end
    end
  end
end
