source "https://rubygems.org"
gem 'rails',                    '~> 3.2.21'
gem 'fast_gettext',             '~> 0.6.8'
gem 'acts-as-taggable-on',      '~> 3.0.2'
gem 'rails_autolink',           '~> 1.1.5'
gem 'RedCloth',                 '~> 4.2.9'
gem 'ruby-feedparser',          '~> 0.7'
gem 'daemons',                  '~> 1.1.5'
gem 'nokogiri',                 '~> 1.5.5'
gem 'rake', require: false
gem 'rest-client',              '~> 1.6.7'
gem 'exception_notification',   '~> 4.0.1'
gem 'gettext',                  '~> 2.2.1', require: false, group: :development
gem 'locale',                   '~> 2.0.5'
gem 'will-paginate-i18n'
gem 'utf8-cleaner'

platform :ruby do
  gem 'pg'
  gem 'rmagick',                '~> 2.13.1'
  gem 'thin'

  gem 'unicode'

  group :performance do
    gem 'fast_blank'
    gem 'gctools' if RUBY_VERSION >= '2.1.0' and RUBY_VERSION < '2.2.0'
    # DON'T IMPROVE
    #gem 'escape_utils'
  end

  group :production do
    gem 'unicorn'
    #gem 'rainbows'
    gem 'unicorn-worker-killer'
  end
end
platform :jruby do
  gem 'activerecord-jdbcpostgresql-adapter'
  gem 'rmagick4j'
end

gem 'eita-jrails', path: 'vendor/plugins/eita-jrails'

gem 'premailer-rails'

group :assets do
  gem 'assets_live_compile'
  gem 'therubyracer', platforms: :ruby
  gem 'uglifier', '>= 1.0.3'
  gem 'coffee-rails'
  gem 'sass'
  gem 'sass-rails'
end

group :production do
  gem 'newrelic_rpm'
  gem 'redis-rails'
  gem 'rack-cache'
end

# needed as removed from ruby 2.2
gem 'test-unit' if RUBY_VERSION >= '2.2'

group :test do
  gem 'rspec',                  '~> 2.10.0'
  gem 'rspec-rails',            '~> 2.10.1'
  gem 'mocha',                  '~> 1.1.0', require: false
end

group :cucumber do
  gem 'cucumber-rails',         '~> 1.0.6', require: false
  gem 'capybara',               '~> 2.1.0'
  gem 'cucumber',               '~> 1.0.6'
  gem 'database_cleaner',       '~> 1.2.0'
  # FIXME: conflicts with axlsx version 2, that requires rubyzip 1.0.0 and selenium-webdriver requires rubyzip 1.1.6
  #gem 'selenium-webdriver',     '~> 2.39.0'
end

group :development do
  #gem 'byebug'
end
# include gemfiles from enabled plugins
# plugins in baseplugins/ are not included on purpose. They should not have any
# dependencies.
Dir.glob('config/plugins/*/Gemfile').each do |gemfile|
  eval File.read(gemfile)
end
