##################################################################################
#  TestRail is a test case/suite management tool. It has available API in order for 
#  automated tests to mark cases as passed or failed.
#  This tool can be used via command line or called inside your script.
#  
#  unix$ testrail_marker -h
#
#
# HISTORY: 4/11/2016 Created - ibarra.alfonso@gmail.com
#          2/19/2018 Packaged as executable ruby GEM
#
#
# TODO: Add option to overwrite config file
#
require 'testrail_marker'
#require_relative '../lib/trail_marker'

#require_relative 'argument'
#require_relative 'response'
#require_relative 'request'
#require_relative 'api_testrail'
#require_relative 'results_parser'

# Test Token = Epf.32h4wbdzBzZwoJZc-qOOoSfYHbWtVfaj2S5IN

############################  MAIN  ############################### 

full_config_path = File.expand_path(File.dirname(__FILE__)) + '/' + 'trail_config.yml'
argument = Argument.new(ARGV)

if argument.has_argument?('-cf')
  cf = ConfigFile.new(full_config_path)
  cf.create_configfile
  exit(0)
else
  mark_tests = MarkTests.new(argument, full_config_path)
  mark_tests.setup
  mark_tests.check_create
  mark_tests.markoff_all_results
  mark_tests.show_exit_msg
end



