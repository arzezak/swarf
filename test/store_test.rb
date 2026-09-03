# frozen_string_literal: true

require "test_helper"

class StoreTest < Minitest::Test
  def setup
    @root = Dir.mktmpdir
    @store = Swarf::Store.new(File.join(@root, ".swarf"), root: @root)
    write_source("def shipping(t)\n  return 0 if t > 100\n\n  t\nend\n")
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def test_it_records_line_hits_for_a_project_file
    @store.record(raw(lines: [1, 1, nil, 0, nil]))

    assert_equal [1, 1, nil, 0, nil], entry["lines"]
  end

  # `ruby cart.rb` makes Coverage report "cart.rb", not its full path.
  def test_a_relative_path_is_resolved_against_the_project_root
    Dir.chdir(@root) { @store.record({ "lib/cart.rb" => { lines: [1] } }) }

    assert_equal [1], entry["lines"]
  end

  # A test run measures every gem and stdlib file it loads; none of that is your code.
  def test_it_ignores_files_outside_the_project
    @store.record({ "/usr/lib/ruby/pp.rb" => { lines: [1] } })

    assert_empty @store.read
  end

  def test_branch_keys_become_stable_strings
    @store.record(raw(branches: { [:if, 0, 2, 2, 2, 21] => { [:then, 1, 2, 2, 2, 12] => 0 } }))

    assert_equal({ "if:0:2:2:2:21" => { "then:1:2:2:2:12" => 0 } }, entry["branches"])
  end

  # The class object in a Coverage method key does not survive JSON, and the runner joins
  # on the line a method starts at anyway.
  def test_method_keys_become_their_starting_line
    @store.record(raw(methods: { [Object, :shipping, 1, 0, 5, 3] => 2 }))

    assert_equal({ "1" => 2 }, entry["methods"])
  end

  def test_two_runs_of_an_unchanged_file_add_up
    @store.record(raw(lines: [1, 0, nil], methods: { [Object, :shipping, 1, 0, 5, 3] => 1 }))
    @store.record(raw(lines: [1, 1, nil], methods: { [Object, :shipping, 1, 0, 5, 3] => 3 }))

    assert_equal [2, 1, nil], entry["lines"]
    assert_equal({ "1" => 4 }, entry["methods"])
  end

  def test_branch_outcomes_add_up_across_runs
    key = { [:if, 0, 2, 2, 2, 21] => { [:then, 1, 2, 2, 2, 12] => 1 } }
    2.times { @store.record(raw(branches: key)) }

    assert_equal 2, entry["branches"]["if:0:2:2:2:21"]["then:1:2:2:2:12"]
  end

  # Coverage is indexed by line number. Insert a method at the top of a file and every line
  # below it shifts while the counters stay put, so blending old with new is worse than
  # dropping the old outright: it reads as confidently correct and is wrong.
  def test_an_edited_file_replaces_its_old_coverage_instead_of_blending
    @store.record(raw(lines: [1, 1, nil, 1, nil]))
    write_source("# a new first line\ndef shipping(t)\n  t\nend\n")
    @store.record(raw(lines: [0, 0, nil, nil]))

    assert_equal [0, 0, nil, nil], entry["lines"]
  end

  # Rails parallelises tests by forking, so a dozen processes can finish at once and each
  # merges into the same file. Without locking they overwrite each other's records.
  def test_concurrent_writers_do_not_lose_each_others_records
    files = Array.new(8) { |i| File.join(@root, "lib", "f#{i}.rb").tap { |f| File.write(f, "def m; end\n") } }
    start = Time.now + 0.3
    pids = files.map do |file|
      fork do
        sleep([start - Time.now, 0].max)
        @store.record({ file => { lines: [1] } })
        exit!(0)
      end
    end
    pids.each { |pid| Process.wait(pid) }

    assert_equal files.sort, @store.read.keys.reject { |k| k.end_with?("cart.rb") }.sort
  end

  def test_it_survives_a_round_trip_through_disk
    @store.record(raw(lines: [1, nil]))

    assert_equal({ "lines" => [1, nil] }, Swarf::Store.new(File.join(@root, ".swarf"), root: @root)
                                                     .read[source].slice("lines"))
  end

  def test_reading_before_any_run_is_empty_rather_than_an_error
    assert_empty @store.read
  end

  private

  def source = File.join(@root, "lib", "cart.rb")

  def write_source(body)
    FileUtils.mkdir_p(File.dirname(source))
    File.write(source, body)
  end

  def raw(lines: [], branches: {}, methods: {})
    { source => { lines: lines, branches: branches, methods: methods } }
  end

  def entry = @store.read.fetch(source)
end
