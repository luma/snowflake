# require "bundler"
# Bundler.setup
# 
# gemspec = eval(File.read("snowflake.gemspec"))
# 
# desc "Build the gem"
# task :build => "#{gemspec.full_name}.gem"
# 
# file "#{gemspec.full_name}.gem" => gemspec.files + ["snowflake.gemspec"] do
#   system "gem build snowflake.gemspec"
#   system "gem install snowflake-#{Snowflake::VERSION}.gem"
# end

require 'bundler'
Bundler::GemHelper.install_tasks

Dir['tasks/**/*.rake'].each { |t| load t }