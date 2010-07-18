require File.expand_path("../lib/snowflake/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "snowflake"
  s.version     = Snowflake::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Rolly Fordham"]
  s.email       = ["rolly@luma.co.nz"]
  s.homepage    = "http://github.com/luma/snowflake"
  s.summary     = "A simple graph database built on top of Redis. Just an experiment for now, I'm trying out a bunch of ideas. Syntax heavily influenced by the awesome DataMapper."
  s.description = ""

  s.required_rubygems_version = ">= 1.3.6"

  # lol - required for validation
  s.rubyforge_project         = "snowflake"

  # If you have other dependencies, add them here
  s.add_dependency "redis", ">= 2.0.1"
  s.add_dependency "redis-namespace", ">= 0.5.0"
  s.add_dependency "uuidtools", ">= 2.1.1"
  s.add_dependency "tzinfo"  
  s.add_dependency "activesupport", ">= 3.0.0.beta4"
  s.add_dependency "activemodel", ">= 3.0.0.beta4"

  # If you need to check in files that aren't .rb files, add them here
  s.files        = Dir["{lib}/snowflake.rb", "{lib}/snowflake/*.rb", "{lib}/snowflake/**/*.rb", "LICENSE", "*.md", "README.rdoc"]
  s.require_path = 'lib'
end