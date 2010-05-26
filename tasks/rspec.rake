begin
  require 'spec'
rescue LoadError
  require 'rubygems' unless ENV['NO_RUBYGEMS']
  require 'spec'
end
begin
  require 'spec/rake/spectask'
rescue LoadError
  puts <<-EOS
To use rspec for testing you must install rspec gem:
    gem install rspec
EOS
  exit(0)
end

desc "Run the specs under spec/models"
Spec::Rake::SpecTask.new do |t|
  t.spec_opts = ['--options', "spec/spec.opts"]
  t.spec_files = FileList['spec/**/*_spec.rb']
end

begin
  require 'rcov'
  require 'spec/rake/verify_rcov'

  Spec::Rake::SpecTask.new(:rcov) do |rcov|
    spec_defaults.call(rcov)
    rcov.rcov      = true
    rcov.rcov_opts = File.read('spec/rcov.opts').split(/\s+/)
  end

  RCov::VerifyTask.new(:verify_rcov => :rcov) do |rcov|
    rcov.threshold = 100
  end
rescue LoadError
  %w[ rcov verify_rcov ].each do |name|
    task name do
      abort "rcov is not available. In order to run #{name}, you must: gem install rcov"
    end
  end
end

task :rcov => :check_dependencies