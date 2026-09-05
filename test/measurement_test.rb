# frozen_string_literal: true

require "test_helper"

class MeasurementTest < Minitest::Test
  def setup
    @root = File.realpath(Dir.mktmpdir)
    @path = File.join(@root, "cart.rb")
    File.write(@path, "def total\n  1\nend\n")
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def test_a_file_whose_bytes_still_match_is_current
    assert_predicate measurement, :current?
  end

  def test_a_file_edited_after_it_was_measured_is_not_current
    taken = measurement
    File.write(@path, "# a new first line\ndef total\n  1\nend\n")

    refute_predicate taken, :current?
  end

  def test_a_file_that_no_longer_exists_is_not_current
    taken = measurement
    FileUtils.rm(@path)

    refute_predicate taken, :current?
  end

  def test_freshness_is_settled_on_the_first_ask_and_not_asked_again
    taken = measurement

    assert_predicate taken, :current?
    File.write(@path, "# edited after the question was answered\n")

    assert_predicate taken, :current?
  end

  def test_it_reports_how_many_times_the_method_on_a_line_was_called
    assert_equal 3, measurement(methods: {"1" => 3}).calls(1)
  end

  def test_a_line_with_no_method_recorded_has_no_call_count
    assert_nil measurement(methods: {"1" => 3}).calls(9)
  end

  def test_it_collects_the_branch_outcomes_inside_a_range
    taken = measurement(branches: {"if:0:2:2:2:21" => {"then:1:2:2:2:12" => 0, "else:2:2:2:2:21" => 4}})

    assert_equal [0, 4], taken.branches(1..3)
    assert_empty taken.branches(5..9)
  end

  def test_it_collects_the_line_hits_inside_a_range
    assert_equal [1, 0], measurement(lines: [1, 0, nil]).lines(1..3)
  end

  private

  def measurement(**recorded) = measurement_of(@path, **recorded)
end
