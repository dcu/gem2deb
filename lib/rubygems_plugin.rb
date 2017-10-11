$:.unshift File.dirname(__FILE__)

require 'rubygems/command_manager'
#require 'commands/abstract_command'

%w[deb].each do |command|
  require "commands/#{command}_command"
  Gem::CommandManager.instance.register_command command.to_sym
end

