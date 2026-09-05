# frozen_string_literal: true

require "test_helper"

class CoverageMapTest < Minitest::Test
  def setup
    @root = File.realpath(Dir.mktmpdir)
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def test_a_file_no_run_has_touched_has_no_coverage_at_all
    write("def total = 1\n")
    found = Swarf::CoverageMap.new({}).for(methods.first)

    assert_nil found.coverage
    assert_equal "no data", found.evidence
  end

  def test_a_file_edited_since_it_was_measured_reports_no_coverage_and_says_why
    write("def total = 1\n")
    taken = measurement(lines: [1], methods: {"1" => 1})
    write("# edited\ndef total = 1\n")
    found = Swarf::CoverageMap.new({source => taken}).for(methods.first)

    assert_nil found.coverage
    assert_equal "stale", found.evidence
  end

  def test_a_method_nothing_called_scores_zero_however_its_lines_look
    write("def total = 1\n")
    found = result(lines: [1], methods: {"1" => 0})

    assert_in_delta 0.0, found.coverage
    assert_equal "never called", found.evidence
  end

  def test_a_method_without_branches_falls_back_to_its_line_coverage
    write("def total\n  a = 1\n  b = 2\n  a + b\nend\n")
    found = result(lines: [1, 1, 0, 0, nil], methods: {"1" => 1})

    assert_in_delta(1.0 / 3, found.coverage)
    assert_equal "1/3 ln", found.evidence
  end

  def test_a_guard_clause_taken_only_one_way_reports_half_by_branch_not_all_by_line
    write("def total(x)\n  return 0 if x.negative?\n\n  x\nend\n")
    found = result(lines: [1, 1, nil, 1, nil],
      branches: {"if:0:2:2:2:25" => {"then:1:2:12:2:13" => 0, "else:2:2:2:2:25" => 1}},
      methods: {"1" => 1})

    assert_in_delta 0.5, found.coverage
    assert_equal "1/2 br", found.evidence
  end

  def test_a_branch_on_an_endless_def_still_belongs_to_that_method
    write("def pick(x) = x ? 1 : 2\n")
    found = result(lines: [1],
      branches: {"if:0:1:14:1:23" => {"then:1:1:18:1:19" => 2, "else:2:1:22:1:23" => 1}},
      methods: {"1" => 3})

    assert_in_delta 1.0, found.coverage
    assert_equal "2/2 br", found.evidence
  end

  def test_a_method_with_no_recorded_call_count_is_scored_rather_than_called_never_called
    write("def total\n  1\nend\n")
    found = result(lines: [1, 1, nil])

    assert_in_delta 1.0, found.coverage
    assert_equal "1/1 ln", found.evidence
  end

  def test_a_body_with_no_recorded_lines_has_nothing_to_go_on
    write("def total\n  1\nend\n")
    found = result(methods: {"1" => 1})

    assert_in_delta 1.0, found.coverage
    assert_equal "no body", found.evidence
  end

  def test_an_empty_method_that_ran_has_nothing_left_to_cover
    write("def noop\nend\n")
    found = result(lines: [1, nil], methods: {"1" => 1})

    assert_in_delta 1.0, found.coverage
    assert_equal "no body", found.evidence
  end

  private

  def source = File.join(@root, "cart.rb")

  def write(body) = File.write(source, body)

  def methods = Swarf::Complexity.analyze(File.read(source), path: source)

  def measurement(**recorded) = measurement_of(source, **recorded)

  def result(**recorded)
    Swarf::CoverageMap.new({source => measurement(**recorded)}).for(methods.first)
  end
end
