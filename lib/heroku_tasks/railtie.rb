require 'heroku_tasks'
require 'rails'

module HerokuTasks
  class Railtie < Rails::Railtie
    railtie_name :heroku_tasks
    
    rake_tasks do
      load "tasks/assets.rake"
      load "tasks/deploy.rake"
    end
  end
end
