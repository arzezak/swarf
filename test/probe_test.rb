# frozen_string_literal: true

require "test_helper"

class ProbeTest < Minitest::Test
  def setup
    @root = File.realpath(Dir.mktmpdir)
    File.write(script, <<~RUBY)
      def used(x)
        return 0 if x.negative?

        x
      end

      def unused = :never
      used(1)
    RUBY
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def test_running_code_under_the_probe_writes_a_coverage_file
    run_probed

    assert_path_exists File.join(@root, ".swarf", "coverage.json")
  end

  def test_it_records_which_lines_ran
    run_probed

    assert_equal [1, 1, nil, 1, nil, nil, 1, 1], coverage["lines"]
  end

  def test_it_records_which_branches_were_taken
    run_probed
    taken = coverage["branches"].values.flat_map(&:values)

    assert_equal [0, 1], taken.sort
  end

  def test_it_records_how_many_times_each_method_was_called
    run_probed

    assert_equal({"1" => 1, "7" => 0}, coverage["methods"])
  end

  def test_separate_runs_accumulate
    2.times { run_probed }

    assert_equal 2, coverage["methods"]["1"]
  end

  def test_it_loads_nothing_else_before_coverage_starts
    lib = File.expand_path("../lib", __dir__)
    output = IO.popen([{"SWARF_DIR" => File.join(@root, ".swarf")}, RbConfig.ruby, "-I#{lib}",
      "-rswarf/probe", "-e", "puts Swarf.const_defined?(:Store)"],
      chdir: @root, err: %i[child out], &:read)

    assert_equal "false", output.strip
  end

  def test_it_warns_instead_of_raising_when_coverage_is_already_running
    File.write(File.join(@root, "other_tool.rb"), "require 'coverage'\nCoverage.start\n")
    output = run_probed(prelude: ["-I#{@root}", "-rother_tool"])

    assert_match(/swarf.*already/i, output)
  end

  private

  def script = File.join(@root, "script.rb")

  def run_probed(prelude: [])
    lib = File.expand_path("../lib", __dir__)
    IO.popen([{"SWARF_DIR" => File.join(@root, ".swarf")}, RbConfig.ruby, "-I#{lib}",
      *prelude, "-rswarf/probe", script], chdir: @root, err: %i[child out], &:read)
  end

  def coverage
    JSON.parse(File.read(File.join(@root, ".swarf", "coverage.json"))).fetch(script)
  end
end
