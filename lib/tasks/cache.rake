namespace :cache do
  desc "Update cache"
  task :points => :environment do
    begin
      Point.update_relative_scores()
    rescue
      Rails.logger.info "Could not update point scores"
    end    
  end

  task :proposals => :environment do
    begin
      Proposal.update_scores
    rescue
      Rails.logger.info "Could not update proposal scores"
    end
  end
  
  task :all => [:points, :proposals] do
    Rails.logger.info "**** RAKE *****\nUpdated cache\n***********"
  end

end