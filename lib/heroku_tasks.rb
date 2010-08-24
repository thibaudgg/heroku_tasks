module HerokuTasks
  require 'heroku_tasks/railtie' if defined?(Rails)
  
  class << self
    
    def method_missing(name)
      yml[name.to_s]
    end
    
  private
    
    def yml
      config_path = Rails.root.join('config', 'heroku.yml')
      @yml_options ||= YAML::load_file(config_path)
    rescue
      raise "\nconfig/heroku.yml not found. To generate one run: rails generate heroku_tasks:config\n"
    end
    
  end
end
