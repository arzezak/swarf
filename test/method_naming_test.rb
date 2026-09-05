# frozen_string_literal: true

require "test_helper"

class MethodNamingTest < Minitest::Test
  def test_an_instance_method_is_named_with_a_hash
    assert_equal ["Cart#total"], names("class Cart\n  def total = 1\nend\n")
  end

  def test_a_singleton_method_is_named_with_a_dot
    assert_equal ["Cart.build"], names("class Cart\n  def self.build = 1\nend\n")
  end

  def test_methods_inside_class_self_are_singleton_methods
    assert_equal ["Cart.build"], names("class Cart\n  class << self\n    def build = 1\n  end\nend\n")
  end

  def test_leaving_a_singleton_block_restores_instance_naming
    assert_equal ["Cart.build", "Cart#total"],
      names("class Cart\n  class << self\n    def build = 1\n  end\n  def total = 1\nend\n")
  end

  def test_nesting_is_joined_with_colons
    assert_equal ["Shop::Cart#total"], names("module Shop\n  class Cart\n    def total = 1\n  end\nend\n")
  end

  def test_a_compact_definition_keeps_its_written_path
    assert_equal ["Shop::Cart#total"], names("class Shop::Cart\n  def total = 1\nend\n")
  end

  def test_a_method_outside_any_namespace_is_named_bare
    assert_equal ["total"], names("def total = 1\n")
  end

  private

  def names(source)
    Swarf::Complexity.analyze(source, path: "(test)").map(&:name)
  end
end
