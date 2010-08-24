namespace :deploy do
  
  desc "Prepare jammit assets before deploy"
  task :assets do
    system "bundle exec jammit -u #{HerokuTasks.production_url} -f"
    
    files = ["public/assets/style.css","public/assets/style-datauri.css","public/assets/style-mhtml.css"]
    files.each do |file|
      buffer = File.new(file,'r').read.gsub(/@media screen and\(/,"@media screen and (")
      File.open(file,'w') {|fw| fw.write(buffer)}
    end
    
    system "git add public/assets/*"
    system "git commit public/assets/* -m 'Updated assets before deploy'"
  end
  
  desc "Heroku staging (#{HerokuTasks.staging}) deploy"
  task :staging => [:set_staging_app, :push, :restart, :tag]
  
  namespace :staging do
    desc "Heroku staging (#{HerokuTasks.staging}) deploy with migration (and copy production db)"
    task :migrations => [:set_staging_app, :push, :copy_production_db, :migrate, :restart, :tag]
    desc "Heroku staging (#{HerokuTasks.staging}) rollback"
    task :rollback => [:set_staging_app, :rollback, :restart]
  end
  
  desc "Heroku production (#{HerokuTasks.production}) deploy"
  task :production => [:set_production_app, :push, :restart, :tag]
  
  namespace :production do
    desc "Heroku production (#{HerokuTasks.staging}) deploy with migration"
    task :migrations => [:set_production_app, :push, :migrate, :restart, :tag]
    desc "Heroku production (#{HerokuTasks.staging}) rollback"
    task :rollback => [:set_production_app, :rollback, :restart]
  end
  
  # =======================
  # = Don't call directly =
  # =======================
  
  task :set_staging_app do
    APP    =  HerokuTasks.staging
    TARGET = 'staging'
  end
  task :set_production_app do
    APP    =  HerokuTasks.production
    TARGET = 'production'
  end
  
  task :push do
    timed do
      puts "\nDeploying #{TARGET}'s branch to #{APP} on heroku ..."
      system "git push git@heroku.com:#{APP}.git #{TARGET}:master"
    end
  end
  
  task :restart do
    timed do
      puts "\nRestarting #{app_and_target} servers ..."
      system "heroku restart --app #{APP}"
    end
  end
  
  task :tag do
    tag_and_push_release("#{prefix}#{normalized_date}")
  end
  
  task :migrate do
    timed do
      puts "\nRunning database migrations for #{app_and_target} ..."
      system "heroku rake db:migrate --app #{APP}"
    end
  end
  
  task :copy_production_db do
    timed do
      puts "\nCopying production database for #{app_and_target} ..."
      system "heroku db:pull sqlite://backup.db --app #{HerokuTasks.production}"
      system "heroku db:push sqlite://backup.db --app #{APP}"
    end
  end
  
  task :rollback do
    releases = `git tag`.split("\n").select { |t| t[0..prefix.length-1] == prefix }.sort
    
    if releases.length >= 2
      current_release  = releases.last
      previous_release = releases[-2]
      
      started_at = Time.now.utc
      puts "\nRolling back to '#{previous_release}' ..."
      
      puts "\nChecking out '#{previous_release}' in a new branch on local git repo ..."
      system "git checkout #{previous_release}"
      system "git checkout -b #{previous_release}"
      
      puts "\nRemoving tagged version '#{previous_release}' (now transformed in branch) ..."
      delete_tagged_version(previous_release)
      
      puts "\nPushing '#{previous_release}' to #{APP} on heroku/master ..."
      system "git push git@heroku.com:#{APP}.git +#{previous_release}:master --force"
      puts "Done"
      
      puts "\nDeleting rollbacked release '#{current_release}' ..."
      delete_tagged_version(current_release)
      
      puts "\nRetagging release '#{previous_release}' ..."
      tag_and_push_release(previous_release)
      
      puts "\nTurning local repo checked out on master ..."
      system "git checkout master"
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
      system "git tag -d #{release_name}"
      system "git push git@heroku.com:#{APP}.git :refs/tags/#{release_name}"
      system "git push #{HerokuTasks.git_repo} :refs/tags/#{release_name}"
    end
  end
  
  def tag_and_push_release(release_name)
    timed do
      puts "\nTagging release as '#{release_name}'"
      system "git tag -a #{release_name} -m \"Heroku's tagged release\""
      system "git push --tags git@heroku.com:#{APP}.git"
      system "git push --tags #{HerokuTasks.git_repo}"
    end
  end
  
  def normalized_date
    Time.now.utc.strftime("%Y%m%d%H%M%S")
  end
  
  def timed(&block)
    if block_given?
      start_time = Time.now.utc
      yield
      print "\tDone in #{Time.now.utc - start_time}s!\n\n"
    else
      print "\n\nYou must pass a block to this method!\n\n"
    end
  end
  
end