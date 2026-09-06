# frozen_string_literal: true

require "fileutils"

module Swarf
  class Init
    SKILL_SOURCE = File.expand_path("../../skills/swarf", __dir__)
    SKILL_TARGET = File.join(".claude", "skills", "swarf")
    GITIGNORE_ENTRY = ".swarf/"

    def initialize(root = Dir.pwd)
      @root = root
    end

    def run(out)
      out.puts "#{install_skill} #{SKILL_TARGET}/"
      out.puts "#{ignore_store} #{GITIGNORE_ENTRY} in .gitignore"
    end

    private

    def install_skill
      target = File.join(@root, SKILL_TARGET)
      existed = File.directory?(target)
      FileUtils.mkdir_p(target)
      FileUtils.cp_r(File.join(SKILL_SOURCE, "."), target)
      existed ? "updated" : "wrote"
    end

    def ignore_store
      path = File.join(@root, ".gitignore")
      lines = File.exist?(path) ? File.readlines(path, chomp: true) : []
      return "kept" if lines.any? { |line| line.strip.delete_suffix("/") == GITIGNORE_ENTRY.delete_suffix("/") }

      File.write(path, [*lines, GITIGNORE_ENTRY].join("\n") + "\n")
      "added"
    end
  end
end
