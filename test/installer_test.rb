require "minitest/autorun"
require "open3"
require "stringio"
require "tmpdir"

require_relative "../lib/dotfiles/installer"

class InstallerTest < Minitest::Test
  def setup
    @temporary_directory = Dir.mktmpdir("dotfiles-test")
    @home = File.join(@temporary_directory, "home")
    Dir.mkdir(@home)
    @output = StringIO.new
  end

  def teardown
    FileUtils.remove_entry(@temporary_directory)
  end

  def test_installs_only_the_explicit_manifest
    installer = build_installer("Test User\ntest@example.com\n")

    installer.install_dotfiles

    assert File.symlink?(File.join(@home, ".my_aliases.sh"))
    assert File.symlink?(File.join(@home, ".zsh"))
    assert File.symlink?(File.join(@home, ".vim"))
    assert_equal File.binread(File.expand_path("../zshrc", __dir__)),
                 File.binread(File.join(@home, ".zshrc"))
    refute File.exist?(File.join(@home, ".README.md"))
    refute File.exist?(File.join(@home, ".LICENSE"))

    gitconfig = File.read(File.join(@home, ".gitconfig"))
    assert_includes gitconfig, 'name = "Test User"'
    assert_includes gitconfig, 'email = "test@example.com"'
    refute_match(/token/i, gitconfig)
    assert_equal 0o600, File.stat(File.join(@home, ".gitconfig")).mode & 0o777

    _output, error, status = Open3.capture3(
      "git", "config", "--file", File.join(@home, ".gitconfig"), "--list"
    )
    assert status.success?, error
  end

  def test_existing_target_is_backed_up_before_replacement
    existing = File.join(@home, ".gemrc")
    File.write(existing, "old configuration\n")
    installer = build_installer("y\n")
    entry = Dotfiles::Installer::ENTRIES.find { |candidate| candidate.target == "gemrc" }

    installer.send(:install_entry, entry, false)

    assert File.symlink?(existing)
    backups = Dir.glob(File.join(@home, ".dotfiles-backups", "*", ".gemrc"))
    assert_equal 1, backups.length
    assert_equal "old configuration\n", File.read(backups.first)
  end

  def test_existing_target_can_be_skipped
    existing = File.join(@home, ".gemrc")
    File.write(existing, "keep me\n")
    installer = build_installer("n\n")
    entry = Dotfiles::Installer::ENTRIES.find { |candidate| candidate.target == "gemrc" }

    result = installer.send(:install_entry, entry, false)

    assert_equal :skipped, result
    assert_equal "keep me\n", File.read(existing)
    refute File.symlink?(existing)
  end

  def test_current_symlink_is_idempotent
    source = File.expand_path("../gemrc", __dir__)
    destination = File.join(@home, ".gemrc")
    File.symlink(source, destination)
    installer = build_installer("")
    entry = Dotfiles::Installer::ENTRIES.find { |candidate| candidate.target == "gemrc" }

    result = installer.send(:install_entry, entry, false)

    assert_equal :current, result
    assert_equal source, File.readlink(destination)
  end

  def test_git_config_values_are_escaped
    installer = build_installer("")

    escaped = installer.send(:escape_git_config_value, "Name \"with\" \\ slash\nnext")

    assert_equal "Name \\\"with\\\" \\\\ slash next", escaped
  end

  def test_full_install_is_offline_when_dependencies_already_exist
    %w[zsh-autosuggestions zsh-syntax-highlighting].each do |plugin|
      FileUtils.mkdir_p(
        File.join(@home, ".oh-my-zsh", "custom", "plugins", plugin)
      )
    end
    installer = build_installer(
      "Test User\ntest@example.com\n",
      command_runner: ->(*) { flunk "unexpected external command" }
    )

    installer.install

    assert File.symlink?(File.join(@home, ".zsh"))
    refute File.exist?(
      File.join(@home, ".oh-my-zsh", "custom", "plugins", "rbates")
    )
  end

  private

  def build_installer(input, command_runner: nil)
    Dotfiles::Installer.new(
      root: File.expand_path("..", __dir__),
      home: @home,
      env: {
        "HOME" => @home,
        "PATH" => ENV.fetch("PATH"),
        "SHELL" => "/bin/zsh"
      },
      input: StringIO.new(input),
      output: @output,
      command_runner: command_runner
    )
  end
end
