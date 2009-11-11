require 'rubygems'
require 'rake/gempackagetask'

require 'merb-core'
require 'merb-core/tasks/merb'

GEM_NAME = "repertoire_core"
AUTHOR = "Christopher York"
EMAIL = "yorkc@mit.edu"
HOMEPAGE = "http://hyperstudio.mit.edu/repertoire"
SUMMARY = "RepertoireCore provides registration and role based authorization to Repertoire projects"
GEM_VERSION = "0.4.0"

spec = Gem::Specification.new do |s|
  s.rubyforge_project = 'merb'
  s.name = GEM_NAME
  s.version = GEM_VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README", "LICENSE", "TODO", "INSTALL"]
  s.summary = SUMMARY
  s.description = s.summary
  s.author = AUTHOR
  s.email = EMAIL
  s.homepage = HOMEPAGE
  
  s.add_dependency('rep.ajax.toolkit',  '~>0.1.1')
  s.add_dependency('rep.jquery',        '~>1.3.2')

  s.add_dependency('merb-mailer',    '~> 1.0.15')
  s.add_dependency('merb-assets',    '~> 1.0.15')
  s.add_dependency('merb-action-args',    '~> 1.0.15')
  s.add_dependency('merb-auth-core', '~> 1.0.15')
  s.add_dependency('merb-auth-more', '~> 1.0.15')
  s.add_dependency('merb-auth-slice-password',    '~> 1.0.15')
  s.add_dependency('merb-helpers',   '~> 1.0.15')
  s.add_dependency('merb-slices',    '~> 1.0.15')
  s.add_dependency('dm-core',        '~> 0.10.1')
#  s.add_dependency('dm-constraints', '~> 0.10.1')
  s.add_dependency('dm-validations', '~> 0.10.1')
  s.add_dependency('dm-timestamps',  '~> 0.10.1')
  s.add_dependency('dm-aggregates',  '~> 0.10.1')
  s.add_dependency('dm-is-nested_set', '~> 0.10.1')
  s.add_dependency('dm-is-list',     '~> 0.10.1')
  s.add_dependency('tlsmail',        '= 0.0.1')
  
  s.require_path = 'lib'
  s.files = %w(LICENSE README Rakefile TODO) + Dir.glob("{lib,spec,app,public,stubs}/**/*")
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "Install the gem"
task :install do
  Merb::RakeHelper.install(GEM_NAME, :version => GEM_VERSION)
end

desc "Uninstall the gem"
task :uninstall do
  Merb::RakeHelper.uninstall(GEM_NAME, :version => GEM_VERSION)
end

desc "Create a gemspec file"
task :gemspec do
  File.open("#{GEM_NAME}.gemspec", "w") do |file|
    file.puts spec.to_ruby
  end
end

require 'spec/rake/spectask'
require 'merb-core/test/tasks/spectasks'
desc 'Default: run spec examples'
task :default => 'spec'
