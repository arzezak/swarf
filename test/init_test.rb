# frozen_string_literal: true

require "test_helper"

class InitTest < Minitest::Test
  def test_it_installs_the_skill_and_ignores_the_store
    dir = File.realpath(Dir.mktmpdir)
    write_file(File.join(dir, ".gitignore"), "/tmp/\n")

    output = swarf("init", chdir: dir)

    assert_equal "wrote .claude/skills/swarf/\nadded .swarf/ in .gitignore\n", output
    assert_match(/^name: swarf$/, File.read(File.join(dir, ".claude", "skills", "swarf", "SKILL.md")))
    assert_equal "/tmp/\n.swarf/\n", File.read(File.join(dir, ".gitignore"))
  end

  def test_running_it_again_refreshes_the_skill_and_leaves_the_gitignore_alone
    dir = File.realpath(Dir.mktmpdir)
    swarf("init", chdir: dir)
    File.write(File.join(dir, ".claude", "skills", "swarf", "SKILL.md"), "edited")

    output = swarf("init", chdir: dir)

    assert_equal "updated .claude/skills/swarf/\nkept .swarf/ in .gitignore\n", output
    assert_match(/^name: swarf$/, File.read(File.join(dir, ".claude", "skills", "swarf", "SKILL.md")))
    assert_equal ".swarf/\n", File.read(File.join(dir, ".gitignore"))
  end

  private

  def swarf(*args, chdir:)
    ruby(File.join(ROOT, "exe", "swarf"), *args, chdir: chdir, swarf_dir: Dir.mktmpdir)
  end
end
