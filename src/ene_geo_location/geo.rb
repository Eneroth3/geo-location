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
    end
  end
end
