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
      @entry["branches"].filter_map do |branch, taken|
        taken.values if range.cover?(branch.split(":")[2].to_i)
      end.flatten
    end

    def lines(range)
      range.filter_map { |line| @entry["lines"][line - 1] }
    end
  end
end
