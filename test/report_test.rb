# frozen_string_literal: true

require "test_helper"

class ReportTest < Minitest::Test
  def test_it_lists_the_worst_method_first
    output = render([row("Cart#subtotal", cc: 1), row("Cart#shipping", cc: 3)])

    assert_operator output.index("Cart#shipping"), :<, output.index("Cart#subtotal")
  end

  def test_it_prints_the_crap_score_to_two_decimals
    assert_match(/Cart#shipping\s+3\s+—\s+12\.00/, render([row("Cart#shipping", cc: 3)]))
  end

  def test_a_scored_method_shows_its_coverage_as_a_percentage
    assert_match(/Cart#shipping\s+4\s+50\.0%\s+6\.00/,
      render([row("Cart#shipping", cc: 4, coverage: 0.5, evidence: "1/2 br")]))
  end

  def test_coverage_is_an_em_dash_when_there_is_no_data
    assert_match(/Cart#shipping\s+3\s+—/, render([row("Cart#shipping", cc: 3)]))
  end

  def test_it_shows_the_evidence_behind_each_score
    assert_match(/never called/, render([row("Cart#x", cc: 1, coverage: 0.0, evidence: "never called")]))
  end

  def test_each_row_names_the_file_and_line_the_method_starts_on
    assert_match(%r{app/cart\.rb:42}, render([row("Cart#shipping", cc: 3, location: "app/cart.rb:42")]))
  end

  def test_it_shows_only_the_worst_rows_by_default
    scores = Array.new(30) { |i| row("Cart#m#{i}", cc: i + 1) }

    assert_equal 20, render(scores).lines.count { |line| line.start_with?("Cart#") }
  end

  def test_it_says_how_many_rows_it_held_back
    assert_match(/10 more/, render(Array.new(30) { |i| row("Cart#m#{i}", cc: i + 1) }))
  end

  def test_a_limit_of_zero_shows_everything
    scores = Array.new(30) { |i| row("Cart#m#{i}", cc: i + 1) }

    assert_equal 30, render(scores, limit: 0).lines.count { |line| line.start_with?("Cart#") }
  end

  def test_nothing_is_held_back_when_everything_fits
    refute_match(/more/, render([row("Cart#shipping", cc: 3)]))
  end

  def test_an_empty_run_says_so_instead_of_printing_a_bare_header
    assert_match(/no methods found/i, render([]))
  end

  private

  def row(name, cc:, coverage: nil, evidence: "no data", location: "app/cart.rb:1")
    Swarf::Score.new(name: name, cc: cc, coverage: coverage, evidence: evidence,
      location: location)
  end

  def render(scores, limit: Swarf::Report::DEFAULT_LIMIT)
    Swarf::Report.new(scores, limit: limit).to_s
  end
end
