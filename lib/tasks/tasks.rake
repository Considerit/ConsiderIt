namespace :cache do
  desc "Update cache"
  task :points => :environment do
    begin
      Point.update_scores()
      Rails.logger.info "Updated point scores"
    rescue
      Rails.logger.info "Could not update point scores"
    end 
  end

  # task :proposals => :environment do
  #   begin
  #     Proposal.update_scores
  #     Rails.logger.info "Updated proposal scores"
  #   rescue
  #     Rails.logger.info "Could not update proposal scores"
  #   end
  # end

  # task :users => :environment do
  #   # compute influence score
  #   User.update_user_metrics()
  # end
end

task :compute_metrics => ["cache:points"]

# For a weird bug we can't figure out that leaves an 
# inclusion without an associated point. 
# Remove this after we have a decent caching method for inclusions
task :clear_null_inclusions => :environment do
  Inclusion.where(:point_id => nil).destroy_all
end