require 'heroku_tasks'
require 'rails'

module HerokuTasks
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/deploy.rake"
    end
  end
end
