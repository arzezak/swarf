# frozen_string_literal: true

require "test_helper"

class AcceptanceTest < Minitest::Test
  def test_the_row_limit_is_configurable
    output = swarf("--limit", "1", "test/fixtures/cart.rb")

    assert_match(/Cart#shipping/, output)
    refute_match(/Cart#subtotal/, output)
    assert_match(/1 more/, output)
  end

  def test_migrations_are_left_out_by_default_but_all_brings_them_back
    dir = File.realpath(Dir.mktmpdir)
    FileUtils.mkdir_p(File.join(dir, "db", "migrate"))
    FileUtils.mkdir_p(File.join(dir, "app"))
    File.write(File.join(dir, "app", "cart.rb"), "class Cart\n  def total = 1\nend\n")
    File.write(File.join(dir, "db", "migrate", "20260101_create_carts.rb"),
      "class CreateCarts\n  def change = 1\nend\n")

    refute_match(/CreateCarts/, swarf(chdir: dir))
    assert_match(/CreateCarts/, swarf("--all", chdir: dir))
  end

  def test_ignore_takes_extra_patterns
    output = swarf("--ignore", "**/fixtures/**", "test/")

    refute_match(/Cart#shipping/, output)
  end

  def test_it_scores_against_coverage_a_real_run_recorded
    dir = File.realpath(Dir.mktmpdir)
    File.write(File.join(dir, "cart.rb"), <<~RUBY)
      class Cart
        def shipping(total)
          return 0 if total > 100

          total
        end

        def refund(total) = -total
      end
      Cart.new.shipping(10)
    RUBY
    probe(dir, "cart.rb")
    output = swarf("cart.rb", chdir: dir, swarf_dir: File.join(dir, ".swarf"))

    assert_match(/Cart#refund\s+1\s+0\.0%\s+2\.00\s+never called/, output)
    assert_match(%r{Cart#shipping\s+2\s+50\.0%\s+2\.50\s+1/2 br}, output)
  end

  private

  def probe(dir, script)
    root = File.expand_path("..", __dir__)
    IO.popen([{"SWARF_DIR" => File.join(dir, ".swarf")}, RbConfig.ruby, "-I#{root}/lib",
      "-rswarf/probe", script], chdir: dir, err: %i[child out], &:read)
  end

  def swarf(*args, chdir: nil, swarf_dir: Dir.mktmpdir)
    root = File.expand_path("..", __dir__)
    IO.popen([{"SWARF_DIR" => swarf_dir}, RbConfig.ruby, "-I#{root}/lib",
      "#{root}/exe/swarf", *args], chdir: chdir || root, err: %i[child out], &:read)
  end
end
