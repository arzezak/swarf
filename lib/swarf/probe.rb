# frozen_string_literal: true

require "coverage"

module Swarf
  module Probe
    def self.start
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
