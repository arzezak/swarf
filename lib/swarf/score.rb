# frozen_string_literal: true

module Swarf
  # One scored method: what it costs to change, and what evidence backs the number.
  Score = Struct.new(:name, :cc, :coverage, :evidence, :location, keyword_init: true) do
    # With no coverage the score is CC^2 + CC — not a placeholder but the correct reading
    # for code nothing has run. Coverage can only ever pull it down, toward CC.
    def crap = Swarf.crap(cc, coverage || 0.0)
  end
end
