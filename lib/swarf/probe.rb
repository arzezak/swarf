# frozen_string_literal: true

require "coverage"

module Swarf
  module Probe
    def self.start
      ::Coverage.start(lines: true, branches: true, methods: true)
      spare_bootsnap
      at_exit { record(::Coverage.result) }
    rescue RuntimeError => e
      warn "swarf: coverage is already being measured (#{e.message}); not recording. " \
           "Remove SimpleCov, or drop the swarf/probe require."
    end

    def self.spare_bootsnap
      return unless defined?(::RubyVM::InstructionSequence)

      ::RubyVM::InstructionSequence.compile("").to_binary
    rescue RuntimeError
      ENV["DISABLE_BOOTSNAP_COMPILE_CACHE"] ||= "1"
    end

    def self.record(result)
      require_relative "store"
      Store.new.record(result)
    end
  end
end

Swarf::Probe.start
