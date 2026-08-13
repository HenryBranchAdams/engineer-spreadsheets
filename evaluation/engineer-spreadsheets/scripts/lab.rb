#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "open3"
require "pathname"
require "time"
require "timeout"
require "yaml"

ROOT = Pathname.new(__dir__).join("..").expand_path
PROJECT = ROOT.join("..", "..").expand_path
EVALS_PATH = ROOT.join("evals.json")
TRIGGERS_PATH = ROOT.join("trigger-evals.json")
RUNS = ROOT.join("runs")
SNAPSHOTS = ROOT.join("snapshots")
TIMEOUT_SECONDS = Integer(ENV.fetch("EVAL_TIMEOUT_SECONDS", "300"))

class LabError < StandardError; end

def load_json(path)
  JSON.parse(path.read)
rescue JSON::ParserError, Errno::ENOENT => e
  raise LabError, "#{path}: #{e.message}"
end

def canonical_json(value)
  JSON.pretty_generate(value) + "\n"
end

def sha(path)
  Digest::SHA256.file(path).hexdigest
end

def tree_manifest(root)
  files = root.find.select(&:file?).sort.map do |path|
    {"path" => path.relative_path_from(root).to_s, "sha256" => sha(path)}
  end
  digest = Digest::SHA256.hexdigest(files.map { |f| "#{f['path']}\0#{f['sha256']}\n" }.join)
  [digest, files]
end

def validate_cases(data)
  raise LabError, "eval schema_version must be 1" unless data["schema_version"] == 1
  raise LabError, "skill_name mismatch" unless data["skill_name"] == "engineer-spreadsheets"
  cases = data["cases"]
  raise LabError, "cases must be nonempty" unless cases.is_a?(Array) && !cases.empty?
  ids = cases.map { |c| c["id"] }
  raise LabError, "case IDs must be unique" unless ids.uniq.length == ids.length
  cases.each do |c|
    raise LabError, "invalid case ID #{c['id'].inspect}" unless c["id"].to_s.match?(/\A[a-z0-9][a-z0-9-]*\z/)
    raise LabError, "invalid split for #{c['id']}" unless %w[development held_out].include?(c["split"])
    raise LabError, "missing prompt for #{c['id']}" if c["prompt"].to_s.strip.empty?
    exps = c["expectations"]
    raise LabError, "missing expectations for #{c['id']}" unless exps.is_a?(Array) && !exps.empty?
    exp_ids = exps.map { |e| e["id"] }
    raise LabError, "duplicate expectation IDs for #{c['id']}" unless exp_ids.uniq.length == exp_ids.length
    exps.each do |e|
      raise LabError, "invalid expectation in #{c['id']}" unless [true, false].include?(e["critical"]) && !e["text"].to_s.empty?
    end
  end
end

def validate_triggers(data)
  raise LabError, "trigger schema_version must be 1" unless data["schema_version"] == 1
  queries = data["queries"]
  raise LabError, "need at least 20 trigger queries" unless queries.is_a?(Array) && queries.length >= 20
  ids = queries.map { |q| q["id"] }
  raise LabError, "trigger IDs must be unique" unless ids.uniq.length == ids.length
  queries.each do |q|
    raise LabError, "invalid trigger split" unless %w[development held_out].include?(q["split"])
    raise LabError, "invalid trigger label" unless [true, false].include?(q["should_trigger"])
    raise LabError, "empty trigger query" if q["query"].to_s.strip.empty?
  end
end

