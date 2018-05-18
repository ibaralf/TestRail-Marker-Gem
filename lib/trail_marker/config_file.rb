require 'yaml'

# History:
#   2/19/2018 Created ibarra.alfonso@gmail.com
#
#
class ConfigFile

  attr_accessor :username, :token, :testrail_url, :filename, :default_comment

  def initialize(cfile)
    @filename = cfile
    read_config_file
  end

  def prompt_user(user_msg, default_val)
    retval = default_val
    newval = ''
    atmps = 0
    while newval.strip == '' && atmps < 3
      atmps += 1
      print "#{user_msg}"
      newval = STDIN.gets
      retval = newval.strip == '' ? default_val : newval.strip
      newval = retval
    end
    if atmps >= 3
      puts "\nERROR: Value cannot be empty... exiting."
      exit(0)
    end
    return retval
  end

  def user_continue?(user_msg, default_val=false)
    retval = default_val
    reply = prompt_user(user_msg, 'N')
    if reply.upcase == "Y"
      retval = true
    end
    return retval
  end

  def read_config_file
    if File.exist?(@filename)
      @trail_info = YAML.load_file(@filename)
      @username = @trail_info["username"]
      @token = @trail_info["token"]
      @testrail_url = @trail_info["testrail_url"]
      @default_comment = @trail_info['default_comment']
    else
      @trail_info = Hash.new
      @username = ''
      @token = ''
      @testrail_url = ''
      @default_comment = 'Marked by Automation'
    end
  end

  def check_create_configfile
    if ! File.exist?(@filename)
      puts "\nWARNING: Configuration File does not exist."
      if user_continue?("Create a new config file (Y/N)? : ", 'N')
        create_configfile
      end
    end
  end

  def create_configfile
    @username = prompt_user("Enter testrail email (#{@username}): ", @username)
    @token = prompt_user("Enter testrail token (#{@token}): ", @token)
    @testrail_url = prompt_user("TestRail URL (#{@testrail_url}): ", @testrail_url)
    @default_comment = prompt_user("Test comment (Default - Marked by Automation): ", "Marked by Automation")
    @trail_info = Hash.new
    @trail_info["username"] = @username
    @trail_info["token"] = @token
    @trail_info["testrail_url"] = @testrail_url
    @trail_info["default_comment"] = @default_comment
    save
    # Comment out until overwrite is finished.
    #if user_continue?("Do you want to save the testrail project info (Y/N)?")
    #  config_project
    #  thash["project_name"] = @project_name
    #  thash["testrun"] = @testrun
    #  thash["testplan"] = @testplan
    #end
  end

  def config_project
    @project_name = prompt_user("Enter testrail project name: ")
    @testrun = prompt_user("Enter name of test run: ", "NA")
    @testplan = prompt_user("Enter name of test plan: ", "NA")
  end

  def update(varname, varvalue)
    if defined? @trail_info
      @trail_info[varname] = varvalue
    end
  end

  def save
    File.open(@filename, 'w') { |f|
      f.write @trail_info.to_yaml
      puts "Successfully saved config file: #{@filename}"
    }
  end
  
end