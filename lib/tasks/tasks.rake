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
  task :check_moderation => :environment do
    Account.where(:enable_moderation => true).each do |accnt|

      ApplicationController.set_current_tenant_to(accnt)

      # Find out how many objects need to be moderated
      # this section is horribly coded and inefficient ... TODO fix
      content_to_moderate = 0
      Moderatable::Moderation.classes_to_moderate.each do |mc|
        existing = {}
        objs_to_moderate = {}
        if mc == Commentable::Comment
          comments = []
          mc.moderatable_objects.call.each do |comment|
            if comment.commentable_type != 'Point' || comment.root_object.proposal.active 
              comments.push(comment)
            end
          end
          objs_to_moderate = comments.map{|x| x.id}.compact
          records = Moderatable::Moderation.where(:moderatable_type => mc.name)
          if objs_to_moderate.length > 0
            records = records.where("moderatable_id in (#{objs_to_moderate.join(',')})")
          end
        else
          objs_to_moderate = mc.moderatable_objects.call
          records = Moderatable::Moderation.where(:moderatable_type => mc.name)
        end
        records.each do |mod|
          existing[mod.moderatable_id] = mod
        end

        content_to_moderate += objs_to_moderate.length - existing.length
      end
      #######

      if content_to_moderate > 0
        # send to all users with moderator status
        moderators = []
        accnt.users.where('roles_mask > 0').each do |u|
          if u.has_any_role? :moderator, :admin, :superadmin
            moderators.push(u)
          end
        end
        moderators.each do |user|
          AlertMailer.content_to_moderate(user, accnt).deliver!
        end
      end
    end
  end
end