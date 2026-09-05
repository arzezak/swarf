# frozen_string_literal: true

require "digest"

module Swarf
  class CoverageMap
    Result = Struct.new(:coverage, :evidence, keyword_init: true)

    NO_DATA = Result.new(coverage: nil, evidence: "no data")
    STALE = Result.new(coverage: nil, evidence: "stale")
    NEVER_CALLED = Result.new(coverage: 0.0, evidence: "never called")
    NO_BODY = Result.new(coverage: 1.0, evidence: "no body")

    def initialize(data)
      @data = data
    end

    def for(method)
      entry = @data[method.path]
      return NO_DATA if entry.nil?
      return STALE unless current?(method.path, entry)
      return NEVER_CALLED if never_called?(method, entry)

      branch_coverage(method, entry) || line_coverage(method, entry) || NO_BODY
    end

    private

    def current?(path, entry)
      File.file?(path) && Digest::SHA256.file(path).hexdigest == entry["sha"]
    end

    def never_called?(method, entry)
      entry["methods"][method.start_line.to_s]&.zero?
    end

    def branch_coverage(method, entry)
      outcomes = entry["branches"].filter_map do |branch, taken|
        taken.values if method.range.cover?(branch.split(":")[2].to_i)
      end.flatten
      return nil if outcomes.empty?

      ratio(outcomes.count(&:positive?), outcomes.size, "br")
    end

    def line_coverage(method, entry)
      return nil unless method.body

      hits = method.body.filter_map { |line| entry["lines"][line - 1] }
      return nil if hits.empty?

      ratio(hits.count(&:positive?), hits.size, "ln")
    end

    def ratio(covered, total, unit)
      Result.new(coverage: covered.fdiv(total), evidence: "#{covered}/#{total} #{unit}")
    end
  end
end
