# frozen_string_literal: true

require "test_helper"

class ScanTest < Minitest::Test
  def setup
    @root = File.realpath(Dir.mktmpdir)
    @store = Swarf::Store.new(File.join(@root, ".swarf"), root: @root)
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def test_a_method_no_run_has_touched_scores_the_complexity_floor
    write("sub/cart.rb", <<~RUBY)
      class Cart
        def shipping(total)
          return 0 if total > 100

          total
        end
      end
    RUBY
    score = scores.first

    assert_equal "Cart#shipping", score.name
    assert_equal 2, score.cc
    assert_nil score.coverage
    assert_in_delta 6.0, score.crap
    assert_equal "no data", score.evidence
  end

  def test_every_score_names_a_file_and_line_relative_to_the_root
    write("sub/cart.rb", "class Cart\n  def total = 1\nend\n")

    assert_equal "sub/cart.rb:2", scores.first.location
  end

  def test_ignored_paths_are_left_out
    write("lib/cart.rb", "def total = 1\n")
    write("lib/legacy/old.rb", "def total = 1\n")

    assert_equal ["lib/cart.rb:1"], scores(ignore: ["lib/legacy/**"]).map(&:location)
  end

  def test_a_named_path_is_resolved_against_the_root_not_the_working_directory
    write("lib/cart.rb", "def total = 1\n")
    write("lib/item.rb", "def price = 1\n")

    assert_equal ["lib/cart.rb:1"], scores(paths: ["lib/cart.rb"]).map(&:location)
  end

  def test_it_joins_parsed_complexity_to_recorded_coverage
    write("cart.rb", <<~RUBY)
      class Cart
        def shipping(total)
          return 0 if total > 100

          total
        end

        def refund(total) = -total
      end
    RUBY
    record("cart.rb",
      lines: [1, 1, 1, nil, 1, nil, nil, 1, nil],
      branches: {[:if, 0, 3, 4, 3, 27] => {[:then, 1, 3, 11, 3, 12] => 0, [:else, 2, 3, 4, 3, 27] => 1}},
      methods: {[Object, :shipping, 2, 2, 6, 5] => 1, [Object, :refund, 8, 2, 8, 27] => 0})
    by_name = scores.to_h { |score| [score.name, score] }

    assert_in_delta 0.5, by_name["Cart#shipping"].coverage
    assert_equal "1/2 br", by_name["Cart#shipping"].evidence
    assert_in_delta 0.0, by_name["Cart#refund"].coverage
    assert_equal "never called", by_name["Cart#refund"].evidence
  end

  private

  def write(relative, body)
    full = File.join(@root, relative)
    FileUtils.mkdir_p(File.dirname(full))
    File.write(full, body)
  end

  def record(relative, lines: [], branches: {}, methods: {})
    @store.record({File.join(@root, relative) => {lines: lines, branches: branches, methods: methods}})
  end

  def scores(paths: [], ignore: [])
    Swarf::Scan.new(paths: paths, ignore: ignore, store: @store, root: @root).scores
  end
end
