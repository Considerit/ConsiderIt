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

  task :avatars => :environment do 
    beginning_time = Time.now
    ttime = 0


    size = 'small'
    #TODO: do not automatically replace each file ... check hash at end for equality
    begin
      Subdomain.find_each do |accnt|
        internal = Rails.application.config.action_controller.asset_host.nil?
        File.open("public/system/cache/#{accnt.identifier}.css", 'w') do |f|

          accnt.users.select([:id,:avatar_file_name]).where('avatar_file_name IS NOT NULL').each do |user|
            #data = [File.read("public/system/avatars/#{user.id}/small/#{user.avatar_file_name}")].pack('m')
            begin

              img_path = "/system/avatars/#{user.id}/#{size}/#{user.avatar_file_name}".gsub(' ', '_')

              if internal
                img_data = File.read("public#{img_path}")
              else
                i_time = Time.now
                img_data = open(URI.parse("http:#{Rails.application.config.action_controller.asset_host}#{img_path}")).read
                ttime += (Time.now - i_time)*1000
              end

              data = Base64.encode64(img_data)
              f.puts("#avatar-#{user.id} { background-image: url(\"data:image/jpeg;base64,#{data.gsub(/\n/," ")}\"); }")
            rescue
              Rails.logger.info "Could not generate avatar #{user.id}"
            end
            #avatars[:small][user.id] = "data:image/jpg;base64,#{data}"
          end
        end
        # TODO: upload resulting cached avatar file if assethost is s3 (can we add digest to it and serve through asset pipeline?)
      end
    rescue
      Rails.logger.info "Could not regenerate avatars"
    end

    end_time = Time.now
    puts "Time elapsed #{(end_time - beginning_time)*1000} milliseconds"
    puts "In big block #{ttime} milliseconds"


  end
end

#task :compute_metrics => ["cache:points", "cache:proposals", "cache:users"]

task :compute_metrics => ["cache:points"]

namespace :alerts do
  task :check_moderation => :environment do
    Subdomain.all.each do |accnt| 
      next if accnt.classes_to_moderate.length == 0 

      # Find out how many objects need to be moderated
      # TODO: this section is copied from moderation_controller#index ... refactor
      content_to_moderate = false

      accnt.classes_to_moderate.each do |moderation_class|

        if moderation_class == Comment
          # select all comments of points of active proposals
          qry = "SELECT c.id, c.user_id, prop.id as proposal_id FROM comments c, points pnt, proposals prop WHERE prop.subdomain_id=#{accnt.id} AND prop.active=1 AND prop.id=pnt.proposal_id AND c.point_id=pnt.id"
        elsif moderation_class == Point
          qry = "SELECT pnt.id, pnt.user_id, pnt.proposal_id FROM points pnt, proposals prop WHERE prop.subdomain_id=#{accnt.id} AND prop.active=1 AND prop.id=pnt.proposal_id AND pnt.published=1"
        elsif moderation_class == Proposal
          qry = "SELECT id, long_id, user_id, name, description from proposals where subdomain_id=#{accnt.id}"
        end

        objects = ActiveRecord::Base.connection.select(qry)

        existing_moderations = Moderation.where("moderatable_type='#{moderation_class.name}' AND moderatable_id in (?)", objects.map {|o| o['id']})

        if existing_moderations.count < objects.count || existing_moderations.where('status IS NULL OR updated_since_last_evaluation=1').count > 0
          content_to_moderate = true
          break
        end

      end

      #######

      if content_to_moderate
        # send to all users with moderator status
        roles = accnt.user_roles()
        moderators = roles.has_key?('moderator') ? roles['moderator'] : []

        moderators.each do |key|
          begin
            user = User.find(key_id(key))
          rescue
          end
          if user
            AlertMailer.content_to_moderate(user, accnt).deliver!
          end
        end
      end
    end
  end
end