# frozen_string_literal: true

module Swarf
  class Report
    HEADINGS = ["Method", "CC", "Cov%", "CRAP", "Evidence", "Location"].freeze

    DEFAULT_LIMIT = 20

    def initialize(scores, limit: DEFAULT_LIMIT)
      @scores = scores.sort_by { |score| -score.crap }
      @shown = limit.zero? ? @scores : @scores.first(limit)
    end

    def to_s
      return "No methods found.\n" if @scores.empty?

      rows = @shown.map { |score| cells(score) }
      widths = column_widths(rows)
      lines = [heading(widths), divider(widths), *rows.map { |row| line(row, widths) }]
      "#{(lines + footer).join("\n")}\n"
    end

    private

    def held_back = @scores.size - @shown.size

    def footer
      notes = []
      notes << "… #{held_back} more (--limit 0 for all)" if held_back.positive?
      notes << unmeasured_note if unmeasured.positive?
      notes << stale_note if stale.positive?
      notes.empty? ? notes : [""] + notes
    end

    def unmeasured_note
      "No coverage recorded for #{scope(unmeasured)} — run your suite with swarf/probe loaded."
    end

    def stale_note = "#{scope(stale).capitalize} changed after measurement — re-run your suite."

    def scope(count) = (count == files.size) ? "every file" : "#{count} of #{files.size} files"

    def unmeasured = @unmeasured ||= files_reporting(CoverageMap::NO_DATA.evidence)

    def stale = @stale ||= files_reporting(CoverageMap::STALE.evidence)

    def files_reporting(evidence)
      files.count { |methods| methods.all? { |score| score.evidence == evidence } }
    end

    def files
      @files ||= @scores.group_by { |score| score.location.to_s.rpartition(":").first }.values
    end

    def cells(score)
      [score.name, score.cc.to_s, percentage(score.coverage), format("%.2f", score.crap),
        score.evidence.to_s, score.location.to_s]
    end

    def percentage(coverage) = coverage.nil? ? "—" : format("%.1f%%", coverage * 100)

    def column_widths(rows)
      ([HEADINGS] + rows).transpose.map { |column| column.map(&:length).max }
    end

    def heading(widths) = line(HEADINGS, widths)

    def divider(widths) = "-" * (widths.sum + 2 * (widths.size - 1))

    def line(cells, widths)
      cells.each_with_index.map do |cell, index|
        (index.zero? || index == cells.size - 1) ? cell.ljust(widths[index]) : cell.rjust(widths[index])
      end.join("  ").rstrip
    end
  end
end
