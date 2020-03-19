# frozen_string_literal: true

module Eneroth
  module GeoLocation
    # Math related functionality.
    module MathHelper
      # Find counter clockwise angle in plane between vectors.
      #
      # @param minuend [Geom::Vector3d]
      # @param subtrahend [Geom::Vector3d]
      # @param normal [Geom::Vector3d]
      #
      # @return [Numeric] Angle in radians.
      def self.planar_angle(minuend, subtrahend, normal = Z_AXIS)
        Math.atan2((minuend * subtrahend) % normal, subtrahend % minuend)
      end

      # Check if a transformation involves scaling in any axis.
      #
      # @param transformation [Geom::Transformation]
      #
      # @return [Boolean]
      def self.scaled?(transformation)
        axes = [X_AXIS, Y_AXIS, Z_AXIS]

        !axes.all? { |a| a.transform(transformation).length == 1.to_l }
      end

      # Check if transformation is the identity matrix.
      # Up until SketchUp 2018 the native API method has been broken.
      #
      # @param transformation [Geom::Transformation]
      #
      # @return [Boolean]
      def self.identity_transformation?(transformation)
        ary0 = transformation.to_a
        ary1 = Geom::Transformation.new.to_a

        ary0.each_with_index { |v, i| return(false) if v != ary1[i].to_l }

        true
      end
    end
  end
end
