require 'nokogiri'
require 'json'

# HISTORY: 1/7/2016    modified to handle just 1 file
#          3/21/2016   Allows indexing of test case, needed by ASCP tests
#                      e.g. (TestRail: [C11, C22], [C33, C44], 1) Last argument is an index (starts at 0)
#                      to mark test case C33 and C44. Modified method parse_trail_tag to implement this.
#
# TODO: Add SquishReport parser - done     
#       Clean up due to change when 1 file is passed in the constructor
#
class ResultsParser
  
  DEBUG_MODE = false 
  
  def initialize(results_path)
    checkIfDirectoryExists(results_path)
    @results_path = results_path
    #xmls = getAllXMLFiles(results_path)
    #readAllXMLFiles(xmls)
  end
  
  def checkIfDirectoryExists(xml_loc) 
    if ! File.directory?(xml_loc) && ! File.file?(xml_loc)
      puts "ERROR: Cannot find the XML results directory or file:"
      puts "       #{xml_loc}"
      puts "       Please check the path of the directory where the results are located.\n\n"
      exit(1)
    end
  end
  
  # Retrieves all .xml files in the directory passed as parameter
  # also recurssively gets subdirectory files because it uses Dir.glob
  # Return: array of file names with path where it is located.
  def getAllXMLFiles() 
    originalDir = Dir.pwd
    Dir.chdir @results_path
    filesArray = Array.new
    debug_msg "#{@results_path}/**/*.xml"
    Dir.glob("**/*.xml") do |f|
      debug_msg "XML: #{f}"
      filesArray << "#{@results_path}/" + f
    end
    Dir.chdir originalDir
    return filesArray
  end
  
  def readAllXMLFiles(xml_files)
    xml_files.each do |xml_file|
      read_XML_file(xml_file)
    end
  end
  
  # Reads XML file and uses nokogiri to parse
  # 
  def read_XML_file(xfile)
    result_array = []
    if File.file?(xfile)
      puts "\n\nOPENING #{xfile}"
      f = File.open(xfile)
      doc = Nokogiri::XML(f)
      if is_squish?(doc)
        result_array = squish_parser(doc)
      else
        result_array = rspec_parser(doc)
      end
    else
      puts "\nNot a file: #{xfile} - verify options (-x for directory, -f for a specific file)"
    end
    return result_array  
  end
  
  # Parses the SquishReport XML results file
  def squish_parser(nokigiri_doc)
    result_arr = []
    verifications = nokigiri_doc.xpath("//verification")
    verifications.each do |verification|
      #puts "ONEVER: #{verification}"
      trail_cases = parse_trail_tag(verification["name"])
      result = verification.xpath("result").first
      is_passed = squish_check_passed(result)
      debug_msg "\nVERIFICATION: #{verification["name"]} :: #{trail_cases}"
      trail_cases = parse_trail_tag(verification["name"])
      trail_cases.each do |trail_case|
        result_arr.push({:trail_case => trail_case, :passed => is_passed})
      end
    end
    debug_msg "Squish FINAL: #{result_arr}"
    return result_arr
  end
  
  # Parses the results of an RSPEC XML file.
  # TODO: 
  def rspec_parser(nokigiri_doc)
    result_arr = []
    testsuites = nokigiri_doc.xpath("//testsuites")
    testsuites.each do |suites|
      testsuite = suites.xpath("./testsuite")
      testsuite.each do |suite|
        debug_msg "\nSUITE: #{suite["name"]} "
        testsuite_name = suite["name"]
        testcases = suite.xpath("./testcase")
        testcases.each do |tcase|
          debug_msg "TESTCASE: #{tcase}"
          is_passed = false
          failure = tcase.xpath("./failure")
          if ! failure.nil?
            is_passed = true
            if failure.size > 0
              is_passed = false
            end
          end
          debug_msg "    TC: #{tcase["name"]}"
          testcase_name = tcase["name"]
          trail_cases = parse_trail_tag(testcase_name)
          trail_cases.each do |trail_case|
            result_arr.push({:trail_case => trail_case, :passed => is_passed})
          end
        end
      end
      debug_msg "FINAL: #{result_arr}"
      return result_arr
    end
  end
  
  # Parses the 'name' attribute of <testcase> and returns all 
  # test cases found. Returns an array in case a single test can mark off multiple test cases.
  # Ex. <testcase name="Login: should allow all valued users to successfully login (TestRail: C123, C888)
  # Returns ['C123', 'C888']
  def parse_trail_tag(name_line)
    case_arr = []
    ndex = get_index(name_line)
    if ndex < 0
      pattern = /\(TestRail:([Cc0-9\,\s]+)\)/
      just_cases = pattern.match(name_line)
      if ! just_cases.nil?
        debug_msg "HowMany #{just_cases[1]}"
        split_cases = just_cases[1].split(',')
        split_cases.each do |onecase|
          case_arr.push(onecase.strip)
        end
      end
      debug_msg "ARR: #{case_arr}"
    else
      case_arr = get_indexed_cases(name_line, ndex)
    end
    return case_arr
  end
  
  private
  
  # Called if the test cases are indexed as described in JIRA ticket ACI-206
  #
  def get_indexed_cases(name_line, nx)
    cases = []
    pattern = /\(TestRail:([Cc0-9\,\s\[\]\|]+)\:[0-9\s]+\)/
    just_cases = pattern.match(name_line)
    if ! just_cases.nil?
      case_tags = just_cases[1]
      debug_msg "PARSING: #{case_tags}"
      if (case_tags =~ /^\s*[Cc0-9\,\s]+$/)
        debug_msg "CASE COMMAS"
        indexed_case = case_tags.split(',')[nx].strip
        cases.push(indexed_case)
      elsif (case_tags =~ /^\s*[Cc0-9\,\s\|]+$/)
        debug_msg "CASE PIPES"
        indexed_case = case_tags.split('|')[nx]
        cases = strip_array(indexed_case.split(','))
      elsif (case_tags =~ /^\s*[Cc0-9\,\s\[\]]+$/)
        debug_msg "CASE BRACKETS"
        subed_tags = sub_brackets(case_tags)
        indexed_case = subed_tags.split('|')[nx]
        cases = strip_array(indexed_case.split(','))
        end
      end
      return cases
    end
  
  # Replaces ],[ and ], and ,[ with '|'
  def sub_brackets(nline)
    local_line = nline
    local_line.gsub!(/\]\s*\,\s*\[/, '|')
    local_line.gsub!(/\]\s*\,/, '|')
    local_line.gsub!(/\,\s*\[/, '|')
    return local_line.tr('[]', '')
  end
  
  # Parses for (TestRail: [C12, C13], [C21, C24], [C33]:2)
  # Returns the index number if found or -1 if not found
  def get_index(name_line)
    index_found = -1
    pattern = /\(TestRail:.*\:\s*([0-9]+)\s*\)/
    just_cases = pattern.match(name_line)
    if ! just_cases.nil?
      index_found = just_cases[1].to_i
    end
    return index_found
  end
  
  def is_squish?(nokigiri_doc)
    retval = false
    squish_report = nokigiri_doc.xpath("/SquishReport")
    if ! squish_report.nil? 
      if squish_report.size > 0
        retval = true
      end
    end
    return retval
  end
  
  def squish_check_passed(result_doc)
    retval = false
    if ! result_doc.nil?
      debug_msg "RESULT: #{result_doc}"
      get_type = result_doc['type']
      if get_type.downcase == "pass"
        retval = true
      end
    end
    debug_msg "PASED: #{retval}"
    return retval
  end
  
  # Removed all white spaces before/after each cell in
  # an array. Returns array.
  def strip_array(clothed_arr)
    fully_stripped = []
    clothed_arr.each do |onecase|
      fully_stripped.push(onecase.strip)
    end
    return fully_stripped
  end
  
  def debug_msg(msg)
    if DEBUG_MODE
      puts msg
    end
  end
  
end


