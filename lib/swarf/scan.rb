# frozen_string_literal: true

module Swarf
  class Scan
    def initialize(paths:, ignore: [], store: Store.new, root: Dir.pwd)
      @root = File.expand_path(root)
      @paths = resolve(paths)
      @ignore = ignore
      @store = store
    end

    def scores
      coverage = CoverageMap.new(@store.read)
      Sources.collect(@paths, ignore: @ignore).flat_map do |path|
        Complexity.analyze(File.read(path), path: path).map do |method|
          found = coverage.for(method)
          Score.new(name: method.name, cc: method.cc, coverage: found.coverage,
            evidence: found.evidence, location: locate(method))
        end
      end
    end

    private

    def resolve(paths)
      return [@root] if paths.empty?

      paths.map { |path| File.expand_path(path, @root) }
    end

    def locate(method)
      "#{method.path.delete_prefix("#{@root}/")}:#{method.start_line}"
    end
  end
end
