require_relative 'testrail'

# Calls testrail 
class Request
  
  
  def initialize(client, debug_mode = false)
    @client = client
    @debug_mode = get_debug_value(debug_mode)
    @debug_mode = true
  end
  
  # TODO: DRY with exec_get
  def exec_post(req, data, exit_on_fail = false)
    maxs = 2
    get_hash = nil
    attempts = 0
    is_good = false
    while ! is_good && attempts < maxs
      attempts += 1
      get_hash = call_api(req, "POST", data)
      is_good = get_hash[:status]
      if ! is_good
        if exit_on_fail
          exit_script()
        end
        puts "Got Error making API call - #{req} "
        puts "Retrying #{attempts}"
        if attempts < maxs
          sleep(4 * attempts)
        end
      end
    end
    return get_hash[:response]
  end
  
  # Retries an API call max number of times if an
  # exception is raised. Sleeps 4, 8, 12 .... seconds 
  # for each retry.
  #
  def exec_get(req, exit_on_fail = false)
    maxs = 2
    get_hash = nil
    attempts = 0
    is_good = false
    while ! is_good && attempts < maxs
      attempts += 1
      get_hash = call_api(req, "GET")
      is_good = get_hash[:status]
      if ! is_good
        if exit_on_fail
          exit_script()
        end
        puts "Got Error making API call - #{req} "
        puts "Retrying #{attempts}"
        if attempts < maxs
          sleep(4 * attempts)
        end
      end
    end
    if ! is_good
      check_authentication_fail(get_hash)
    end
    return get_hash[:response]
  end
 
  # Executes a TestRail API call but catches any
  # exception raised to prevent script from crashing.
  # Used by exec_get to do retries.
  #
  def call_api(req, rtype, data=nil)
    msg("#{rtype} REQ: #{req}")
    res_hash = {:status => true, :response => ""}
    begin
      if rtype == "POST"
        get_response = @client.send_post(req, data)
      else
        get_response = @client.send_get(req)
      end
    rescue Exception => e
      puts "Raised Exception: #{e.message}."
      res_hash[:status] = false
      res_hash[:response] = e.message
    else
      res_hash[:status] = true
      res_hash[:response] = get_response
    end
    msg("RESPONSE: #{res_hash}")
    return res_hash
  end
  
  private
   
  def exit_script()
    msg("Exiting script.")
    exit(1)
  end
  
  def msg(msg_txt)
    if @debug_mode
      puts msg_txt
    end
  end
  
  class APIError < StandardError
  end
  
  def get_debug_value(debug_val)
    boolval = false
    if !! debug_val == debug_val
      boolval = debug_val
    else
      boolval = string_to_boolean(debug_val)
    end
    return boolval
  end
  
  def string_to_boolean(strval)
    retval = false
    if strval.downcase == "true"
      retval = true
    end
    return retval
  end
  
  def check_authentication_fail(response_hash)
    failed_str = "Authentication failed"
    max_attempts_str = "maximum number of failed"
    if response_hash[:response].include?(failed_str) || response_hash[:response].include?(max_attempts_str)
      puts "Cannot authenticate User or password.\n"
      exit(1)
    end
  end
  
end