# Deploy and rollback on Heroku in staging and production
namespace :deploy do
  GIT_REPOS      = ['git@jime1.epfl.ch:my.sublimevideo.net.git']
  STAGING_APP    = ''
  PRODUCTION_APP = 'empty-warrior-43'
  
  # Default
  APP    = PRODUCTION_APP
  TARGET = 'production'
  
  desc "Heroku staging deploy"
  task :staging => [:update_assets, :set_staging_app, :push, :restart, :tag]
  task :staging_migrations => [:set_staging_app, :migrations]
  task :staging_rollback => [:set_staging_app, :rollback]
  
  desc "Heroku production deploy"
  task :production => [:update_assets, :set_production_app, :push, :restart, :tag]
  task :production_off => [:set_production_app, :off]
  task :production_migrations => [:set_production_app, :migrations]
  task :production_rollback => [:set_production_app, :rollback]
  task :production_on => [:set_production_app, :on]
  
  # Don't call directly
  task :migrations => [:push, :migrate, :restart, :tag]
  task :rollback => [:push_previous, :restart]
  
  task :set_staging_app do
    APP    = STAGING_APP
    TARGET = 'staging'
  end
  
  task :set_production_app do
    APP    = PRODUCTION_APP
    TARGET = 'production'
  end
  
  task :update_assets => ['assets:prepare'] do
    timed do
      puts "\nUpdating assets before deploy for #{app_and_target}"
      puts `git add public/assets/*`
      puts `git commit public/assets/* -m 'Updated assets before deploy'`
    end
  end
  
  task :push do
    timed do
      puts "\nDeploying #{app_and_target} site to #{APP} on heroku/master ..."
      puts `git push git@heroku.com:#{APP}.git --force`
    end
  end
  
  task :restart do
    timed do
      puts "\nRestarting #{app_and_target} servers ..."
      puts `heroku restart --app #{APP}`
    end
  end
  
  task :tag do
    tag_and_push_release("#{prefix}#{normalized_date}")
  end
  
  task :migrate do
    timed do
      puts "\nRunning database migrations for #{app_and_target} ..."
      puts `heroku rake db:migrate --app #{APP}`
    end
  end
  
  task :off do
    timed do
      puts "\nPutting #{app_and_target} into maintenance mode ..."
      puts `heroku maintenance:on --app #{APP}`
    end
  end
  
  task :on do
    timed do
      puts "\nTaking #{app_and_target} out of maintenance mode ..."
      puts `heroku maintenance:off --app #{APP}`
    end
  end
  
  task :push_previous do
    releases = `git tag`.split("\n").select { |t| t[0..prefix.length-1] == prefix }.sort
    
    if releases.length >= 2
      current_release  = releases.last
      previous_release = releases[-2]
      
      started_at = Time.now.utc
      puts "\nRolling back to '#{previous_release}' ..."
      
      puts "\nChecking out '#{previous_release}' in a new branch on local git repo ..."
      puts `git checkout #{previous_release}`
      puts `git checkout -b #{previous_release}`
      
      puts "\nRemoving tagged version '#{previous_release}' (now transformed in branch) ..."
      delete_tagged_version(previous_release)
      
      puts "\nPushing '#{previous_release}' to #{APP} on heroku/master ..."
      puts `git push git@heroku.com:#{APP}.git +#{previous_release}:master --force`
      puts "Done"
      
      puts "\nDeleting rollbacked release '#{current_release}' ..."
      delete_tagged_version(current_release)
      
      puts "\nRetagging release '#{previous_release}' ..."
      tag_and_push_release(previous_release)
      
      puts "\nTurning local repo checked out on master ..."
      puts `git checkout master`
      puts "All done! Rolled back to '#{previous_release}' in #{Time.now.utc - started_at} seconds!"
    else
      puts "\nCan't roll back! You need at least 2 release to be able to rollback the last release!"
      puts releases
    end
  end
  
  def prefix
    "#{APP}_#{TARGET}_release-"
  end
  
  def app_and_target
    "#{APP} (#{TARGET})"
  end
  
  def delete_tagged_version(release_name)
    timed do
      puts `git tag -d #{release_name}`
      puts `git push git@heroku.com:#{APP}.git :refs/tags/#{release_name}`
      GIT_REPOS.each { |r| puts `git push #{r} :refs/tags/#{release_name}` }
    end
  end
  
  def tag_and_push_release(release_name)
    timed do
      puts "\nTagging release as '#{release_name}'"
      puts `git tag -a #{release_name} -m "Heroku's tagged release"`
      puts `git push --tags git@heroku.com:#{APP}.git`
      GIT_REPOS.each { |r| puts `git push --tags #{r}` }
    end
  end
end