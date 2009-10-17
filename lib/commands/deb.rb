require 'rubygems/install_update_options'
require 'rubygems/dependency_installer'
require 'rubygems/local_remote_options'
require 'rubygems/version_option'
require 'rubygems/validator'

require 'tmpdir'
require 'erb'

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

    @templates_dir = File.dirname(__FILE__)+"/../templates"
    @install_dir = Dir.tmpdir+"/gemdeb_home"
    @current_dir = Dir.getwd

    FileUtils.mkpath(@install_dir)
  end

  def execute
    install_options = {
      :env_shebang => options[:env_shebang],
      :domain => options[:domain],
      :force => options[:force],
      :format_executable => options[:format_executable],
      :ignore_dependencies => options[:ignore_dependencies],
      :install_dir => @install_dir,
      :security_policy => options[:security_policy],
      :wrappers => options[:wrappers],
      :bin_dir => "#{@install_dir}/bin",
      :development => options[:development]
    }

    get_all_gem_names.each do |gem_name|
      installer = Gem::DependencyInstaller.new(install_options)
      installer.install gem_name, options[:version]

      installer.installed_gems.each do |spec|
        generate_deb_for(spec)
      end
    end
  end

  protected
  def generate_deb_for(spec)
    say "Generating deb for #{spec.full_name}..."
    target_dir = @install_dir+"/gems/#{spec.full_name}"
    deb_package_path = nil
    Dir.chdir(target_dir) do
      deb_package_path = install_debian_template(target_dir, spec)
      system("dpkg-buildpackage -rfakeroot -b")
    end

    if deb_package_path && File.exist?(deb_package_path)
      FileUtils.mv(deb_package_path, @current_dir)
    end
  end

  def install_debian_template(target_dir, spec)
    debian_tpl_dir = @templates_dir+"/debian"
    debian_dir = target_dir+"/debian"
    FileUtils.mkpath(debian_dir)

    files = Dir.glob("*")
    Dir.foreach(debian_tpl_dir) do |tpl|
      next if File.directory?(tpl)

      tpl_path = File.join(debian_tpl_dir, tpl)

      @tpl_options = {:spec => spec, :files => files}
      @tpl_options[:libdir] = Config::CONFIG["rubylibdir"]
      @tpl_options[:arch] = "all" # FIXME: autodetect

      data = ERB.new(File.read(tpl_path)).result(binding)
      File.open("#{debian_dir}/#{tpl}", "w") do |f|
        f.puts data
      end
    end

    old_umask=File.umask(0)
    File.chmod(0755, "#{debian_dir}/rules")
    File.umask(old_umask)

    File.expand_path("#{target_dir}/../#{spec.name}_#{spec.version}_#{@tpl_options[:arch]}.deb")
  end
end

