require 'json'

# Holds the TestRail response to easily access fields and
# give an easy user selector.
# TODO: Clean this UP!
class Response
  
  @response_type = nil
  
  def initialize(response)
    @response_type = response.class.name
    @json_data = ""
    @raw_data = response
  end
  
  def update(response)
    initialize(response)
  end
  
  def list_projects()
    
  end
  
  def get_value(key)
    retval = nil
    case @response_type
    when "Array"
      retval = parse_array(@raw_data, key)
    when "Hash"
      retval = parse_hash(@raw_data, key)
    end
    return retval
  end
  
  def get_id(key, value)
    retval = nil
    case @response_type
    when "Array"
      retval = parse_array_kv(@raw_data, key, value, 'id')
    when "Hash"
      retval = @raw_data['id']
    end
    return retval
  end
  
  # Returns ID of item selected via user key enter
  #
  def picker(key)
    min_val = 1
    max_val = 1
    valarr = get_value(key)
    puts "Options Available: "
    valarr.each_with_index do |one_select, index|
      dis_index = index + 1
      puts "#{dis_index}) #{one_select}"
      max_val = dis_index
    end
    
    puts "q) TO QUIT"
    print "Enter number of your selection: "
   
    user_choice = pick_filter(min_val, max_val, true)
    puts "You SELECTED #{valarr[user_choice - 1]}"
    puts ""
    return valarr[user_choice - 1]
  end
  
  private
  
  def parse_array_kv(rdata, k, v, key_return)
    fnd = rdata.detect {|unhash| unhash[k] == v}
    return fnd['id']
  end
  
  def parse_array(rdata, key)
    retarr = []
    rdata.map do |h|
      retarr.push(h[key])
    end
    return retarr
  end
  
  def parse_hash(rdata, key)
    retval = rdata[key]
  end
  
  # TODO: Add user keyboard input checks.
  #
  def pick_filter(min, max, add_quit = true)
    guide_msg = "Valid values are from #{min} to #{max}"
    if add_quit
      guide_msg += " or 'q' to quit"
    end
    retval = nil
    entered_valid = false
    atmps = 0
    integer_pattern = /[0-9]+/
    while ! entered_valid do
      user_input = $stdin.gets.chomp.downcase
      if (user_input == 'q' && add_quit) || (atmps > 7)
        puts "Exiting!"
        exit(0)
      end
      if user_input =~ integer_pattern
        entered_value = user_input.to_i
        if entered_value >= min && entered_value <= max
          retval = entered_value
          entered_valid = true
        end
      end
      if ! entered_valid
        puts guide_msg
      end
      atmps += 1
    end
    return retval
  end  
    
  
  
end