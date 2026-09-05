# frozen_string_literal: true

module Swarf
  module Sources
    IGNORE_FILE = ".swarfignore"

    DEFAULT_IGNORE = [
      "**/test/**", "**/spec/**", "**/features/**",
      "db/**",
      "**/vendor/**", "**/tmp/**", "**/log/**", "**/node_modules/**"
    ].freeze

    def self.collect(paths, ignore:)
      patterns = ignore.flat_map { |pattern| variants(pattern) }
      paths.flat_map { |path| expand(path, patterns) }.uniq.sort
    end

    def self.ignore_file(root = Dir.pwd)
      File.readlines(File.join(root, IGNORE_FILE), chomp: true)
        .map(&:strip).reject { |line| line.empty? || line.start_with?("#") }
    rescue Errno::ENOENT
      []
    end

    def self.expand(path, patterns)
      return [path] if File.file?(path)
      raise Error, "no such file or directory: #{path}" unless File.directory?(path)

      Dir.glob(File.join(path, "**", "*.rb"))
        .reject { |file| ignored?(file.delete_prefix("#{path}/"), patterns) }
    end

    def self.ignored?(relative, patterns)
      patterns.any? do |pattern|
        File.fnmatch?(pattern, relative, File::FNM_PATHNAME) || File.fnmatch?(pattern, relative)
      end
    end

    def self.variants(pattern)
      pattern.start_with?("**/") ? [pattern, pattern.delete_prefix("**/")] : [pattern]
    end
  end
end
