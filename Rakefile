#FIXME Necessary hack to avoid the need of downgrading rubygems on rails 2.3.5
# http://stackoverflow.com/questions/5564251/uninitialized-constant-activesupportdependenciesmutex
require 'thread'

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'active_support/all'
ActiveSupport::Deprecation.silenced = true

# rails tasks
require 'tasks/rails'

# plugins' tasks
plugins_tasks = Dir.glob("config/plugins/*/{tasks,lib/tasks,rails/tasks}/**/*.rake").sort +
  Dir.glob("config/plugins/*/vendor/plugins/*/{tasks,lib/tasks,rails/tasks}/**/*.rake").sort
plugins_tasks.each{ |ext| load ext }
