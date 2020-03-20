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
        model = Sketchup.active_model
        model.shadow_info["NorthAngle"] = north_angle.radians
        # HACK: Internal dictionary.
        # Seems not to be used when adding more imagery :( .
        model.set_attribute("GeoReference", "GeoReferenceNorthAngle",
                            north_angle.radians)
      end

      # Get model origin height.
      #
      # @return [Length]
      def self.height
        # REVIEW: Document height over what? Height over Earth ellipsoid?
        # HACK: Internal dictionary. Ideally SketchUp should have public API.
        model = Sketchup.active_model

        (-model.get_attribute("GeoReference", "ModelTranslationZ", 0)).to_l
      end

      # Set model origin height.
      #
      # @param height [Length]
      def self.height=(height)
        # REVIEW: Document height over what? Height over Earth ellipsoid?
        # HACK: Internal dictionary.
        model = Sketchup.active_model
        model.set_attribute("GeoReference", "ModelTranslationZ", -height.to_f)
        model.set_attribute("GeoReference", "ZValueCentered", -height.to_f)
      end

      # Get model origin LatLong.
      #
      # @return [Geom::LatLong]
      def self.latlong
        point_to_latlong(ORIGIN)
      end

      # Get model origin LatLong.
      #
      # @return [Geom::LatLong]
      def self.latlong=(latlong)
        model = Sketchup.active_model
        model.shadow_info["Latitude"] = latlong.latitude
        model.shadow_info["Longitude"] = latlong.longitude
        # HACK: Internal dictionary.
        model.set_attribute("GeoReference", "Latitude", latlong.latitude)
        model.set_attribute("GeoReference", "Longitude", latlong.longitude)
      end

      # Move earth relative to model.
      #
      # @param movement [Geom::Transformation]
      def self.move_earth(movement)
        self.latlong = point_to_latlong(movement.inverse.origin)
        self.height += movement.inverse.origin.z
        self.north_angle += MathHelper.planar_angle(movement.yaxis, Y_AXIS)

        # Seems to correctly update what SketchUp's model#point_to_utm reports
        # but not what Model#point_to_latlong reports.
      end

      # Get the height of a point.
      #
      # @return [Length]
      def self.point_to_height(point)
        # REVIEW: Document height over what? Height over Earth ellipsoid?
        (point.z + height).to_l
      end

      # Convert point to LatLong.
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

      # Get model origin UTM.
      #
      # @return [Geom::UTM]
      def self.utm
        point_to_utm(ORIGIN)
      end
    end
  end
end
