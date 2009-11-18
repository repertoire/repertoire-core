require 'merb-core'
require 'merb-core/tasks/merb'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "repertoire_core"
    s.summary = "RepertoireCore provides registration and role based authorization to Repertoire projects"
    s.description = "RepertoireCore provides registration and role based authorization to Repertoire projects"
    s.email = "yorkc@mit.edu"
    s.homepage = "http://github.com/repertoire/repertoire-core"
    s.authors = ["Christopher York"]
    
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
  end
  Jeweler::RubyforgeTasks.new do |rubyforge|
    rubyforge.doc_task = "yardoc"
  end
 
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install jeweler"
end


require 'spec/rake/spectask'
require 'merb-core/test/tasks/spectasks'
desc 'Default: run spec examples'
task :default => 'spec'