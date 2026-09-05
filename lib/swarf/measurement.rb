# frozen_string_literal: true

require "digest"

module Swarf
  class Measurement
    def initialize(path, entry)
      @path = path
      @entry = entry
      @current = nil
    end

    def current?
      @current = File.file?(@path) && Digest::SHA256.file(@path).hexdigest == @entry["sha"] if @current.nil?
      @current
    end

    def calls(line)
      @entry["methods"][line.to_s]
    end

    def branches(range)
      range.flat_map { |line| outcomes_by_line.fetch(line, []) }
    end

    def lines(range)
      range.filter_map { |line| @entry["lines"][line - 1] }
    end

    private

    def outcomes_by_line
      @outcomes_by_line ||= @entry["branches"].each_with_object({}) do |(branch, taken), by_line|
        (by_line[branch.split(":")[2].to_i] ||= []).concat(taken.values)
      end
    end
  end
end
