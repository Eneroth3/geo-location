# frozen_string_literal: true

module Eneroth
  module GeoLocation
    Sketchup.require "#{PLUGIN_ROOT}/terrain.rb"
    Sketchup.require "#{PLUGIN_ROOT}/inspect_tool.rb"

    # Reload extension.
    #
    # @param clear_console [Boolean] Whether console should be cleared.
    # @param undo [Boolean] Whether last oration should be undone.
    #
    # @return [void]
    def self.reload(clear_console = true, undo = false)
      # Hide warnings for already defined constants.
      verbose = $VERBOSE
      $VERBOSE = nil
      Dir.glob(File.join(PLUGIN_ROOT, "**/*.rb")).each { |f| load(f) }
      $VERBOSE = verbose

      # Use a timer to make call to method itself register to console.
      # Otherwise the user cannot use up arrow to repeat command.
      UI.start_timer(0) { SKETCHUP_CONSOLE.clear } if clear_console

      Sketchup.undo if undo

      nil
    end

    unless @loaded
      @loaded = true

      menu = UI.menu("Plugins").add_submenu(EXTENSION.name)
      menu.add_item(InspectTool.command)
    end
  end
end
