# frozen_string_literal: true

require "test_helper"

class BodyRangeTest < Minitest::Test
  def test_the_def_line_is_excluded_from_the_body
    assert_equal 3..4, body(<<~RUBY)
      # comment
      def shipping(total)
        return 0 if total > 100
        total
      end
    RUBY
  end

  def test_an_endless_method_is_its_own_body
    assert_equal 1..1, body("def total = 1\n")
  end

  def test_an_implicit_rescue_does_not_pull_the_body_back_onto_the_def_line
    assert_equal 2..4, body(<<~RUBY)
      def risky
        work
      rescue
        nil
      end
    RUBY
  end

  def test_a_body_sharing_a_line_with_its_keywords_keeps_that_line
    assert_equal 1..1, body("def total; 1; end\n")
    assert_equal 2..2, body("def total\n  1; end\n")
  end

  def test_an_empty_method_has_no_body
    assert_nil body("def noop\nend\n")
  end

  private

  def body(source)
    Swarf::Complexity.analyze(source, path: "(test)").first.body
  end
end
