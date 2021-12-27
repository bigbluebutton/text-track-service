# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.5.7'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'activerecord'
gem 'faktory_worker_ruby'
gem 'google-cloud-speech'
gem 'google-cloud-storage'
gem 'aws-sdk'
gem 'aws-sdk-transcribestreamingservice'

gem 'httparty'
gem 'jwt'
# Use Puma as the app server
gem "pg"

gem 'puma', '~> 3.12.4'

gem 'rails', '~> 5.2.3'

gem 'redis', '4.1.2'
gem 'redis-namespace'
gem 'redis-rack-cache'
gem 'redis-rails'

gem 'rubocop', require: false

gem 'sequel'
gem 'speech_to_text', '0.1.8'
# Use sqlite3 as the database for Active Record
#gem 'sqlite3'
gem 'table_print'
gem 'open3'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS),
# making cross-origin AJAX possible
# gem 'rack-cors'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution
  # and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
