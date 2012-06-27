namespace :cache do
  desc "Update cache"
  task :points => :environment do
    begin
      Point.update_relative_scores()
      Rails.logger.info "Updated point scores"
    rescue
      Rails.logger.info "Could not update point scores"
    end    
  end

  task :proposals => :environment do
    begin
      Proposal.update_scores
      Rails.logger.info "Updated proposal scores"
    rescue
      Rails.logger.info "Could not update proposal scores"
    end
  end
  

end

task :compute_metrics => ["cache:points", "cache:proposals"]
