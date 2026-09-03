# frozen_string_literal: true

module Swarf
  # A fixed-width table, worst first.
  class Report
    HEADINGS = ["Method", "CC", "Cov%", "CRAP", "Evidence"].freeze

    def initialize(scores)
      @scores = scores.sort_by { |score| -score.crap }
    end

    def to_s
      return "No methods found.\n" if @scores.empty?

      widths = column_widths
      [heading(widths), divider(widths), *@scores.map { |score| line(cells(score), widths) }]
        .join("\n") + "\n"
    end

    private

    def rows = @scores.map { |score| cells(score) }

    def cells(score)
      [score.name, score.cc.to_s, percentage(score.coverage), format("%.2f", score.crap),
       score.evidence.to_s]
    end

    def percentage(coverage) = coverage.nil? ? "—" : format("%.1f%%", coverage * 100)

    def column_widths
      ([HEADINGS] + rows).transpose.map { |column| column.map(&:length).max }
    end

    def heading(widths) = line(HEADINGS, widths)

    def divider(widths) = widths.sum { |width| width + 2 }.then { |total| "-" * (total - 2) }

    # Only the method name is left-aligned; numbers read better flush right.
    def line(cells, widths)
      cells.each_with_index.map do |cell, index|
        index.zero? ? cell.ljust(widths[index]) : cell.rjust(widths[index])
      end.join("  ").rstrip
    end
  end
end
