# frozen_string_literal: true

module Eneroth
  module GeoLocation
    Sketchup.require "#{PLUGIN_ROOT}/tool.rb"
    Sketchup.require "#{PLUGIN_ROOT}/geo.rb"

    # Tool for inspecting geo location of points.
    class InspectTool < Tool
      # Background color behind text.
      BACKGROUND = Sketchup::Color.new(255, 255, 255, 0.8)

      def initialize
        @ip = Sketchup::InputPoint.new
        update_status_text
      end

      def deactivate(view)
        view.invalidate
      end

      def draw(view)
        @ip.draw(view)

        corners = [[90, 90, 0], [600, 90, 0], [600, 250, 0], [90, 250, 0]]
        view.drawing_color = BACKGROUND
        view.draw2d(GL_POLYGON, corners)
        view.draw_text([100, 100], @text, size: 15)
      end

      def onMouseMove(_flags, x, y, view)
        @ip.pick(view, x, y)
        @text = text

        view.invalidate
      end

      def onLButtonDown(*_args)
        Sketchup.active_model.active_entities.add_text(
          @text,
          @ip.position,
          Geom::Vector3d.new(1.m, 1.m, 3.m)
        )
      end

      def suspend(view)
        view.invalidate
      end

      def resume(view)
        update_status_text
        view.invalidate
      end

      private

      def text
        "Position: #{@ip.position.to_a.map(&:to_l).join(', ')}\n"\
        "LatLong: #{Geo.point_to_latlong(@ip.position)}\n"\
        "UTM: #{Geo.point_to_utm(@ip.position)}\n"\
        "Height: #{Geo.point_to_height(@ip.position)}\n"\
      end

      def update_status_text
        Sketchup.status_text = "Click to add text note."
      end
    end
  end
end
