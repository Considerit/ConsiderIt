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

namespace :alerts do
  task :check_moderation => :environment do
    Subdomain.all.each do |subdomain| 
      next if subdomain.classes_to_moderate.length == 0 

      # Find out how many objects need to be moderated
      # TODO: this section is copied from moderation_controller#index ... refactor
      content_to_moderate = false

      subdomain.classes_to_moderate.each do |moderation_class|

        if moderation_class == Comment
          # select all comments of points of active proposals
          qry = "SELECT c.id, c.user_id, prop.id as proposal_id FROM comments c, points pnt, proposals prop WHERE prop.subdomain_id=#{subdomain.id} AND prop.active=1 AND prop.id=pnt.proposal_id AND c.point_id=pnt.id"
        elsif moderation_class == Point
          qry = "SELECT pnt.id, pnt.user_id, pnt.proposal_id FROM points pnt, proposals prop WHERE prop.subdomain_id=#{subdomain.id} AND prop.active=1 AND prop.id=pnt.proposal_id AND pnt.published=1"
        elsif moderation_class == Proposal
          qry = "SELECT id, slug, user_id, name, description from proposals where subdomain_id=#{subdomain.id}"
        else
          raise "Can't handle moderation type"
        end

        objects = ActiveRecord::Base.connection.exec_query(qry)

        existing_moderations = Moderation.where("moderatable_type='#{moderation_class.name}' AND moderatable_id in (?)", objects.map {|o| o['id']})

        if existing_moderations.count < objects.count || existing_moderations.where('status IS NULL OR updated_since_last_evaluation=1').count > 0
          content_to_moderate = true
          break
        end

      end

      #######

      if content_to_moderate
        # send to all users with moderator status
        roles = subdomain.user_roles()
        moderators = roles.has_key?('moderator') ? roles['moderator'] : []

        moderators.each do |key|
          begin
            user = User.find(key_id(key))
          rescue
          end
          if user && !!(user.email && user.email.length > 0 && !user.email.match('\.ghost') && !user.no_email_notifications)
            AdminMailer.content_to_moderate(user, subdomain).deliver_now
          end
        end
      end
    end
  end
end