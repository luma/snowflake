require 'rubygems'
gem 'hoe', '>= 2.1.0'
require 'hoe'
require 'fileutils'
require './lib/snowflake'

Hoe.plugin :newgem
# Hoe.plugin :website
# Hoe.plugin :cucumberfeatures

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.spec 'snowflake' do
  self.developer 'Rolly', 'rolly@luma.co.nz'
  #self.post_install_message = 'PostInstall.txt' # TODO remove if post-install message not required
  self.rubyforge_name       = self.name # TODO this is default value
  self.extra_deps         = [
    ['redis','>= 2.0.1'],
    ['redis-namespace','>= 0.5.0'],
    ['uuidtools', '>= 2.1.1']
  ]
end

require 'newgem/tasks'
RAILS_ROOT = File.join(Pathname(__FILE__).dirname.expand_path)
Dir['tasks/**/*.rake'].each { |t| load t }

# TODO - want other tests/tasks run by default? Add them to the list
# remove_task :default
# task :default => [:spec, :features]