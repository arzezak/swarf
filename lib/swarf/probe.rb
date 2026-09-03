# frozen_string_literal: true

require "coverage"

# Load this into your own test runs, ahead of everything else:
#
#   # .rspec
#   --require swarf/probe
#
# It only records. Scoring happens later, in a separate process, when you run `swarf`.
module Swarf
  module Probe
    def self.start
      # Coverage measures only what is loaded after it starts, and Ruby permits one start
      # per process. So this runs before the application does — and before the rest of
      # swarf, which is why the store is required down in `at_exit` rather than up here.
      ::Coverage.start(lines: true, branches: true, methods: true)
      at_exit { record(::Coverage.result) }
    rescue RuntimeError => e
      warn "swarf: coverage is already being measured (#{e.message}); not recording. " \
           "Remove SimpleCov, or drop the swarf/probe require."
    end

    def self.record(result)
      require_relative "store"
      Store.new.record(result)
    end
  end
end

Swarf::Probe.start
