# frozen_string_literal: true

ROOT = File.expand_path("..", __dir__)
LIB = File.join(ROOT, "lib")

$LOAD_PATH.unshift LIB
require "swarf"

require "minitest/autorun"
require "tmpdir"
require "fileutils"

require_relative "support/swarf_helpers"
Minitest::Test.include SwarfHelpers
