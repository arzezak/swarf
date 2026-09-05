# frozen_string_literal: true

module Swarf
  class CoverageMap
    Result = Struct.new(:coverage, :evidence)

    NO_DATA = Result.new(coverage: nil, evidence: "no data")
    STALE = Result.new(coverage: nil, evidence: "stale")
    NEVER_CALLED = Result.new(coverage: 0.0, evidence: "never called")
    NO_BODY = Result.new(coverage: 1.0, evidence: "no body")

    def initialize(data)
      @data = data
    end

    def for(method)
      measurement = @data[method.path]
      return NO_DATA if measurement.nil?
      return STALE unless measurement.current?
      return NEVER_CALLED if measurement.calls(method.start_line)&.zero?

      branch_coverage(measurement, method) || line_coverage(measurement, method) || NO_BODY
    end

    private

    def branch_coverage(measurement, method)
      outcomes = measurement.branches(method.range)
      return nil if outcomes.empty?

      ratio(outcomes.count(&:positive?), outcomes.size, "br")
    end

    def line_coverage(measurement, method)
      return nil unless method.body

      hits = measurement.lines(method.body)
      return nil if hits.empty?

      ratio(hits.count(&:positive?), hits.size, "ln")
    end

    def ratio(covered, total, unit)
      Result.new(coverage: covered.fdiv(total), evidence: "#{covered}/#{total} #{unit}")
    end
  end
end
