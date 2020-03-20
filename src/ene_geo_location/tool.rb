# frozen_string_literal: true

module Eneroth
  module GeoLocation
    # Generic tool functionality, like activation and menu command state.
    #
    # Designed to be reusable between tools and extensions.
    #
    # When inhering from this, call `super` in `activate` and `deactivate`.
    class Tool
      # Whether this is the active tool in SketchUp.
      @active = false

      # Activate a tool of this class.
      # Intended to be called on subclasses.
      #
      # @return [Object] The Ruby tool object.
      def self.activate(*args, &block)
        tool = block ? new(*args, &block) : new(*args)
        Sketchup.active_model.select_tool(tool)

        tool
      end

      # Check if a tool of this class is active.
      # Intended to be called on subclasses.
      def self.active?
        @active
      end

      # Get command for activating tool.
      #
      # Implement a custom `tool_description` method returning a string to set
      # a custom tool description for the command.
      #
      # @return [UI::Command]
      def self.command
        raise "tool_name class method required" unless respond_to?(:tool_name)

        command = UI::Command.new(tool_name) { activate }
        command.tooltip = tool_name
        if respond_to?(:tool_description)
          command.status_bar_text = tool_description
        end
        if respond_to?(:tool_icon_path)
          command.small_icon = command.large_icon = tool_icon_path
        end
        command.set_validation_proc { command_state }

        command
      end

      # Get command state to use in toggle tool activation command.
      # Intended to be called on subclasses.
      #
      # @return [MF_CHECKED, MF_UNCHECKED]
      def self.command_state
        active? ? MF_CHECKED : MF_UNCHECKED
      end

      # Guess tool name based on class name.
      #
      # Override for custom name.
      #
      # @return [String]
      def self.tool_name
        # Exclude trailing "Tool" from name.
        name.split("::").last.gsub(/([A-Z]+)([A-Z][a-z])/, '\1 \2')
            .gsub(/([a-z\d])([A-Z])/, '\1 \2').gsub(/ Tool$/, "")
      end

      # @api
      # @see https://ruby.sketchup.com/Sketchup/Tool.html
      def activate
        self.class.instance_variable_set(:@active, true)
      end

      # @api
      # @see https://ruby.sketchup.com/Sketchup/Tool.html
      def deactivate(*_args)
        self.class.instance_variable_set(:@active, false)
      end
    end
  end
end
