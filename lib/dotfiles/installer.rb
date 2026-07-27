require "erb"
require "fileutils"
require "time"

module Dotfiles
  class Installer
    Entry = Struct.new(:source, :target, :strategy)

    ENTRIES = [
      Entry.new("gemrc", "gemrc", :link),
      Entry.new("gitconfig.erb", "gitconfig", :template),
      Entry.new("gitignore", "gitignore", :link),
      Entry.new("gvimrc", "gvimrc", :link),
      Entry.new("irbrc", "irbrc", :link),
      Entry.new("my_aliases.sh", "my_aliases.sh", :link),
      Entry.new("my_functions.sh", "my_functions.sh", :link),
      Entry.new("scripts", "scripts", :link),
      Entry.new("vim", "vim", :link),
      Entry.new("vimrc", "vimrc", :link),
      Entry.new("workstation_setup.sh", "workstation_setup.sh", :link),
      Entry.new("zshrc", "zshrc", :copy),
      Entry.new(
        "oh-my-zsh/custom/plugins/rbates",
        "oh-my-zsh/custom/plugins/rbates",
        :link
      ),
      Entry.new(
        "oh-my-zsh/custom/rbates.zsh-theme",
        "oh-my-zsh/custom/rbates.zsh-theme",
        :link
      )
    ].freeze

    THIRD_PARTY_PLUGINS = {
      "zsh-autosuggestions" => "https://github.com/zsh-users/zsh-autosuggestions.git",
      "zsh-syntax-highlighting" => "https://github.com/zsh-users/zsh-syntax-highlighting.git"
    }.freeze

    REQUIRED_COMMANDS = %w[git rake ruby zsh].freeze
    OPTIONAL_COMMANDS = %w[fzf vim].freeze

    attr_reader :root, :home

    def initialize(
      root: File.expand_path("../..", __dir__),
      home: ENV.fetch("HOME"),
      env: ENV,
      input: $stdin,
      output: $stdout,
      command_runner: nil
    )
      @root = File.expand_path(root)
      @home = File.expand_path(home)
      @env = env
      @input = input
      @output = output
      @command_runner = command_runner || ->(*command) { system(*command) }
      @backup_root = nil
    end

    def install
      install_oh_my_zsh
      install_custom_plugins
      switch_to_zsh
      install_dotfiles
    end

    def install_dotfiles
      replace_all = false

      ENTRIES.each do |entry|
        result = install_entry(entry, replace_all)
        replace_all = true if result == :replace_all
        break if result == :quit
      end
    end

    def install_oh_my_zsh
      destination = oh_my_zsh_dir
      if File.directory?(destination)
        say "found #{display_path(destination)}"
        return
      end

      case ask("install Oh My Zsh? [ynq] ")
      when :yes, :all
        clone("https://github.com/ohmyzsh/ohmyzsh.git", destination)
      when :quit
        raise Interrupt, "installation cancelled"
      else
        say "skipping Oh My Zsh; zshrc will still work with a basic prompt"
      end
    end

    def install_custom_plugins
      unless File.directory?(oh_my_zsh_dir)
        say "skipping third-party Zsh plugins because Oh My Zsh is not installed"
        return
      end

      plugins_dir = File.join(zsh_custom_dir, "plugins")
      FileUtils.mkdir_p(plugins_dir)

      THIRD_PARTY_PLUGINS.each do |name, url|
        destination = File.join(plugins_dir, name)
        if File.directory?(destination)
          say "found #{display_path(destination)}"
        else
          clone(url, destination)
        end
      end
    end

    def switch_to_zsh
      if File.basename(@env.fetch("SHELL", "")) == "zsh"
        say "using zsh"
        return
      end

      zsh = find_executable("zsh")
      unless zsh
        say "zsh is not installed; leaving the current login shell unchanged"
        return
      end

      case ask("switch the login shell to zsh? [ynq] ")
      when :yes, :all
        run!("chsh", "-s", zsh)
      when :quit
        raise Interrupt, "installation cancelled"
      else
        say "leaving the current login shell unchanged"
      end
    end

    def doctor
      ok = true
      say "Requirements:"

      REQUIRED_COMMANDS.each do |command|
        found = find_executable(command)
        say format("  %-8s %s", command, found || "MISSING")
        ok = false unless found
      end

      OPTIONAL_COMMANDS.each do |command|
        say format("  %-8s %s", command, find_executable(command) || "optional, not found")
      end

      say "Sources:"
      ENTRIES.each do |entry|
        source = source_path(entry)
        present = File.exist?(source)
        say format("  %-45s %s", entry.source, present ? "ok" : "MISSING")
        ok = false unless present
      end

      say "Installed targets:"
      ENTRIES.each do |entry|
        say format("  %-45s %s", "~/.#{entry.target}", target_status(entry))
      end

      ok
    end

    private

    def install_entry(entry, replace_all)
      source = source_path(entry)
      destination = destination_path(entry)
      raise "Missing source: #{source}" unless File.exist?(source)

      if current_target?(entry)
        say "current #{display_path(destination)}"
        return :current
      end

      choice = if path_exists?(destination) && !replace_all
                 ask("replace #{display_path(destination)}? [ynaq] ")
               elsif path_exists?(destination)
                 :yes
               else
                 :yes
               end

      case choice
      when :quit
        return :quit
      when :no
        say "skipping #{display_path(destination)}"
        return :skipped
      end

      backup(destination) if path_exists?(destination)
      deploy(entry, source, destination)
      choice == :all ? :replace_all : :installed
    end

    def deploy(entry, source, destination)
      FileUtils.mkdir_p(File.dirname(destination))

      case entry.strategy
      when :link
        say "linking #{display_path(destination)}"
        FileUtils.ln_s(source, destination)
      when :copy
        say "copying #{display_path(destination)}"
        FileUtils.cp(source, destination)
      when :template
        say "generating #{display_path(destination)}"
        content = render_gitconfig(source)
        File.write(destination, content)
        File.chmod(0o600, destination)
      else
        raise "Unknown install strategy: #{entry.strategy}"
      end
    end

    def current_target?(entry)
      destination = destination_path(entry)

      case entry.strategy
      when :link
        File.symlink?(destination) &&
          File.exist?(destination) &&
          File.identical?(source_path(entry), destination)
      when :copy
        File.file?(destination) &&
          File.binread(source_path(entry)) == File.binread(destination)
      else
        false
      end
    end

    def target_status(entry)
      destination = destination_path(entry)
      return "current" if current_target?(entry)
      return "not installed" unless path_exists?(destination)
      return "generated file present" if entry.strategy == :template

      "different existing target"
    end

    def render_gitconfig(template)
      git_name = escape_git_config_value(prompt_value("Your Name: "))
      git_email = escape_git_config_value(prompt_value("Your Email: "))
      ERB.new(File.read(template)).result_with_hash(
        git_name: git_name,
        git_email: git_email,
        home: escape_git_config_value(home)
      )
    end

    def escape_git_config_value(value)
      value.gsub(/["\\\r\n]/) do |character|
        case character
        when "\\" then "\\\\"
        when "\"" then "\\\""
        else " "
        end
      end
    end

    def backup(destination)
      @backup_root ||= File.join(
        home,
        ".dotfiles-backups",
        "#{Time.now.utc.strftime('%Y%m%dT%H%M%SZ')}-#{Process.pid}"
      )
      relative = destination.delete_prefix("#{home}/")
      backup_path = File.join(@backup_root, relative)
      FileUtils.mkdir_p(File.dirname(backup_path))
      FileUtils.mv(destination, backup_path)
      say "backed up #{display_path(destination)} to #{display_path(backup_path)}"
    end

    def clone(url, destination)
      say "cloning #{url} into #{display_path(destination)}"
      FileUtils.mkdir_p(File.dirname(destination))
      run!("git", "clone", "--depth", "1", url, destination)
    end

    def run!(*command)
      return if @command_runner.call(*command)

      raise "Command failed: #{command.join(' ')}"
    end

    def ask(question)
      @output.print(question)
      answer = @input.gets
      return :no unless answer

      case answer.strip.downcase
      when "a" then :all
      when "y", "yes" then :yes
      when "q", "quit" then :quit
      else :no
      end
    end

    def prompt_value(question)
      @output.print(question)
      value = @input.gets
      raise Interrupt, "installation cancelled" unless value

      value.chomp
    end

    def say(message)
      @output.puts(message)
    end

    def source_path(entry)
      File.join(root, entry.source)
    end

    def destination_path(entry)
      File.join(home, ".#{entry.target}")
    end

    def oh_my_zsh_dir
      value = @env["ZSH"]
      value && !value.empty? ? File.expand_path(value, home) : File.join(home, ".oh-my-zsh")
    end

    def zsh_custom_dir
      value = @env["ZSH_CUSTOM"]
      value && !value.empty? ? File.expand_path(value, home) : File.join(oh_my_zsh_dir, "custom")
    end

    def find_executable(command)
      @env.fetch("PATH", "").split(File::PATH_SEPARATOR).each do |directory|
        candidate = File.join(directory, command)
        return candidate if File.file?(candidate) && File.executable?(candidate)
      end
      nil
    end

    def path_exists?(path)
      File.exist?(path) || File.symlink?(path)
    end

    def display_path(path)
      path.sub(/\A#{Regexp.escape(home)}(?=\/|\z)/, "~")
    end
  end
end
