# frozen_string_literal: true

require_relative "swarf/version"
require_relative "swarf/complexity"
require_relative "swarf/measurement"
require_relative "swarf/store"
require_relative "swarf/coverage_map"
require_relative "swarf/score"
require_relative "swarf/report"
require_relative "swarf/sources"
require_relative "swarf/scan"
require_relative "swarf/cli"

module Swarf
  class Error < StandardError; end

  # CRAP(m) = CC(m)^2 * (1 - coverage(m))^3 + CC(m)
  def self.crap(complexity, coverage)
    (complexity**2) * ((1.0 - coverage)**3) + complexity
  end
end
