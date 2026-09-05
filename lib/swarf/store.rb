# frozen_string_literal: true

require "json"
require "digest"
require "fileutils"

module Swarf
  class Store
    FILENAME = "coverage.json"

    def self.default_dir = ENV.fetch("SWARF_DIR", File.join(Dir.pwd, ".swarf"))

    def initialize(dir = self.class.default_dir, root: Dir.pwd)
      @dir = dir
      @root = File.expand_path(root)
    end

    def read
      parse(File.read(path)).to_h { |file, entry| [file, Measurement.new(file, entry)] }
    rescue Errno::ENOENT
      {}
    end

    def record(result)
      fresh = normalize(result)
      return if fresh.empty?

      FileUtils.mkdir_p(@dir)
      File.open(path, File::RDWR | File::CREAT, 0o644) do |file|
        file.flock(File::LOCK_EX)
        merged = merge(parse(file.read), fresh)
        file.rewind
        file.write(JSON.pretty_generate(merged))
        file.truncate(file.pos)
      end
    end

    private

    def path = File.join(@dir, FILENAME)

    def parse(json)
      JSON.parse(json)
    rescue JSON::ParserError
      {}
    end

    def merge(merged, fresh)
      fresh.each do |file, entry|
        previous = merged[file]
        merged[file] = (previous && previous["sha"] == entry["sha"]) ? combine(previous, entry) : entry
      end
      merged
    end

    def normalize(result)
      result.filter_map do |file, coverage|
        file = File.expand_path(file, @root)
        next unless project_file?(file)

        [file, {
          "sha" => Digest::SHA256.file(file).hexdigest,
          "lines" => coverage[:lines] || [],
          "branches" => stringify_branches(coverage[:branches] || {}),
          "methods" => stringify_methods(coverage[:methods] || {})
        }]
      end.to_h
    end

    def project_file?(file)
      file.start_with?("#{@root}/") && File.file?(file)
    end

    def stringify_branches(branches)
      branches.to_h do |branch, outcomes|
        [branch.join(":"), outcomes.transform_keys { |outcome| outcome.join(":") }]
      end
    end

    def stringify_methods(methods)
      methods.each_with_object(Hash.new(0)) do |((_owner, _name, line, *), count), totals|
        totals[line.to_s] += count
      end
    end

    def combine(previous, fresh)
      fresh.merge(
        "lines" => sum_lines(previous["lines"], fresh["lines"]),
        "branches" => sum_branches(previous["branches"], fresh["branches"]),
        "methods" => previous["methods"].merge(fresh["methods"]) { |_, a, b| a + b }
      )
    end

    def sum_lines(previous, fresh)
      fresh.each_with_index.map do |hits, index|
        hits.nil? ? nil : hits + (previous[index] || 0)
      end
    end

    def sum_branches(previous, fresh)
      fresh.merge(previous) do |_branch, a, b|
        a.merge(b) { |_outcome, x, y| x + y }
      end
    end
  end
end
