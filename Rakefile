# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"
require "standard/rake"

Minitest::TestTask.create do |task|
  # Record swarf's coverage with swarf. The prelude runs before the tests load,
  # which is the only place `Coverage.start` can still see them.
  task.test_prelude = 'require "swarf/probe"'
end

task default: %i[test standard]
