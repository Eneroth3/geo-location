module Eneroth
  module GeoLocation
    # Math related functionality.
    module MathHelper
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
        return a if a == 0 || a == Math::PI
        a *= -1 if (vector1 * vector0).samedirection? normal

        a
      end

      # Check if a transformation involves scaling in any axis.
      #
      # transformation - A Transformation object to test.
      #
      # Returns true or false.
      def self.scaled?(transformation)
        axes = [X_AXIS, Y_AXIS, Z_AXIS]

        !axes.all? { |a| a.transform(transformation).length == 1.to_l }
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
    end
  end
end
