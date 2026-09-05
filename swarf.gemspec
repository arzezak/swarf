# frozen_string_literal: true

require_relative "lib/swarf/version"

Gem::Specification.new do |spec|
  spec.name = "swarf"
  spec.version = Swarf::VERSION
  spec.authors = ["Ariel Rzezak"]
  spec.email = ["arzezak@gmail.com"]

  spec.summary = "Scores Ruby methods by the CRAP metric: complexity against coverage."
  spec.description = "Ranks every Ruby method by complexity against test coverage, worst first."
  spec.homepage = "https://github.com/arzezak/swarf"
  spec.required_ruby_version = ">= 3.4.0"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      f.start_with?(*%w[bin/ Gemfile .gitignore test/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |file| File.basename(file) }
  spec.require_paths = ["lib"]
end
