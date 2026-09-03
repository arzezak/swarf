# frozen_string_literal: true

require "test_helper"

class ComplexityTest < Minitest::Test
  def test_a_method_with_no_decisions_has_complexity_one
    assert_equal 1, cc(<<~RUBY)
      def plain
        1 + 1
      end
    RUBY
  end

  def test_an_if_adds_one
    assert_equal 2, cc(<<~RUBY)
      def guard(x)
        return 0 if x.negative?

        x
      end
    RUBY
  end

  def test_each_elsif_adds_one
    assert_equal 3, cc(<<~RUBY)
      def size(n)
        if n > 10 then :big
        elsif n > 5 then :medium
        else :small
        end
      end
    RUBY
  end

  def test_a_ternary_adds_one
    assert_equal 2, cc("def pick(x) = x ? 1 : 2\n")
  end

  def test_an_unless_adds_one
    assert_equal 2, cc(<<~RUBY)
      def check(x)
        unless x
          raise
        end
      end
    RUBY
  end

  def test_each_when_adds_one
    assert_equal 3, cc(<<~RUBY)
      def label(x)
        case x
        when 1 then :one
        when 2 then :two
        end
      end
    RUBY
  end

  def test_each_in_pattern_adds_one
    assert_equal 3, cc(<<~RUBY)
      def match(x)
        case x
        in [1] then :one
        in [2] then :two
        end
      end
    RUBY
  end

  def test_each_rescue_adds_one
    assert_equal 3, cc(<<~RUBY)
      def risky
        work
      rescue TypeError
        1
      rescue ArgumentError
        2
      end
    RUBY
  end

  def test_a_rescue_modifier_adds_one
    assert_equal 2, cc("def risky = work rescue nil\n")
  end

  def test_loops_add_one
    assert_equal 4, cc(<<~RUBY)
      def spin(n)
        while n > 0 do n -= 1 end
        until n > 5 do n += 1 end
        for i in 1..3 do n += i end
        n
      end
    RUBY
  end

  def test_boolean_operators_add_one_each
    assert_equal 3, cc("def both?(a, b) = a.positive? && b.positive? || false\n")
  end

  def test_safe_navigation_adds_one
    assert_equal 2, cc("def name(user) = user&.name\n")
  end

  def test_blocks_do_not_add_complexity
    assert_equal 1, cc(<<~RUBY)
      def totals(rows)
        rows.map { |r| r.total }.select { |t| t }
      end
    RUBY
  end

  def test_a_nested_def_gets_its_own_complexity
    methods = analyze(<<~RUBY)
      def outer
        def inner(x)
          return 0 if x.negative?

          x
        end
      end
    RUBY

    assert_equal 1, methods.find { |m| m.name == "outer" }.cc
    assert_equal 2, methods.find { |m| m.name == "inner" }.cc
  end

  def test_decisions_outside_a_method_belong_to_no_method
    assert_empty analyze("puts 1 if ENV['DEBUG']\n")
  end

  private

  def analyze(source)
    Swarf::Complexity.analyze(source, path: "(test)")
  end

  def cc(source)
    analyze(source).first.cc
  end
end
