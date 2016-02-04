task :compute_metrics => :environment do 
  begin
    Point.update_scores()
    Rails.logger.info "Updated point scores"
  rescue
    Rails.logger.info "Could not update point scores"
  end 
end

# For a weird bug we can't figure out that leaves an 
# inclusion without an associated point. 
# Remove this after we have a decent caching method for inclusions
task :clear_null_inclusions => :environment do
  Inclusion.where(:point_id => nil).destroy_all
end