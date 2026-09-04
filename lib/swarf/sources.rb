# frozen_string_literal: true

module Swarf
  # Turns command-line paths into the list of Ruby files to score.
  module Sources
    IGNORE_FILE = ".swarfignore"

    # Globs matched against each file's path relative to the root being scanned.
    DEFAULT_IGNORE = [
      # Where coverage comes from, not where risk lives.
      "**/test/**", "**/spec/**", "**/features/**",
      # Generated, run once, never tested. On a well-tested app these are the only
      # untested code left, so without this they take over the top of the report.
      "db/**",
      "**/vendor/**", "**/tmp/**", "**/log/**", "**/node_modules/**"
    ].freeze

    def self.collect(paths, ignore: DEFAULT_IGNORE)
      paths = ["."] if paths.empty?
      paths.flat_map { |path| expand(File.expand_path(path), ignore) }.uniq.sort
    end

    # One glob per line; `#` comments and blank lines are skipped.
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

    # No single fnmatch call covers the shapes people write. With `FNM_PATHNAME` a
    # trailing `**` spans only one segment; without it a leading `**/` cannot match zero
    # directories. So each pattern is tried both ways, and a `**/`-anchored one is tried
    # again unanchored so it also catches the directory at the root.
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
