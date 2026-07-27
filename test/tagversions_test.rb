require "minitest/autorun"
require "stringio"
require "tmpdir"

load File.expand_path("../oh-my-zsh/custom/plugins/rbates/bin/tagversions", __dir__)

class TagVersionsTest < Minitest::Test
  def test_preview_reports_tag_without_modifying_repository
    with_repository do
      output = StringIO.new
      tagger = TagVersions.from_argv(["--preview", "release"], output: output)

      tagger.run

      assert_match(/Would tag 1\.2\.3/, output.string)
      assert_equal "", `git tag --list`
    end
  end

  def test_creates_each_version_tag_once
    with_repository do
      output = StringIO.new
      tagger = TagVersions.from_argv(["--all"], output: output)

      tagger.run
      tagger.run

      assert_equal ["1.2.3"], `git tag --list`.lines(chomp: true)
      assert_equal 1, output.string.scan(/Tagging 1\.2\.3/).length
    end
  end

  def test_rejects_an_invalid_regular_expression
    assert_raises(ArgumentError) do
      TagVersions.from_argv(["["])
    end
  end

  private

  def with_repository
    Dir.mktmpdir("tagversions-test") do |directory|
      Dir.chdir(directory) do
        system("git", "init", "--quiet") || raise("git init failed")
        system("git", "config", "user.name", "Dotfiles Test") || raise("git config failed")
        system("git", "config", "user.email", "dotfiles@example.test") || raise("git config failed")
        File.write("version.txt", "1.2.3\n")
        system("git", "add", "version.txt") || raise("git add failed")
        system("git", "commit", "--quiet", "-m", "release 1.2.3") || raise("git commit failed")
        yield
      end
    end
  end
end