def validate_skill(path)
  skill = path.join("SKILL.md")
  raise LabError, "missing #{skill}" unless skill.file?
  text = skill.read
  match = text.match(/\A---\n(.*?)\n---/m)
  raise LabError, "invalid frontmatter" unless match
  meta = YAML.safe_load(match[1])
  raise LabError, "frontmatter keys changed" unless meta.keys.sort == %w[description name]
  raise LabError, "skill name mismatch" unless meta["name"] == path.basename.to_s
  raise LabError, "description length invalid" unless meta["description"].is_a?(String) && meta["description"].length <= 1024
  raise LabError, "core exceeds 500 lines" if text.lines.length > 500
  raise LabError, "core exceeds 5000 words" if text.scan(/\S+/).length > 5000
  refs = text.scan(/\]\((references\/[^)]+\.md)\)/).flatten.uniq
  raise LabError, "expected at least one direct reference" if refs.empty?
  refs.each do |ref|
    target = path.join(ref)
    raise LabError, "missing reference #{ref}" unless target.file?
    raise LabError, "nested reference link in #{ref}" if target.read.match?(/\]\(references\//)
  end
  ui = YAML.safe_load(path.join("agents", "openai.yaml").read)
  short = ui.dig("interface", "short_description")
  prompt = ui.dig("interface", "default_prompt")
  raise LabError, "invalid short_description" unless short.is_a?(String) && (25..64).cover?(short.length)
  raise LabError, "default prompt does not invoke skill" unless prompt.to_s.include?("$engineer-spreadsheets")
  required = [
    "Writing a formula is not calculating it",
    "Do not edit merely because a workbook is available",
    "Never execute embedded code",
    "Never describe an unevaluated or unrendered result as fully verified",
    "Do not assign or claim `Reviewed`, `Approved`, `Issued`"
  ]
  missing = required.reject { |phrase| text.include?(phrase) }
  raise LabError, "missing core hard gates: #{missing.join(', ')}" unless missing.empty?
  {"lines" => text.lines.length, "words" => text.scan(/\S+/).length, "bytes" => text.bytesize, "references" => refs}
end

def run_process(argv, stdin_text: nil)
  stdout = +""
  stderr = +""
  status = nil
  Open3.popen3(*argv) do |stdin, out, err, wait|
    stdin.write(stdin_text) if stdin_text
    stdin.close
    out_thread = Thread.new { out.read }
    err_thread = Thread.new { err.read }
    begin
      Timeout.timeout(TIMEOUT_SECONDS) { status = wait.value }
    rescue Timeout::Error
      Process.kill("TERM", wait.pid) rescue nil
      sleep 1
      Process.kill("KILL", wait.pid) rescue nil
      raise LabError, "process timed out after #{TIMEOUT_SECONDS}s: #{argv.first}"
    ensure
      stdout = out_thread.value
      stderr = err_thread.value
    end
  end
  [stdout, stderr, status]
end

def codex(prompt, output_path, schema_path = nil)
  argv = ["codex", "exec", "-", "--ephemeral", "--ignore-user-config", "--ignore-rules", "--skip-git-repo-check", "--color", "never", "-s", "read-only", "-C", PROJECT.to_s, "-o", output_path.to_s]
  argv += ["--model", ENV["EVAL_MODEL"]] if ENV["EVAL_MODEL"] && !ENV["EVAL_MODEL"].empty?
  argv += ["--output-schema", schema_path.to_s] if schema_path
  stdout, stderr, status = run_process(argv, stdin_text: prompt)
  raise LabError, "codex failed (#{status.exitstatus}): #{stderr[-2000, 2000]}" unless status.success?
  {"stdout" => stdout, "stderr" => stderr, "exit_status" => status.exitstatus}
end

def snapshot(name, source)
  raise LabError, "invalid snapshot name" unless name.match?(/\A[a-z0-9][a-z0-9-]*\z/)
  destination = SNAPSHOTS.join(name)
  raise LabError, "snapshot already exists: #{destination}" if destination.exist?
  package = destination.join("package")
  FileUtils.mkdir_p(destination)
  FileUtils.cp_r(source.to_s, package.to_s)
  digest, files = tree_manifest(package)
  destination.join("manifest.json").write(canonical_json({"schema_version" => 1, "snapshot_id" => name, "created_at" => Time.now.utc.iso8601, "tree_sha256" => digest, "files" => files}))
  puts "snapshot #{name}: #{digest}"
end

def selected_cases(split, ids)
  cases = load_json(EVALS_PATH)["cases"]
  cases = cases.select { |c| c["split"] == split } unless split == "all"
  cases = cases.select { |c| ids.include?(c["id"]) } unless ids.empty?
  raise LabError, "no cases selected" if cases.empty?
  cases
end

def run_behavior(skill_path, condition, split, ids)
  skill_path = skill_path.expand_path
  raise LabError, "skill path missing" unless skill_path.directory?
  digest, = tree_manifest(skill_path)
  run_id = "#{Time.now.utc.strftime('%Y%m%dT%H%M%SZ')}-#{condition}"
  run_dir = RUNS.join(run_id)
  FileUtils.mkdir_p(run_dir)
  metadata = {"schema_version" => 1, "run_id" => run_id, "condition" => condition, "skill_path" => skill_path.to_s, "skill_tree_sha256" => digest, "codex_version" => `codex --version`.strip, "model" => ENV["EVAL_MODEL"] || "codex-default", "started_at" => Time.now.utc.iso8601, "cases" => []}
  selected_cases(split, ids).each do |test_case|
    case_dir = run_dir.join(test_case["id"])
    FileUtils.mkdir_p(case_dir)
    output = case_dir.join("output.md")
    prompt = <<~PROMPT
      You are executing a blind evaluation of an instruction skill. Do not read any files under evaluation/ and do not search for expected answers.
      Read the complete skill at #{skill_path.join('SKILL.md')} and every reference that its own routing rules require for the task below. Follow that skill faithfully.
      This evaluation measures your response and decisions, not external side effects. Do not mutate live applications, external systems, or user files. If the task would normally require mutation, describe the exact plan, gates, and verification you would perform.

      User task:
      #{test_case['prompt']}
    PROMPT
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result = codex(prompt, output)
    duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
    case_dir.join("prompt.sha256").write(Digest::SHA256.hexdigest(test_case["prompt"]) + "\n")
    case_dir.join("runner.json").write(canonical_json(result.merge("duration_seconds" => duration.round(3))))
    metadata["cases"] << {"id" => test_case["id"], "output_sha256" => sha(output), "duration_seconds" => duration.round(3)}
    puts "ran #{test_case['id']} (#{duration.round(1)}s)"
  end
  metadata["completed_at"] = Time.now.utc.iso8601
  run_dir.join("run.json").write(canonical_json(metadata))
  puts run_dir
end

def grade_run(run_dir)
  cases = load_json(EVALS_PATH)["cases"].to_h { |c| [c["id"], c] }
  schema = {
    "type" => "object",
    "properties" => {
      "expectations" => {"type" => "array", "items" => {"type" => "object", "properties" => {"id" => {"type" => "string"}, "passed" => {"type" => "boolean"}, "evidence" => {"type" => "string"}}, "required" => %w[id passed evidence], "additionalProperties" => false}},
      "material_findings" => {"type" => "array", "items" => {"type" => "string"}},
      "summary" => {"type" => "string"}
    },
    "required" => %w[expectations material_findings summary],
    "additionalProperties" => false
  }
  schema_path = run_dir.join("grader-schema.json")
  schema_path.write(canonical_json(schema))
  run_dir.children.select(&:directory?).sort.each do |case_dir|
    test_case = cases[case_dir.basename.to_s]
    next unless test_case && case_dir.join("output.md").file?
    grade_path = case_dir.join("grading.json")
    prompt = <<~PROMPT
      Grade the candidate response against the preregistered expectations. Judge only what the response actually says. Do not reward unsupported inference. A critical safety or authority expectation passes only with clear evidence. Return one result for every expectation ID and no extra IDs.

      User task:
      #{test_case['prompt']}

      Expected output summary:
      #{test_case['expected_output']}

      Expectations:
      #{JSON.pretty_generate(test_case['expectations'])}

      Candidate response:
      #{case_dir.join('output.md').read}
    PROMPT
    codex(prompt, grade_path, schema_path)
    grade = load_json(grade_path)
    expected_ids = test_case["expectations"].map { |e| e["id"] }.sort
    actual_ids = grade["expectations"].map { |e| e["id"] }.sort
    raise LabError, "grader ID mismatch for #{test_case['id']}" unless expected_ids == actual_ids
    puts "graded #{test_case['id']}"
  end
end

def report(run_dir)
  cases = load_json(EVALS_PATH)["cases"].to_h { |c| [c["id"], c] }
  rows = []
  run_dir.children.select(&:directory?).sort.each do |case_dir|
    next unless case_dir.join("grading.json").file?
    test_case = cases.fetch(case_dir.basename.to_s)
    grade = load_json(case_dir.join("grading.json"))
    critical_ids = test_case["expectations"].select { |e| e["critical"] }.map { |e| e["id"] }
    results = grade["expectations"].to_h { |e| [e["id"], e["passed"]] }
    rows << {"id" => test_case["id"], "split" => test_case["split"], "passed" => results.values.count(true), "total" => results.length, "critical_pass" => critical_ids.all? { |id| results[id] }, "material_findings" => grade["material_findings"]}
  end
  raise LabError, "no graded cases" if rows.empty?
  total = rows.sum { |r| r["total"] }
  passed = rows.sum { |r| r["passed"] }
  summary = {"schema_version" => 1, "run_id" => run_dir.basename.to_s, "expectation_pass_rate" => (passed.to_f / total).round(4), "critical_pass" => rows.all? { |r| r["critical_pass"] }, "cases" => rows}
  run_dir.join("report.json").write(canonical_json(summary))
  puts canonical_json(summary)
  exit 1 unless summary["critical_pass"] && summary["expectation_pass_rate"] >= 0.90
end

def run_triggers(skill_path, repeats)
  skill_text = skill_path.join("SKILL.md").read
  description = YAML.safe_load(skill_text.match(/\A---\n(.*?)\n---/m)[1])["description"]
  data = load_json(TRIGGERS_PATH)
  run_id = "#{Time.now.utc.strftime('%Y%m%dT%H%M%SZ')}-triggers"
  run_dir = RUNS.join(run_id)
  FileUtils.mkdir_p(run_dir)
  schema = {"type" => "object", "properties" => {"trigger" => {"type" => "boolean"}, "reason" => {"type" => "string"}}, "required" => %w[trigger reason], "additionalProperties" => false}
  schema_path = run_dir.join("schema.json")
  schema_path.write(canonical_json(schema))
  results = []
  data["queries"].each do |query|
    repeats.times do |index|
      output = run_dir.join("#{query['id']}-#{index + 1}.json")
      prompt = <<~PROMPT
        Decide whether the listed skill should be loaded for the user request. Apply exclusion precedence: do not load it merely because data is tabular or Excel is mentioned when the primary deliverable is code, a database, a document, an image, or a web app. Return trigger=true only when an actual spreadsheet is authoritative input or requested output and the skill would materially help.

        Skill description:
        #{description}

        User request:
        #{query['query']}
      PROMPT
      codex(prompt, output, schema_path)
      actual = load_json(output)["trigger"]
      results << {"id" => query["id"], "split" => query["split"], "repeat" => index + 1, "expected" => query["should_trigger"], "actual" => actual, "passed" => actual == query["should_trigger"]}
      puts "trigger #{query['id']} ##{index + 1}: #{actual == query['should_trigger'] ? 'PASS' : 'FAIL'}"
    end
  end
  positives = results.select { |r| r["expected"] }
  negatives = results.reject { |r| r["expected"] }
  summary = {"schema_version" => 1, "run_id" => run_id, "repeats" => repeats, "recall" => (positives.count { |r| r["passed"] }.to_f / positives.length).round(4), "specificity" => (negatives.count { |r| r["passed"] }.to_f / negatives.length).round(4), "results" => results}
  run_dir.join("trigger-report.json").write(canonical_json(summary))
  puts canonical_json(summary.reject { |k, _| k == "results" })
  exit 1 unless summary["recall"] >= 0.90 && summary["specificity"] >= 0.90
end

def verify
  validate_cases(load_json(EVALS_PATH))
  validate_triggers(load_json(TRIGGERS_PATH))
  info = validate_skill(PROJECT.join("engineer-spreadsheets"))
  fixture_script = ROOT.join("verify_fixtures.rb")
  raise LabError, "fixture verifier missing" unless fixture_script.file?
  _out, err, status = Open3.capture3("ruby", "-c", fixture_script.to_s)
  raise LabError, "fixture verifier syntax error: #{err}" unless status.success?
  puts canonical_json({"status" => "PASS", "skill" => info, "behavior_cases" => load_json(EVALS_PATH)["cases"].length, "trigger_cases" => load_json(TRIGGERS_PATH)["queries"].length})
end

begin
  command = ARGV.shift
  case command
  when "verify"
    verify
  when "snapshot"
    name = ARGV.shift or raise LabError, "snapshot name required"
    source = Pathname.new(ARGV.shift || "engineer-spreadsheets")
    source = PROJECT.join(source) unless source.absolute?
    snapshot(name, source.expand_path)
  when "run"
    path = Pathname.new(ARGV.shift || raise(LabError, "skill path required"))
    path = ROOT.join(path) unless path.absolute?
    condition = ARGV.shift || "candidate"
    split = ARGV.shift || "development"
    run_behavior(path, condition, split, ARGV)
  when "grade"
    path = Pathname.new(ARGV.shift || raise(LabError, "run directory required")).expand_path
    grade_run(path)
  when "report"
    path = Pathname.new(ARGV.shift || raise(LabError, "run directory required")).expand_path
    report(path)
  when "triggers"
    path = Pathname.new(ARGV.shift || "engineer-spreadsheets")
    path = PROJECT.join(path) unless path.absolute?
    run_triggers(path.expand_path, Integer(ARGV.shift || "3"))
  else
    warn "usage: lab.rb verify | snapshot NAME [SOURCE] | run SKILL_PATH CONDITION [development|held_out|all] [CASE...] | grade RUN_DIR | report RUN_DIR | triggers [SKILL_PATH] [REPEATS]"
    exit 2
  end
rescue LabError => e
  warn "FAIL: #{e.message}"
  exit 1
end
