require "rake"
require "rake/testtask"

require_relative "lib/dotfiles/installer"

desc "Install the managed dotfiles into the current user's home directory"
task :install do
  Dotfiles::Installer.new.install
end

desc "Check required tools, source files, and installed dotfile status"
task :doctor do
  abort "Dotfiles doctor found blocking issues." unless Dotfiles::Installer.new.doctor
end

Rake::TestTask.new(:test) do |task|
  task.libs << "test"
  task.pattern = "test/**/*_test.rb"
  task.warning = true
end

desc "Validate Ruby, shell, and Vim configuration syntax"
task :syntax do
  sh "ruby", "-c", "Rakefile"
  sh "ruby", "-c", "irbrc"
  sh "ruby", "-c", "oh-my-zsh/custom/plugins/rbates/bin/tagversions"
  sh "zsh", "-n",
     "zshrc",
     "my_aliases.sh",
     "my_functions.sh",
     "oh-my-zsh/custom/plugins/rbates/rbates.plugin.zsh",
     "oh-my-zsh/custom/rbates.zsh-theme"
  sh "zsh", "test/shell_smoke.zsh"
  sh "bash", "-n", "workstation_setup.sh", "scripts/commit_message.sh"
  sh({ "DOTFILES_SKIP_LOCAL" => "1" },
     "vim", "-Nu", File.expand_path("vimrc", __dir__),
     "-n", "-i", "NONE", "-es", "+qa!")
end

desc "Run the complete local validation suite"
task check: %i[test syntax]

task default: :check
