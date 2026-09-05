# frozen_string_literal: true

module Swarf
  module Sources
    IGNORE_FILE = ".swarfignore"

    DEFAULT_IGNORE = [
      "**/test/**", "**/spec/**", "**/features/**",
      "db/**",
      "**/vendor/**", "**/tmp/**", "**/log/**", "**/node_modules/**"
    ].freeze

    def self.collect(paths, ignore: DEFAULT_IGNORE)
      paths = ["."] if paths.empty?
      paths.flat_map { |path| expand(File.expand_path(path), ignore) }.uniq.sort
    end

    def self.ignore_file(root = Dir.pwd)
      File.readlines(File.join(root, IGNORE_FILE), chomp: true)
        .map(&:strip).reject { |line| line.empty? || line.start_with?("#") }
    rescue Errno::ENOENT
      []
    end

    def self.expand(path, ignore)
      return [path] if File.file?(path)
      raise Error, "no such file or directory: #{path}" unless File.directory?(path)

      Dir.glob(File.join(path, "**", "*.rb"))
        .reject { |file| ignored?(file.delete_prefix("#{path}/"), ignore) }
    end

    def self.ignored?(relative, ignore)
      ignore.any? do |pattern|
        variants(pattern).any? do |variant|
          File.fnmatch?(variant, relative, File::FNM_PATHNAME) || File.fnmatch?(variant, relative)
        end
      end
    end

    def self.variants(pattern)
      pattern.start_with?("**/") ? [pattern, pattern.delete_prefix("**/")] : [pattern]
    end
  end
end
