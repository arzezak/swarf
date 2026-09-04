# frozen_string_literal: true

require "test_helper"

class SourcesTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def test_a_file_argument_is_taken_as_given
    write("lib/cart.rb")

    assert_equal [path("lib/cart.rb")], collect(path("lib/cart.rb"))
  end

  def test_a_directory_is_searched_recursively_for_ruby_files
    write("lib/cart.rb")
    write("lib/shop/item.rb")
    write("lib/README.md")

    assert_equal [path("lib/cart.rb"), path("lib/shop/item.rb")], collect(path("lib"))
  end

  # Test files are where coverage comes from, not where risk lives.
  def test_test_and_vendor_directories_are_skipped
    write("lib/cart.rb")
    write("test/cart_test.rb")
    write("spec/cart_spec.rb")
    write("vendor/bundle/gem.rb")

    assert_equal [path("lib/cart.rb")], collect(@dir)
  end

  # Migrations are generated, run once, and never tested. On a well-tested app they are
  # the only untested code left, so they take over the top of the report.
  def test_migrations_and_schema_are_skipped
    write("app/cart.rb")
    write("db/migrate/20260101_create_carts.rb")
    write("db/schema.rb")

    assert_equal [path("app/cart.rb")], collect(@dir)
  end

  def test_a_vendor_directory_is_caught_at_any_depth
    write("lib/cart.rb")
    write("lib/deep/vendor/gem.rb")

    assert_equal [path("lib/cart.rb")], collect(@dir)
  end

  def test_an_explicit_test_file_is_still_honoured
    write("test/cart_test.rb")

    assert_equal [path("test/cart_test.rb")], collect(path("test/cart_test.rb"))
  end

  # Patterns match relative to the root being scanned, so naming a skipped directory makes
  # its contents top-level and nothing can match them.
  def test_an_explicit_directory_overrides_its_own_exclusion
    write("db/migrate/20260101_create_carts.rb")

    assert_equal [path("db/migrate/20260101_create_carts.rb")], collect(path("db/migrate"))
  end

  def test_extra_patterns_can_be_supplied
    write("lib/cart.rb")
    write("lib/generated/client.rb")

    assert_equal [path("lib/cart.rb")], collect(@dir, ignore: Swarf::Sources::DEFAULT_IGNORE + ["lib/generated/**"])
  end

  def test_an_empty_pattern_list_scores_everything
    write("lib/cart.rb")
    write("db/migrate/20260101_create_carts.rb")

    assert_equal 2, collect(@dir, ignore: []).size
  end

  def test_patterns_are_read_from_a_swarfignore_file
    write("lib/cart.rb")
    write("lib/legacy/old.rb")
    File.write(path(".swarfignore"), "lib/legacy/**\n")

    assert_equal ["lib/legacy/**"], Swarf::Sources.ignore_file(@dir)
  end

  def test_comments_and_blank_lines_in_swarfignore_are_ignored
    File.write(path(".swarfignore"), "# generated\n\nlib/legacy/**\n  \n")

    assert_equal ["lib/legacy/**"], Swarf::Sources.ignore_file(@dir)
  end

  def test_a_missing_swarfignore_is_simply_no_patterns
    assert_empty Swarf::Sources.ignore_file(@dir)
  end

  def test_a_missing_path_is_reported_clearly
    error = assert_raises(Swarf::Error) { collect(path("nope.rb")) }

    assert_match(/nope\.rb/, error.message)
  end

  private

  def write(relative)
    full = path(relative)
    FileUtils.mkdir_p(File.dirname(full))
    File.write(full, "def noop; end\n")
  end

  def path(relative) = File.join(@dir, relative)

  def collect(*paths, ignore: Swarf::Sources::DEFAULT_IGNORE)
    Swarf::Sources.collect(paths, ignore: ignore)
  end
end
