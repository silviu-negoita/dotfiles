#!/usr/bin/env ruby

require "irb"
require "irb/completion"

IRB.conf[:SAVE_HISTORY] = 1_000
IRB.conf[:HISTORY_FILE] = File.join(Dir.home, ".irb_history")
IRB.conf[:PROMPT_MODE] = :SIMPLE

module DotfilesClipboard
  module_function

  def writer
    return ["pbcopy"] if available?("pbcopy")
    return ["wl-copy"] if available?("wl-copy")
    return ["xclip", "-selection", "clipboard"] if available?("xclip")

    nil
  end

  def reader
    return ["pbpaste"] if available?("pbpaste")
    return ["wl-paste", "--no-newline"] if available?("wl-paste")
    return ["xclip", "-selection", "clipboard", "-o"] if available?("xclip")

    nil
  end

  def available?(command)
    ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).any? do |directory|
      candidate = File.join(directory, command)
      File.file?(candidate) && File.executable?(candidate)
    end
  end
end

class Object
  # List methods defined directly on the object's class.
  def local_methods(obj = self)
    (obj.methods - obj.class.superclass.instance_methods).sort
  end

  # Print ri documentation for a class or method.
  #
  #   ri "Array#pop"
  #   Array.ri
  #   Array.ri :pop
  #   [].ri :pop
  def ri(method = nil)
    unless method && method.to_s.match?(/\A[A-Z]/)
      klass = is_a?(Class) ? name : self.class.name
      method = [klass, method].compact.join("#")
    end
    system("ri", method.to_s)
  end
end

def copy(value)
  command = DotfilesClipboard.writer
  raise "No clipboard writer found (pbcopy, wl-copy, or xclip)" unless command

  IO.popen(command, "w") { |clipboard| clipboard.write(value.to_s) }
  value
end

def copy_history
  history = if defined?(Reline::HISTORY)
              Reline::HISTORY.to_a
            elsif defined?(Readline::HISTORY)
              Readline::HISTORY.to_a
            else
              []
            end
  last_exit = history.rindex("exit") || -1
  copy(history[(last_exit + 1)..-2].to_a.join("\n"))
end

def paste
  command = DotfilesClipboard.reader
  raise "No clipboard reader found (pbpaste, wl-paste, or xclip)" unless command

  IO.popen(command, &:read)
end
