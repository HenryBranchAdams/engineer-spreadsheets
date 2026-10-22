#!/usr/bin/env ruby
# frozen_string_literal: true

require "minitest/autorun"
require "stringio"
require_relative "../scripts/lab"

# These are deterministic harness regressions, not model-quality evaluations.
class LabTest < Minitest::Test
  def setup
    @temporary = Pathname.new(Dir.mktmpdir("spreadsheet-lab-test-"))
    @created_run_dirs = []
    @original_codex_bin = ENV["CODEX_BIN"]
  end

  def teardown
    @created_run_dirs.each { |path| FileUtils.remove_entry(path) if path.exist? }
    FileUtils.remove_entry(@temporary)
    ENV["CODEX_BIN"] = @original_codex_bin
  end

  def new_run_directory(label)
    id, path = super
    @created_run_dirs << path
    [id, path]
  end

  def codex(*args, **kwargs)
    return @fake_codex.call(*args, **kwargs) if @fake_codex
    super
  end

  def codex_version
    @fake_codex ? "fake-codex-test" : super
  end

  def quiet
    saved = $stdout
    $stdout = StringIO.new
    yield
  ensure
    $stdout = saved
  end

  def test_selected_cases_rejects_partial_match_and_invalid_split
    first = load_json(EVALS_PATH)["cases"].first["id"]
    assert_raises(LabError) { selected_cases("development", [first, "missing-case"]) }
    assert_raises(LabError) { selected_cases("development", [first, first]) }
    assert_raises(LabError) { selected_cases("develpment", []) }
  end

  def test_run_paths_accept_repo_relative_and_legacy_relative_forms
    assert_equal PROJECT.join("engineer-spreadsheets"), resolve_skill_path("engineer-spreadsheets")
    assert_equal ROOT.join("fixtures"), resolve_skill_path("evaluation/engineer-spreadsheets/fixtures")
    assert_equal ROOT.join("fixtures"), resolve_skill_path("fixtures")
  end

  def test_same_second_runs_have_distinct_directories_and_labels_cannot_escape
    first_id, first_dir = new_run_directory("candidate-test")
    second_id, second_dir = new_run_directory("candidate-test")
    refute_equal first_id, second_id
    assert first_dir.directory?
    assert second_dir.directory?
    assert_raises(LabError) { new_run_directory("../../outside") }
  end

  def test_manifest_rejects_symlinks_to_unsealed_content
    @temporary.join("outside.md").write("not sealed")
    package = @temporary.join("package")
    package.mkpath
    File.symlink(@temporary.join("outside.md"), package.join("reference.md"))
    assert_raises(LabError) { tree_manifest(package) }
    assert_raises(LabError) { evidence_binding(package.join("reference.md")) }
  end

  def test_snapshot_is_immutable
    label = "test-#{SecureRandom.hex(5)}"
    package = @temporary.join("package")
    package.mkpath
    package.join("SKILL.md").write("test snapshot")
    quiet { snapshot(label, package) }
    assert_raises(LabError) { snapshot(label, package) }
  ensure
    FileUtils.remove_entry(SNAPSHOTS.join(label)) if label && SNAPSHOTS.join(label).exist?
  end

  def valid_grade(test_case)
    {"expectations" => test_case["expectations"].map { |item| {"id" => item["id"], "passed" => true, "evidence" => "Observed evidence."} },
     "material_findings" => [], "summary" => "Test fixture."}
  end

  def recorded_model_result(prompt, input_paths = [])
    submitted = prompt.dup
    inputs = input_paths.map(&:expand_path).sort_by { |path| -path.to_s.length }.each_with_index.map do |path, index|
      staged_path = "input-#{index + 1}/#{path.basename}"
      submitted.gsub!(path.to_s, "/tmp/spreadsheet-eval-fixture/#{staged_path}")
      evidence_binding(path).merge("staged_path" => staged_path)
    end
    {"exit_status" => 0, "submitted_prompt" => submitted,
     "submitted_prompt_sha256" => Digest::SHA256.hexdigest(submitted), "input_evidence" => inputs}
  end

  def test_grade_rejects_truthy_strings_missing_evidence_and_duplicate_ids
    test_case = load_json(EVALS_PATH)["cases"].first
    ["true", "false", nil, 1].each do |value|
      grade = valid_grade(test_case)
      grade["expectations"].first["passed"] = value
      assert_raises(LabError) { validate_grade!(grade, test_case) }
    end
    grade = valid_grade(test_case)
    grade["expectations"].first["evidence"] = " "
    assert_raises(LabError) { validate_grade!(grade, test_case) }
    grade = valid_grade(test_case)
    grade["expectations"][1]["id"] = grade["expectations"][0]["id"]
    assert_raises(LabError) { validate_grade!(grade, test_case) }
    assert_equal valid_grade(test_case), validate_grade!(valid_grade(test_case), test_case)
  end

  def make_behavior_fixture(cases, failed_noncritical: 0)
    run = @temporary.join("run")
    run.mkpath
    skill_path = @temporary.join("package")
    skill_path.mkpath
    skill_path.join("SKILL.md").write("Fixture instruction skill.")
    skill_hash, = tree_manifest(skill_path)
    metadata = {"skill_condition" => "with-skill", "skill_path" => skill_path.to_s,
      "skill_tree_sha256" => skill_hash, "selected_case_ids" => cases.map { |test_case| test_case["id"] }.sort,
      "cases" => [], "model" => "fixture", "codex_version" => "fixture"}
    cases.each do |test_case|
      directory = run.join(test_case["id"])
      directory.mkpath
      directory.join("output.md").write("Untrusted response fixture.")
      directory.join("prompt.sha256").write(Digest::SHA256.hexdigest(test_case["prompt"]) + "\n")
      prompt = behavior_prompt(skill_path, test_case)
      directory.join("behavior-prompt.md").write(prompt)
      directory.join("runner.json").write(canonical_json(recorded_model_result(prompt, [skill_path]).merge(
        "output_sha256" => sha(directory.join("output.md")), "prompt_sha256" => sha(directory.join("behavior-prompt.md")))))
      grade = valid_grade(test_case)
      test_case["expectations"].each do |expectation|
        next unless !expectation["critical"] && failed_noncritical.positive?
        grade["expectations"].find { |item| item["id"] == expectation["id"] }["passed"] = false
        failed_noncritical -= 1
      end
      directory.join("grading.json").write(canonical_json(grade))
      prompt = grader_prompt(test_case, directory.join("output.md"))
      directory.join("grader-prompt.md").write(prompt)
      directory.join("grader-runner.json").write(canonical_json(recorded_model_result(prompt, [directory.join("output.md")]).merge(
        "prompt_sha256" => sha(directory.join("grader-prompt.md")), "grader_output_sha256" => sha(directory.join("grading.json")),
        "response_sha256" => sha(directory.join("output.md")), "skill_tree_sha256" => skill_hash,
        "case_definition_sha256" => case_definition_sha256(test_case))))
      metadata["cases"] << {"id" => test_case["id"], "output_sha256" => sha(directory.join("output.md")),
        "case_definition_sha256" => case_definition_sha256(test_case)}
    end
    run.join("run.json").write(canonical_json(metadata))
    run
  end

  def test_behavior_report_enforces_noncritical_rate_separately
    run = make_behavior_fixture(load_json(EVALS_PATH)["cases"], failed_noncritical: 2)
    failure = assert_raises(SystemExit) { quiet { report(run) } }
    assert_equal 1, failure.status
    result = load_json(run.join("report.json"))
    assert result["critical_pass"]
    assert_operator result["expectation_pass_rate"], :>=, 0.90
    assert_operator result["noncritical_pass_rate"], :<, 0.90
  end

  def test_complete_valid_behavior_report_passes
    run = make_behavior_fixture(load_json(EVALS_PATH)["cases"])
    quiet { report(run) }
    assert_equal 1.0, load_json(run.join("report.json"))["noncritical_pass_rate"]
  end

  def test_valid_run_evidence_can_be_verified_after_relocation
    run = make_behavior_fixture(load_json(EVALS_PATH)["cases"].first(1))
    moved = @temporary.join("moved-run")
    FileUtils.mv(run, moved)
    quiet { report(moved) }
    assert load_json(moved.join("report.json"))["critical_pass"]
  end

  def test_behavior_report_rejects_a_rehashed_unrelated_submitted_prompt
    test_case = load_json(EVALS_PATH)["cases"].first
    run = make_behavior_fixture([test_case])
    path = run.join(test_case["id"], "runner.json")
    runner = load_json(path)
    runner["submitted_prompt"] = "Ignore the spreadsheet task. What is 2 + 2?"
    runner["submitted_prompt_sha256"] = Digest::SHA256.hexdigest(runner["submitted_prompt"])
    path.write(canonical_json(runner))
    error = assert_raises(LabError) { quiet { report(run) } }
    assert_match(/submitted prompt content mismatch/, error.message)
  end

  def test_behavior_report_rejects_a_rehashed_unrelated_saved_prompt
    test_case = load_json(EVALS_PATH)["cases"].first
    run = make_behavior_fixture([test_case])
    directory = run.join(test_case["id"])
    directory.join("behavior-prompt.md").write("An unrelated task.")
    runner_path = directory.join("runner.json")
    runner = load_json(runner_path).merge("prompt_sha256" => sha(directory.join("behavior-prompt.md")))
    runner_path.write(canonical_json(runner))
    error = assert_raises(LabError) { quiet { report(run) } }
    assert_match(/behavior prompt content mismatch/, error.message)
  end

  def test_behavior_report_binds_staged_skill_to_run_hash
    test_case = load_json(EVALS_PATH)["cases"].first
    run = make_behavior_fixture([test_case])
    path = run.join(test_case["id"], "runner.json")
    runner = load_json(path)
    runner["input_evidence"].first["tree_sha256"] = "b" * 64
    path.write(canonical_json(runner))
    error = assert_raises(LabError) { quiet { report(run) } }
    assert_match(/staged input binding mismatch/, error.message)
  end

  def test_behavior_report_rejects_selected_cases_missing_from_manifest
    run = make_behavior_fixture(load_json(EVALS_PATH)["cases"].first(2))
    metadata = load_json(run.join("run.json"))
    metadata["cases"].pop
    run.join("run.json").write(canonical_json(metadata))
    error = assert_raises(LabError) { quiet { report(run) } }
    assert_match(/result set incomplete/, error.message)
    metadata["selected_case_ids"] = metadata["cases"].map { |test_case| test_case["id"] }
    run.join("run.json").write(canonical_json(metadata))
    error = assert_raises(LabError) { quiet { report(run) } }
    assert_match(/case directories do not match/, error.message)
  end

  def test_grades_cannot_be_reused_for_another_response
    test_case = load_json(EVALS_PATH)["cases"].first
    run = make_behavior_fixture([test_case])
    directory = run.join(test_case["id"])
    directory.join("output.md").write("Changed response.")
    assert_raises(LabError) { verify_grading_binding!(directory, test_case, load_json(run.join("run.json"))["skill_tree_sha256"]) }
  end

  def test_grading_verifies_the_staged_response_hash
    test_case = load_json(EVALS_PATH)["cases"].first
    run = make_behavior_fixture([test_case])
    directory = run.join(test_case["id"])
    path = directory.join("grader-runner.json")
    runner = load_json(path)
    runner["input_evidence"].first["sha256"] = "b" * 64
    path.write(canonical_json(runner))
    error = assert_raises(LabError) { quiet { report(run) } }
    assert_match(/staged input binding mismatch/, error.message)
  end

  def test_grading_resumes_after_verified_complete_cases_without_overwriting
    cases = load_json(EVALS_PATH)["cases"].first(2)
    run = make_behavior_fixture(cases)
    complete_before = tree_manifest(run.join(cases.first["id"]))
    pending = run.join(cases.last["id"])
    %w[grading.json grader-prompt.md grader-runner.json].each { |name| pending.join(name).delete }
    calls = []
    @fake_codex = lambda do |prompt, output, *_args, **kwargs|
      calls << output.dirname.basename.to_s
      output.write(canonical_json(valid_grade(cases.last)))
      recorded_model_result(prompt, kwargs.fetch(:input_paths))
    end
    quiet { grade_run(run) }
    assert_equal [cases.last["id"]], calls
    assert_equal complete_before, tree_manifest(run.join(cases.first["id"]))
    quiet { report(run) }
    after = tree_manifest(run)
    quiet { grade_run(run) }
    assert_equal [cases.last["id"]], calls
    assert_equal after, tree_manifest(run)
  end

  def test_grading_rejects_partial_evidence_before_writing_or_calling_a_model
    cases = load_json(EVALS_PATH)["cases"].first(2)
    run = make_behavior_fixture(cases)
    run.join(cases.last["id"], "grader-runner.json").delete
    before = tree_manifest(run)
    @fake_codex = ->(*) { flunk "partial evidence must be rejected before model execution" }
    error = assert_raises(LabError) { quiet { grade_run(run) } }
    assert_match(/partial grading evidence/, error.message)
    assert_equal before, tree_manifest(run)
  end

  def test_behavior_report_rejects_failed_runner
    test_case = load_json(EVALS_PATH)["cases"].first
    run = make_behavior_fixture([test_case])
    runner_path = run.join(test_case["id"], "runner.json")
    runner = load_json(runner_path).merge("exit_status" => 1)
    runner_path.write(canonical_json(runner))
    assert_raises(LabError) { quiet { report(run) } }
  end

  def test_zero_repeat_trigger_run_is_rejected_before_model_call
    [0, -1].each do |repeats|
      assert_raises(LabError) { run_triggers(PROJECT.join("engineer-spreadsheets"), repeats) }
    end
  end

  def fake_triggers(fail_exclusion: false)
    queries = load_json(TRIGGERS_PATH)["queries"]
    exclusion = queries.find { |query| query["exclusion_precedence"] }
    refute_nil exclusion, "regression requires a declared exclusion case"
    @fake_codex = lambda do |prompt, output, *_args, **_kwargs|
      query = queries.find { |item| prompt.include?(item["query"]) }
      actual = fail_exclusion && query == exclusion ? true : query["should_trigger"]
      output.write(canonical_json({"trigger" => actual, "reason" => "Test fixture."}))
      recorded_model_result(prompt)
    end
  end

  def test_exclusion_false_positive_fails_even_at_90_percent_specificity
    fake_triggers(fail_exclusion: true)
    assert_raises(LabError) { quiet { run_triggers(PROJECT.join("engineer-spreadsheets"), 1) } }
    result = load_json(@created_run_dirs.last.join("trigger-report.json"))
    assert_equal 0.9, result["specificity"]
    assert_equal 1, result["exclusion_false_positives"]
  end

  def test_trigger_evidence_detects_tampering
    fake_triggers
    quiet { run_triggers(PROJECT.join("engineer-spreadsheets"), 1) }
    directory = @created_run_dirs.last
    directory.join("t01-1.json").write('{"trigger": false, "reason": "changed"}')
    assert_raises(LabError) { quiet { verify_trigger_report(directory) } }
  end

  def test_trigger_requires_package_hash_and_bound_description
    fake_triggers
    quiet { run_triggers(PROJECT.join("engineer-spreadsheets"), 1) }
    directory = @created_run_dirs.last
    path = directory.join("trigger-report.json")
    original = load_json(path)
    [nil, "not-a-package-hash", "a" * 64].each do |bad_hash|
      changed = original.merge("skill_tree_sha256" => bad_hash)
      path.write(canonical_json(changed))
      assert_raises(LabError) { quiet { verify_trigger_report(directory) } }
    end
    path.write(canonical_json(original))
    directory.join("skill-core.md").write("unrelated core")
    assert_raises(LabError) { quiet { verify_trigger_report(directory) } }
  end

  def test_trigger_checks_actual_submitted_prompt
    fake_triggers
    quiet { run_triggers(PROJECT.join("engineer-spreadsheets"), 1) }
    directory = @created_run_dirs.last
    runner_path = directory.join("t01-1-runner.json")
    runner_path.write(canonical_json(recorded_model_result("unrelated request")))
    report_path = directory.join("trigger-report.json")
    result = load_json(report_path)
    result["results"].find { |item| item["id"] == "t01" }["runner_sha256"] = sha(runner_path)
    report_path.write(canonical_json(result))
    assert_raises(LabError) { quiet { verify_trigger_report(directory) } }
  end

  def test_new_run_source_snapshot_is_bound
    _id, directory = new_run_directory("source-test")
    metadata = {"schema_version" => 2, "runner_source_sha256" => RUNNER_SOURCE_SHA256}
    assert_equal RUNNER_SOURCE_SHA256, verify_runner_source!(directory, metadata)
    directory.join("lab-source.rb").write("changed source")
    assert_raises(LabError) { verify_runner_source!(directory, metadata) }
  end

  def test_without_skill_baseline_passes_no_package_context
    calls = []
    @fake_codex = lambda do |prompt, output, *_args, **kwargs|
      calls << [prompt, kwargs.fetch(:input_paths)]
      output.write("Baseline response.")
      recorded_model_result(prompt)
    end
    id = load_json(EVALS_PATH)["cases"].first["id"]
    quiet { main(["run", "--without-skill", "test-no-skill", "development", id]) }
    assert_empty calls.first[1]
    refute_includes calls.first[0], "SKILL.md"
    metadata = load_json(@created_run_dirs.last.join("run.json"))
    assert_equal "without-skill", metadata["skill_condition"]
    assert_nil metadata["skill_path"]
    assert_nil metadata["skill_tree_sha256"]
    test_case = load_json(EVALS_PATH)["cases"].find { |item| item["id"] == id }
    verify_behavior_case_binding!(@created_run_dirs.last, test_case, metadata["cases"].first)
  end

  def test_process_io_cannot_deadlock_on_large_prompt_and_output
    source = "STDOUT.write('o' * 200_000); STDERR.write('e' * 200_000); STDIN.read"
    out, err, status = run_process([RbConfig.ruby, "-e", source], stdin_text: "p" * 200_000, timeout_seconds: 3)
    assert status.success?
    assert_equal 200_000, out.length
    assert_equal 200_000, err.length
  end

  def test_timeout_includes_children_holding_output_pipes_open
    source = "fork { sleep 30 }; exit 0"
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    error = assert_raises(LabError) { run_process([RbConfig.ruby, "-e", source], timeout_seconds: 0.2) }
    assert_match(/timed out/, error.message)
    assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, :<, 3
  end

  def test_missing_executable_has_actionable_failure
    error = assert_raises(LabError) { run_process([@temporary.join("missing-executable").to_s]) }
    assert_match(/executable unavailable/, error.message)
  end

  def test_codex_failure_preserves_short_error_text
    executable = @temporary.join("failing-codex")
    executable.write("#!#{RbConfig.ruby}\nSTDERR.write('Authentication unavailable'); exit 1\n")
    executable.chmod(0o755)
    ENV["CODEX_BIN"] = executable.to_s
    error = assert_raises(LabError) { codex("test", @temporary.join("no-response.md")) }
    assert_match(/Authentication unavailable/, error.message)
  end

  def test_codex_receives_only_staged_inputs_in_a_fresh_working_directory
    executable = @temporary.join("fake-codex")
    executable.write(<<~RUBY)
      #!#{RbConfig.ruby}
      require "json"
      directory = ARGV.fetch(ARGV.index("-C") + 1)
      output = ARGV.fetch(ARGV.index("-o") + 1)
      File.write(output, JSON.generate({"directory" => directory, "files" => Dir.glob("**/*", base: directory), "prompt" => STDIN.read}))
    RUBY
    executable.chmod(0o755)
    ENV["CODEX_BIN"] = executable.to_s
    package = @temporary.join("skill")
    package.mkpath
    package.join("SKILL.md").write("Task instructions.")
    @temporary.join("expected-answers.json").write("Should not be staged.")
    output = @temporary.join("response.json")
    result = codex("Read #{package.join('SKILL.md')}", output, input_paths: [package])
    evidence = load_json(output)
    refute_equal PROJECT.to_s, evidence["directory"]
    assert_includes evidence["files"], "input-1/skill/SKILL.md"
    refute_includes evidence["files"], "expected-answers.json"
    refute_includes evidence["prompt"], package.to_s
    assert_equal Digest::SHA256.hexdigest(evidence["prompt"]), result["submitted_prompt_sha256"]
    refute Pathname.new(evidence["directory"]).exist?
    assert_raises(LabError) { codex("another request", output) }
  end
end
