# frozen_string_literal: true

require "test_helper"

class AcceptanceTest < Minitest::Test
  def test_scoring_a_file_with_no_coverage_reports_the_complexity_floor
    output = swarf("test/fixtures/cart.rb")

    assert_match(/Cart#shipping\s+3\s+—\s+12\.00/, output)
    assert_match(/Cart#subtotal\s+1\s+—\s+2\.00/, output)
  end

  def test_worst_method_is_listed_first
    output = swarf("test/fixtures/cart.rb")

    assert_operator output.index("Cart#shipping"), :<, output.index("Cart#subtotal")
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

    # The guard was only ever taken one way, and nothing called `refund` at all.
    assert_match(/Cart#refund\s+1\s+0\.0%\s+2\.00\s+never called/, output)
    assert_match(%r{Cart#shipping\s+2\s+50\.0%\s+2\.50\s+1/2 br}, output)
  end

  private

  def probe(dir, script)
    root = File.expand_path("..", __dir__)
    IO.popen([{ "SWARF_DIR" => File.join(dir, ".swarf") }, RbConfig.ruby, "-I#{root}/lib",
              "-rswarf/probe", script], chdir: dir, err: %i[child out], &:read)
  end

  def swarf(*args, chdir: nil, swarf_dir: Dir.mktmpdir)
    root = File.expand_path("..", __dir__)
    IO.popen([{ "SWARF_DIR" => swarf_dir }, RbConfig.ruby, "-I#{root}/lib",
              "#{root}/exe/swarf", *args], chdir: chdir || root, err: %i[child out], &:read)
  end
end
