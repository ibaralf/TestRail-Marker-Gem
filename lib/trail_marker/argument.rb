
# Parses command line argument.
# Avoids requiring a dependent gem, easy to add any parameters and tags
# To Add New Parameter:
#   => Add new tag in @valid_parameters
#   => Change HELP message to describe new parameter added
# 
class Argument
  
  USAGE = "Usage: \n  testrail_marker -r run_plan_name -p project_name -x /home/path_to/results_xml/dir \n"
  HELP = "    -h, Show HELP
    -p *, name of project (e.g. TestRail API Gem) (required parameter)
    -r or -t *, name of test run (-r) or test plan (-t) (required parameter) 
    -m, milestone name (can be used when creating a test run)
    -s, test suite name (* required when creating a test run)
    -u, user (e.g. ibarra@apitestrail.com)
    -pw, password or token (recommended)
    -url, URL of TestRail (e.g. https://yourcompany.testrail.io)
    -cf, create a configuration file
    -d, debug mode (set to false to suppresses most messages)
    -x or -f *, path (-x, Directory) or specific file (-f) for results to parse 
    -com, comment to put on each test
   
    
    NOTES: Results must have TestRail test case numbers to match. See README file for
           more details.
           Create options are available by adding \'c\' to some arguments, ex. -cr would create a new test run."
    
  REQUIRED = "\nMissing required parameter/s (until config file implemented):
    Ex: testrail_marker -p TestRail API Gem -r Regression Suite -x ./results/path
    -p, name of project (e.g. -p TestRail API Gem)
    -r or -t, name of test run or test plan (e.g. -r Regression Suite)
    -x or -f, path (Directory) or a specific file of results to parse (e.g. -f /home/path/results/rspec_results.xml)\n"
  
  # Constructor. Requires passing the parameters from the command line argument.
  #
  def initialize(passed_arguments)
    @arg_passed = passed_arguments
    @valid_parameters = ['-p', '-m', '-r', '-h', '-u', '-pw', '-url', '-d', '-x', '-t', '-s', '-com', '-f']
    @create_parameters = ['-cm', '-cr', '-ct']
    @delete_parameters = ['-dm', '-dr', '-dt']
    @runner_parameters = ['-cf']
    @valid_parameters += @create_parameters
    @valid_parameters += @delete_parameters
    @valid_parameters += @runner_parameters
    @required_parameters = ['-p']
    @requires_atleast_one = ['-r', '-t', '-cr', '-ct']
    @requires_only_one = ['-x', '-f']
    
    check_help(passed_arguments)
    initialize_holder()
    parse_args(passed_arguments)
    check_required_parameters(passed_arguments)
    print_arguments
  end
  
  def print_arguments()
    puts "\nPassed Arguments:"
    @holder.each do |hold|
      if hold[:value] != ""
        puts "  #{hold[:tag]} #{hold[:value]}"
      end
    end
  end
  
  def parse_args(arguments)
    par_index = []
    puts "ARG: #{arguments}"
    @valid_parameters.each do |tag|
      arg_index = arguments.index(tag).nil? ? -1 : arguments.index(tag)
      par_index.push(arg_index)
    end
    @valid_parameters.each_with_index do |tag, x|
      tag_index = par_index[x]
      end_index = get_next_highest(tag_index, par_index)
      save_arg_to_holder(arguments, tag_index, end_index)
    end
  end
  
  # Returns the argument parameter passed with the specified tag
  #
  def get_arg_value(tag)
    tag_value = nil
    if @valid_parameters.include?(tag)
      tag_hash = @holder.detect{|tag_data| tag_data[:tag] == tag}
      tag_value = tag_hash[:value]
    else
      puts "ERROR: Parameter #{tag} not recognized."
    end
    return tag_value
  end
  
  def get_optional_arg(tag_arr)
    tag_value = nil
    tag_arr.each do |tag|
      if @valid_parameters.include?(tag)
        tag_hash = @holder.detect{|tag_data| tag_data[:tag] == tag}
        tag_value = tag_hash[:value]
      else
        puts "ERROR: Parameter #{tag} not recognized."
      end
      if tag_value == ""
        tag_value = nil
      end
      if ! tag_value.nil?
        break
      end
    end
    return tag_value
  end
  
  def arg_exists?(tag)
    it_exists = false
    tagv = get_arg_value(tag)
    if ! tagv.nil? && tagv != ""
      it_exists = true
    end
    return it_exists
  end

  def has_argument?(tag)
    if @arg_passed.include?(tag)
      return true
    end
    return false
  end
  
  private
  
  # Creates an array to hold values of possible parameter tags.
  #
  def initialize_holder()
    @holder = []
    @valid_parameters.each do |tag|
      param_hash = {:tag => tag, :value => ""}
      @holder.push(param_hash)
    end
  end
  
  # Returns the next highest value in the array
  # If num is the highest, then returns 100
  def get_next_highest(num, array_num)
    retval = nil
    if ! num.nil? && num != -1
      arr_size = array_num.size
      sorted_nums = array_num.sort
      num_index = sorted_nums.index(num)
      if num_index == arr_size - 1
        retval = 100
      else
        retval = sorted_nums[num_index + 1]
      end
    end
    return retval
  end
  
  def save_arg_to_holder(arguments, startx, endx)
    if startx >= 0
      which_tag = arguments[startx]
      tag_hash = @holder.detect{|tag_data| tag_data[:tag] == which_tag}
      tag_hash[:value] = arguments[startx+1..endx-1].join(" ")
    end
  end
  
  def check_help(arguments)
    if arguments.include?('-h')
      puts "#{USAGE}"
      puts "#{HELP} \n\n"
      exit(0)
    end
  end
  
  private
  
  # Verifies that all required parameters are passed in the argument.
  # Two types of required. First, parameters that are absolutely needed.
  # Second, parameters that are not all required but at least one must
  # be passed. 
  # Exits the script if parameter requirements are not satisfied.
  #
  def check_required_parameters(arguments)
    params_good = true

    @runner_parameters.each do |run_par|
      if arguments.include?(run_par)
        return true
      end
    end
    @required_parameters.each do |req_par|
      passed_reqpar = get_arg_value(req_par)
      if passed_reqpar.nil? || passed_reqpar == ''
        params_good = false
      end
    end
    
    has_atleast_one = true
    if @requires_atleast_one.size > 0
      has_atleast_one = false
      @requires_atleast_one.each do |least_one|
        luno = get_arg_value(least_one)
        if ! luno.nil? && luno != ""
          has_atleast_one = true
        end
      end
    end
    
    has_only_one = true
    if @requires_only_one.size > 0
      has_only_one = false
      num_detected = 0
      @requires_only_one.each do |only_one|
        if arg_exists?(only_one)
          num_detected += 1
        end
      end
      if num_detected == 1
        has_only_one = true
      end
    end
    
    if !params_good || ! has_atleast_one || ! has_only_one
      puts "#{REQUIRED}"
      exit(1)
    end
     
  end
  

end