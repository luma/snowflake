require 'rubygems'
gem 'hoe', '>= 2.1.0'
require 'hoe'
require 'fileutils'
require './lib/redis-graph'

Hoe.plugin :newgem
# Hoe.plugin :website
# Hoe.plugin :cucumberfeatures

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.spec 'redis-graph' do
  self.developer 'Rolly', 'rolly@luma.co.nz'
  #self.post_install_message = 'PostInstall.txt' # TODO remove if post-install message not required
  self.rubyforge_name       = self.name # TODO this is default value
  self.extra_deps         = [
    ['extlib','>= 0.9.10'],
    ['redis','>= 2.0.0'],
    ['redis-namespace','>= 0.5.0'],
    ['uuidtools', '>= 2.1.1'],
    ['jnunemaker-validatable', '>= 1.8.4']
  ]

end

require 'newgem/tasks'
Dir['tasks/**/*.rake'].each { |t| load t }

# TODO - want other tests/tasks run by default? Add them to the list
# remove_task :default
# task :default => [:spec, :features]