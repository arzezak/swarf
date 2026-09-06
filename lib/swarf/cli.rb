# frozen_string_literal: true

require "optparse"

module Swarf
  class CLI
    def self.run(argv, out: $stdout)
      (argv == ["init"]) ? Init.new.run(out) : new(argv).run(out)
    end

    def initialize(argv)
      @limit = Report::DEFAULT_LIMIT
      @extra_ignore = []
      @all = false
      @paths = parse(argv)
    end

    def run(out)
      scores = Scan.new(paths: @paths, ignore: ignore).scores
      out.print Report.new(scores, limit: @limit).to_s
    end

    private

    def ignore
      return [] if @all

      Sources::DEFAULT_IGNORE + Sources.ignore_file + @extra_ignore
    end

    def parse(argv)
      parser = OptionParser.new do |opts|
        opts.banner = <<~USAGE
          Usage: swarf [options] [paths]
                 swarf init    Install the Claude Code skill and ignore .swarf/
        USAGE
        opts.on("-n", "--limit N", Integer, "Rows to show (0 for all, default #{Report::DEFAULT_LIMIT})") do |n|
          @limit = n
        end
        opts.on("-i", "--ignore GLOB", "Skip paths matching GLOB (repeatable)") do |glob|
          @extra_ignore << glob
        end
        opts.on("-a", "--all", "Score everything, including #{Sources::IGNORE_FILE} and the defaults") do
          @all = true
        end
        opts.on("-v", "--version", "Print the version and exit") do
          puts VERSION
          exit 0
        end
        opts.on("-h", "--help", "Print this message and exit") do
          puts opts
          exit 0
        end
      end
      parser.parse(argv)
    end
  end
end
