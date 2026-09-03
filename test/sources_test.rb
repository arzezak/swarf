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

  def test_an_explicit_test_file_is_still_honoured
    write("test/cart_test.rb")

    assert_equal [path("test/cart_test.rb")], collect(path("test/cart_test.rb"))
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

  def collect(*paths) = Swarf::Sources.collect(paths)
end
