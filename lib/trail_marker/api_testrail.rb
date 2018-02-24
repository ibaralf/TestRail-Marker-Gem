# TODO: CLEAN UP or DRY testruns and testplans methods since can be combined.
#       Refactor attr_accessor variables to be class variables
#       Implement other API calls
#  
class ApiTestRail
  attr_accessor :project_id, :suite_id, :run_id, :test_case_id, :section_id

  def initialize(client)
    @client = client
    @projects = get_projects()
    @project = nil
    @suites = nil
    @suite = nil
    @plans = nil
    @plan = nil
    @runs = nil
    @run = nil
    @test_cases = nil
    @test_case = nil
    @milestones = nil
    @milestone = nil
    @statuses = get_statuses()
  end
  
  # Returns the project ID of the project name passed.
  # 
  def get_project_id(project_name)
    if @projects.nil?
      get_projects()
    end
    project_id = search_array_kv(@projects, 'name', project_name, 'id')
    if project_id.nil?
      puts "\nProject '#{project_name}' WAS NOT FOUND, select from available projects."
      resp_projects = Response.new(@projects)
      project_name = resp_projects.picker("name")
      project_id = search_array_kv(@projects, 'name', project_name, 'id')
    end
    return project_id
  end
  
  def get_milestone_id(project_id, milestone_name)
    ms_id = nil
    if ! milestone_exists?(project_id, milestone_name)
      puts "\nMilestone '#{milestone_name}' WAS NOT FOUND, select from available milestones."
      resp_ms = Response.new(@milestones)
      milestone_name = resp_ms.picker("name")
      #ms_id = search_array_kv(@milestones, 'name', milestone_name, 'id')
    end
    ms_id = search_array_kv(@milestones, 'name', milestone_name, 'id')
    return ms_id
  end
  
  def get_test_runplan_id(project_id, runplan_name)
    if @runs.nil?
      get_runs(project_id)
    end
    run_id = search_array_kv(@runs, 'name', runplan_name, 'id')
    if run_id.nil?
      puts "\nTest Run WAS NOT FOUND, select from available."
      resp_runs = Response.new(@runs)
      runplan_name = resp_runs.picker("name")
      run_id = search_array_kv(@runs, 'name', runplan_name, 'id')
    end
    return run_id
  end
  
  def get_testplan_id(project_id, testplan_name)
    if @plans.nil?
      get_plans(project_id)
    end
    plan_id = search_array_kv(@plans, 'name', testplan_name, 'id')
    if plan_id.nil?
      puts "\nTestPlan #{testplan_name} WAS NOT FOUND, select from available."
      resp_plans = Response.new(@plans)
      plan_name = resp_plans.picker("name")
      plan_id = search_array_kv(@plans, 'name', plan_name, 'id')
    end
    return plan_id
  end
  
  def get_suite_id(proj_id, suite_name)
    suite_id = nil
    if suite_exists?(proj_id, suite_name)
      suite_id = search_array_kv(@suites, 'name', suite_name, 'id')
    end
    return suite_id
  end
  
  def get_projects()
    @projects = request_get('get_projects')
    return @projects
  end
  
  def get_milestones(proj_id)
    ms_req = "get_milestones/" + proj_id.to_s
    @milestones = request_get(ms_req)
  end
  
  def get_runs(proj_id)
    runs_req = "get_runs/" + proj_id.to_s
    @runs = request_get(runs_req)
  end
  
  def get_plans(proj_id)
    plans_req = "get_plans/" + proj_id.to_s
    @plans = request_get(plans_req)
  end
  
  def get_plan(plan_id)
    plan_req = "get_plan/" + plan_id.to_s
    @plan = request_get(plan_req)
  end
  
  def get_suites(proj_id)
    suite_req = "get_suites/" + proj_id.to_s
    @suites = request_get(suite_req)
  end
  
  ######################## VERIFY 
  
  def milestone_exists?(project_id, milestone_name)
    it_exists = false
    if @milestones.nil?
      get_milestones(project_id)
    end
    puts "ALL MILES: #{@milestones}"
    ms_id = search_array_kv(@milestones, 'name', milestone_name, 'id')
    if ! ms_id.nil?
      it_exists = true
    end
    return it_exists
  end
  
  def run_exists?(proj_id, run_name)
    it_exists = false
    if @runs.nil? 
      @runs = get_runs(proj_id)
    end
    run_id = search_array_kv(@runs, 'name', run_name, 'id')
    if ! run_id.nil?
      it_exists = true
    end
    return it_exists
  end
  
  def suite_exists?(proj_id, suite_name)
    it_exists = false
    if @suites.nil? 
      @suites = get_suites(proj_id)
    end
    suite_id = search_array_kv(@suites, 'name', suite_name, 'id')
    if ! suite_id.nil?
      it_exists = true
    end
    return it_exists
  end
  
  #############
  
  # Makes an API call to get all possible results status. Currently has 5
  # passed, blocked, untested, retest, failed. 
  # Puts the name and status in @statuses array.
  #
  def get_statuses()
    @statuses = []
    status_req = request_get('get_statuses')
    status_req.each do |status|
      status_hash  ={}
      status_hash['id'] = status['id']
      status_hash['name'] = status['name']
      @statuses.push(status_hash)
    end
    return @statuses
  end
  
  
  
  ######################## TEST PLANS #########################
  
  # Returns an array of testrun IDs that is inside a testplan.
  #
  def get_testplan_testruns(testplan_id)
    run_ids = []
    plan_resp = get_plan(testplan_id)
    tp_entries = plan_resp['entries']
    tp_entries.each do |entry|
      entry_runs = entry['runs']
      entry_runs.each do |erun|
        run_ids.push(erun['id'])
      end
    end
    return run_ids
  end
  
  # Returns array of id for testruns inside a testplan
  def get_testplan_run_ids(project_id, testplan_name)
    testplan_id = get_testplan_id(project_id, testplan_name)
    get_testplan_testruns(testplan_id)
  end
  
  # NOTE - NOT USED RIGHT NOW.
  # Marks a test case inside a testplan. Testplans adds extra API calls
  # because testruns are inside the testplans and are not named.
  # See note below MARK_TESTPLAN
  def markoff_testplan(case_id, testplan_id, pass_status)
    status_id = search_array_kv(@statuses, 'name', 'failed', 'id')
    defect_txt = ""
    if pass_status
      status_id = search_array_kv(@statuses, 'name', 'passed', 'id')
      defect_txt = ""
    end
    equiv_json = {:status_id => status_id, :comment => 'Auto marker.', :defects => defect_txt}
    add_result_req = "add_result_for_case/" + run_id.to_s + "/" + case_id.to_s
    request_post(add_result_req, equiv_json)
  end
  
  def get_testid(run_id, case_id)
    puts "SEARCH FOR TESTID: #{run_id}  :: #{case_id}"
    tests_req = 'get_tests/' + run_id.to_s
    tests_resp = request_get(tests_req)
    puts "GET_TESTS: #{tests_resp}"
    id_equiv = search_array_kv(tests_resp, 'case_id', case_id.to_i, 'id')
    return id_equiv
  end

  
  
  # TODO: Parse XML for failed reason and add to comment(?)
  #
  def markoff_test(case_id, run_id, pass_status, comment_txt)
    status_id = search_array_kv(@statuses, 'name', 'failed', 'id')
    defect_txt = ""
    if pass_status
      status_id = search_array_kv(@statuses, 'name', 'passed', 'id')
      defect_txt = ""
    end
    equiv_json = {:status_id => status_id, :comment => comment_txt, :defects => defect_txt}
    add_result_req = "add_result_for_case/" + run_id.to_s + "/" + case_id.to_s
    request_post(add_result_req, equiv_json)
  end
  
  # Makes a post call to create a new milestone
  def create_milestone(proj_name, msname)
    proj_id = get_project_id(proj_name)
    if ! milestone_exists?(proj_id, msname)
      puts "Create Milestones #{msname} in Project #{proj_name} "
      unix_timestamp = Time.now.to_i 
      req_field = {:name => msname, :due_on => unix_timestamp}
      create_milestone_req = "add_milestone/" + proj_id.to_s
      request_post(create_milestone_req, req_field)
      sleep(2)
      get_milestones(proj_id)
    end
  end
  
  def delete_milestone(proj_name, msname)
    proj_id = get_project_id(proj_name)
    ms_id = get_milestone_id(proj_id, msname)
    del_ms_req = "delete_milestone/" + ms_id.to_s
    request_post(del_ms_req, nil)
    exit
  end
  
  def create_testrun(proj_name, msname, trname, tsname)
    proj_id = get_project_id(proj_name)
    if ! run_exists?(proj_id, trname)
      if suite_exists?(proj_id, tsname)
        ms_id = nil
        if ! msname.nil? && msname != ""
          ms_id = get_milestone_id(proj_id, msname)
        end
        puts "MSID: #{msname} #{ms_id}"
        ts_id = get_suite_id(proj_id, tsname)
        req_field = {:name => trname, :suite_id => ts_id, :description => "AutoCreated"}
        if ! ms_id.nil? && ms_id != ""
          req_field[:milestone_id] = ms_id
        end
        add_run_req = "add_run/" + proj_id.to_s
        request_post(add_run_req, req_field)
        puts "CREATING RUN under #{proj_name} #{req_field}"
        sleep(2)
        get_runs(proj_id)
      else
        puts "CANNOT Create New TestRun, (-s) test suite name needed."
      end
    else
      puts "CANNOT Create RUN #{trname}, already exists."
    end
  end
  
  private 
  
  def request_get(api_cmd)
    req = Request.new(@client)
    resp = req.exec_get(api_cmd)
    return resp
  end
  
  def request_post(api_cmd, data)
    req = Request.new(@client)
    resp = req.exec_post(api_cmd, data)
    return resp
  end
  
  # Searched an array of hashes for a key and value to match
  # and returns a field of that hash.
  # * *Args*  : 
  #   - +rdata+ -> Array of hash data (e.g)
  #   - +k+ -> key (e.g. "name")
  #   - +v+ -> value to find (e.g. "Test Project")
  #   - +key_return+ -> name of another field to return (e.g. "id")
  # * *Returns* : 
  #   - Value of a field in the hash
  #   - nil if none found
  #
  # Example: rdata: [{'id' => 12, 'name' => 'Project-Files, 'owner' => 'Serban', 'run_name' => 'Sprint 2'}, 
  #                  {'id' => 22, 'name' => 'Faspex, 'owner' => 'Ajanta', 'run_name' => 'Marathon 10'}]
  #  
  #          search_array_kv(rdata, "name", "Faspex", "owner")
  #          => Calling this find the hash that has 'Faspex' for name, 
  #             then return the value of 'owner' in that hash 'Ajanta'
  #
  def search_array_kv(rdata, k, v, key_return)
    retval = nil
    fnd = rdata.detect {|unhash| unhash[k] == v}
    if ! fnd.nil?
      retval = fnd[key_return]
    end
    return retval
  end
  
   
  # NOTE: MARK_TEST_PLAN
  # User Input: Project Name, TestRun Name
  # Project Name > Get project_id
  # Call API get_plans/project_id to get all test plans for the project
  # Get testplan_id of testplan with the given name
  # Call API get_plan/testplan_id to get testruns inside this testplan
  # 
  
  
  
  
  
  ############### DELETE THESE NOT USED
  
  # TODO: Parse XML for failed reason and add to comment(?)
  #
  # def markoff_test(case_id, run_id, pass_status)
    # status_id = search_array_kv(@statuses, 'name', 'failed', 'id')
    # defect_txt = ""
    # if pass_status
      # status_id = search_array_kv(@statuses, 'name', 'passed', 'id')
      # defect_txt = ""
    # end
    # equiv_json = {:status_id => status_id, :comment => 'Auto marker.', :defects => defect_txt}
    # add_result_req = "add_result_for_case/" + run_id.to_s + "/" + case_id.to_s
    # request_post(add_result_req, equiv_json)
  # end
#   
  
 
  
end