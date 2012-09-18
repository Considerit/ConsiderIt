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

namespace :alerts do
  #TODO: do this in a way that doesn't effectively resend the same email
  task :check_moderation => :environment do
    Account.all.each do |accnt|
      ApplicationController.set_current_tenant_to(accnt)
      # check if any outstanding moderations (just look at counts using unique ids)
      content_to_moderate = 0
      Moderatable::Moderation.classes_to_moderate.each do |mc|
        content_to_moderate += mc.moderatable_objects.call.where(:account_id => accnt.id).count - Moderatable::Moderation.select('DISTINCT (moderatable_type, moderatable_id)').where(:moderatable_type => mc.name, :account_id => accnt.id).count
      end
      if content_to_moderate > 0
        # send to all users with moderator status
        moderators = []
        accnt.users.where('roles_mask > 0').each do |u|
          if u.has_any_role? :moderator, :admin, :superadmin
            moderators.push(u)
          end
        end
        moderators.each do |user|
          AlertMailer.content_to_moderate(user, accnt)
        end
      end
    end
  end
end