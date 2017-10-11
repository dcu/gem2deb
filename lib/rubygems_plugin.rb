$:.unshift File.dirname(__FILE__)

require 'rubygems/command_manager'

%w[deb].each do |command|
  require "commands/#{command}_command"
  Gem::CommandManager.instance.register_command command.to_sym
end

