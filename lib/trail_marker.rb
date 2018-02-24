#Dir[File.dirname(__FILE__) + '/trail_marker/*.rb'].each {|file| require file }
require_relative 'trail_marker/api_testrail'
require_relative 'trail_marker/argument'
require_relative 'trail_marker/config_file'
require_relative 'trail_marker/mark_tests'
require_relative 'trail_marker/request'
require_relative 'trail_marker/response'
require_relative 'trail_marker/results_parser'
require_relative 'trail_marker/testrail'

# Can be used as a mixin.
#
module TrailMarker
  class ConfigFile < ConfigFile

  end
end
