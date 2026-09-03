# frozen_string_literal: true

require "optparse"

module Swarf
  # `swarf [options] [paths]`
  class CLI
    def self.run(argv, out: $stdout, err: $stderr)
      new(argv).run(out, err)
    rescue Error => e
      err.puts("swarf: #{e.message}")
      1
    end

    def initialize(argv)
      @paths = parse(argv)
    end

    def run(out, _err)
      out.print Report.new(scores).to_s
      0
    end

    private

    def scores
      coverage = CoverageMap.new(Store.new.read)
      Sources.collect(@paths).flat_map do |path|
        Complexity.analyze(File.read(path), path: path).map do |method|
          found = coverage.for(method)
          Score.new(name: method.name, cc: method.cc,
                    coverage: found.coverage, evidence: found.evidence)
        end
      end
    end

    def parse(argv)
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: swarf [options] [paths]"
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
