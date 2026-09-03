# frozen_string_literal: true

require_relative "lib/swarf/version"

Gem::Specification.new do |spec|
  spec.name = "swarf"
  spec.version = Swarf::VERSION
  spec.authors = ["Ariel Rzezak"]
  spec.email = ["arzezak@gmail.com"]

  spec.summary = "Scores Ruby methods by the CRAP metric: complexity against coverage."
  spec.description = "swarf computes CRAP = CC^2 * (1 - coverage)^3 + CC for every method " \
                     "in a file, directory or project. Complexity comes from Prism; coverage " \
                     "comes from a probe you load into your own test runs."
  spec.homepage = "https://github.com/arzezak/swarf"
  spec.required_ruby_version = ">= 3.4.0"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
