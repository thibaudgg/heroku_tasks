namespace :assets do
  desc "Prepare assets before deploy"
  task :prepare do
    
    %x[bundle exec jammit -u http://empty-warrior-43.heroku.com -f]
        
    files = ["public/assets/style.css","public/assets/style-datauri.css","public/assets/style-mhtml.css"]
    
    files.each do |file|
      buffer = File.new(file,'r').read.gsub(/@media screen and\(/,"@media screen and (")
      File.open(file,'w') {|fw| fw.write(buffer)}
    end
  end
end