# frozen_string_literal: true

module Swarf
  # Turns command-line paths into the list of Ruby files to score.
  module Sources
    # Coverage comes from these; risk does not live in them.
    SKIP = %w[test spec vendor tmp node_modules].freeze

    def self.collect(paths)
      paths = ["."] if paths.empty?
      paths.flat_map { |path| expand(File.expand_path(path)) }.uniq.sort
    end

    def self.expand(path)
      return [path] if File.file?(path)
      raise Error, "no such file or directory: #{path}" unless File.directory?(path)

      Dir.glob(File.join(path, "**", "*.rb")).reject { |file| skip?(file, path) }
    end

    # A directory named on the command line is what you asked for, even if it is `spec/`;
    # only directories found underneath one are skipped.
    def self.skip?(file, root)
      file.delete_prefix("#{root}/").split(File::SEPARATOR)[0..-2].any? { |part| SKIP.include?(part) }
    end
  end
end
