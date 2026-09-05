# frozen_string_literal: true

module Swarf
  Score = Struct.new(:name, :cc, :coverage, :evidence, :location) do
    def crap = Swarf.crap(cc, coverage || 0.0)
  end
end
