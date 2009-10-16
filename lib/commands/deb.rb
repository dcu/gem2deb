require 'rubygems/install_update_options'
require 'rubygems/dependency_installer'
require 'rubygems/local_remote_options'
require 'rubygems/version_option'
require 'rubygems/validator'

class Gem::Commands::DebCommand < Gem::Command
  include Gem::LocalRemoteOptions
  include Gem::VersionOption
  include Gem::InstallUpdateOptions

  def description
    'Convert a rubygem to debian package'
  end

  def arguments
    "GEM       gem to convert"
  end

  def usage
    "#{program_name} GEM"
  end

  def initialize
    defaults = Gem::DependencyInstaller::DEFAULT_OPTIONS.merge({
      :generate_rdoc => false,
      :generate_ri   => true,
      :format_executable => false,
      :test => false,
      :version => Gem::Requirement.default,
    })

    super 'deb', 'Convert a rubygem to debian package', defaults

    add_install_update_options
    add_local_remote_options
    add_version_option
  end

  def execute
    install_options = {
      :env_shebang => options[:env_shebang],
      :domain => options[:domain],
      :force => options[:force],
      :format_executable => options[:format_executable],
      :ignore_dependencies => options[:ignore_dependencies],
      :install_dir => "fixme",
      :security_policy => options[:security_policy],
      :wrappers => options[:wrappers],
      :bin_dir => "fixme/bin",
      :development => options[:development]
    }

    get_all_gem_names.each do |gem_name|
      inst = Gem::DependencyInstaller.new install_options
      inst.install gem_name, options[:version]

      inst.installed_gems.each do |spec|
        say "Successfully installed #{spec.full_name}"
      end
    end
  end
end

