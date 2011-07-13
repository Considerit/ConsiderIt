namespace :cache do
  desc "Update cache"
  task :points => :environment do
    #begin
      Point.update_relative_scores()
    #rescue
      Rails.logger.info "Could not update scores"
    #end    
  end
  
  task :all => [:points] do
    Rails.logger.info "**** RAKE *****\nUpdated cache\n***********"
  end

end