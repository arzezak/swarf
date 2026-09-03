# frozen_string_literal: true

require "test_helper"

class CoverageMapTest < Minitest::Test
  def setup
    @root = File.realpath(Dir.mktmpdir)
    @store = Swarf::Store.new(File.join(@root, ".swarf"), root: @root)
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def test_a_file_no_run_has_touched_has_no_coverage_at_all
    write("def total = 1\n")

    assert_nil result.coverage
    assert_equal "no data", result.evidence
  end

  # Coverage is indexed by line number, so numbers recorded against different bytes are
  # not merely old, they are misattributed. Report the CC floor rather than a wrong figure.
  def test_a_file_edited_since_it_was_measured_reports_no_coverage_and_says_why
    write("def total = 1\n")
    record(lines: [1], methods: { [Object, :total, 1, 0, 1, 13] => 1 })
    write("# edited\ndef total = 1\n")

    assert_nil result.coverage
    assert_equal "stale", result.evidence
  end

  # A `def` line runs when the file loads, so line coverage alone calls this method tested.
  def test_a_method_nothing_called_scores_zero_however_its_lines_look
    write("def total = 1\n")
    record(lines: [1], methods: { [Object, :total, 1, 0, 1, 13] => 0 })

    assert_in_delta 0.0, result.coverage
    assert_equal "never called", result.evidence
  end

  def test_a_method_without_branches_falls_back_to_its_line_coverage
    write("def total\n  a = 1\n  b = 2\n  a + b\nend\n")
    record(lines: [1, 1, 0, 0, nil], methods: { [Object, :total, 1, 0, 5, 3] => 1 })

    assert_in_delta(1.0 / 3, result.coverage)
    assert_equal "1/3 ln", result.evidence
  end

  # The reason branches are preferred: this method reads 100% by line and 50% by branch,
  # and the untested half is exactly where the complexity is.
  def test_a_guard_clause_taken_only_one_way_reports_half_by_branch_not_all_by_line
    write("def total(x)\n  return 0 if x.negative?\n\n  x\nend\n")
    record(lines: [1, 1, nil, 1, nil],
           branches: { [:if, 0, 2, 2, 2, 25] => { [:then, 1, 2, 12, 2, 13] => 0,
                                                  [:else, 2, 2, 2, 2, 25] => 1 } },
           methods: { [Object, :total, 1, 0, 5, 3] => 1 })

    assert_in_delta 0.5, result.coverage
    assert_equal "1/2 br", result.evidence
  end

  def test_a_branch_on_an_endless_def_still_belongs_to_that_method
    write("def pick(x) = x ? 1 : 2\n")
    record(lines: [1],
           branches: { [:if, 0, 1, 14, 1, 23] => { [:then, 1, 1, 18, 1, 19] => 2,
                                                   [:else, 2, 1, 22, 1, 23] => 1 } },
           methods: { [Object, :pick, 1, 0, 1, 23] => 3 })

    assert_in_delta 1.0, result.coverage
    assert_equal "2/2 br", result.evidence
  end

  def test_an_empty_method_that_ran_has_nothing_left_to_cover
    write("def noop\nend\n")
    record(lines: [1, nil], methods: { [Object, :noop, 1, 0, 2, 3] => 1 })

    assert_in_delta 1.0, result.coverage
    assert_equal "no body", result.evidence
  end

  private

  def source = File.join(@root, "cart.rb")

  def write(body) = File.write(source, body)

  def record(lines: [], branches: {}, methods: {})
    @store.record({ source => { lines: lines, branches: branches, methods: methods } })
  end

  def result(name: nil)
    methods = Swarf::Complexity.analyze(File.read(source), path: source)
    method = name ? methods.find { |m| m.name == name } : methods.first
    Swarf::CoverageMap.new(@store.read).for(method)
  end
end
