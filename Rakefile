# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"

Minitest::TestTask.create do |t|
  # Record swarf's coverage with swarf. The prelude runs before the tests load, which is
  # the only place `Coverage.start` can still see them.
  t.test_prelude = 'require "swarf/probe"'
end

task default: :test
