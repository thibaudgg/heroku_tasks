module HerokuTasks
  module Generators
    class ConfigGenerator < Rails::Generators::Base
      desc "Creates a HerokuTasks configuration file at config/heroku.yml"
      
      def self.source_root
        @source_root ||= File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
      end
      
      def create_config_file
        template 'heroku.yml', File.join('config', "heroku.yml")
      end
      
    end
  end
end
