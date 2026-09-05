# frozen_string_literal: true

require "test_helper"

class ScoreTest < Minitest::Test
  def test_fully_covered_code_is_only_as_risky_as_it_is_complex
    assert_in_delta 9.0, Swarf.crap(9, 1.0)
  end

  def test_untested_complexity_grows_quadratically
    assert_in_delta 90.0, Swarf.crap(9, 0.0)
  end

  def test_partial_coverage_falls_between_the_two
    assert_in_delta 19.125, Swarf.crap(9, 0.5)
  end

  def test_the_simplest_possible_method_scores_one
    assert_in_delta 1.0, Swarf.crap(1, 1.0)
  end

  def test_complexity_is_a_floor_no_coverage_can_go_under
    (1..30).each do |cc|
      assert_operator Swarf.crap(cc, 1.0), :>=, cc
    end
  end
end
