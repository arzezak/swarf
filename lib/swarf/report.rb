# frozen_string_literal: true

module Swarf
  class Report
    HEADINGS = ["Method", "CC", "Cov%", "CRAP", "Evidence", "Location"].freeze

    DEFAULT_LIMIT = 20

    def initialize(scores, limit: DEFAULT_LIMIT)
      @scores = scores.sort_by { |score| -score.crap }
      @limit = limit
      @shown = limit.zero? ? @scores : @scores.first(limit)
    end

    def to_s
      return "No methods found.\n" if @scores.empty?

      widths = column_widths
      lines = [heading(widths), divider(widths), *@shown.map { |score| line(cells(score), widths) }]
      lines << footer if held_back.positive?
      "#{lines.join("\n")}\n"
    end

    private

    def held_back = @scores.size - @shown.size

    def footer = "\n… #{held_back} more (--limit 0 for all)"

    def rows = @shown.map { |score| cells(score) }

    def cells(score)
      [score.name, score.cc.to_s, percentage(score.coverage), format("%.2f", score.crap),
       score.evidence.to_s, score.location.to_s]
    end

    def percentage(coverage) = coverage.nil? ? "—" : format("%.1f%%", coverage * 100)

    def column_widths
      ([HEADINGS] + rows).transpose.map { |column| column.map(&:length).max }
    end

    def heading(widths) = line(HEADINGS, widths)

    def divider(widths) = widths.sum { |width| width + 2 }.then { |total| "-" * (total - 2) }

    def line(cells, widths)
      cells.each_with_index.map do |cell, index|
        index.zero? || index == cells.size - 1 ? cell.ljust(widths[index]) : cell.rjust(widths[index])
      end.join("  ").rstrip
    end
  end
end
