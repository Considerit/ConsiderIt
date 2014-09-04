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

  task :proposals => :environment do
    begin
      Proposal.update_scores
      Rails.logger.info "Updated proposal scores"
    rescue
      Rails.logger.info "Could not update proposal scores"
    end
  end

  task :users => :environment do
    # compute influence score
    User.update_user_metrics()
  end

  task :avatars => :environment do 
    beginning_time = Time.now
    ttime = 0


    size = 'small'
    #TODO: do not automatically replace each file ... check hash at end for equality
    begin
      Account.find_each do |accnt|
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

task :compute_metrics => ["cache:points", "cache:proposals", "cache:users"]

namespace :alerts do
  task :check_moderation => :environment do
    Account.where(:enable_moderation => true).each do |accnt|

      #ApplicationController.set_current_tenant_to(accnt)

      # Find out how many objects need to be moderated
      # this section is horribly coded and inefficient ... TODO fix
      content_to_moderate = 0
      existing_moderations = {}
      objs_to_moderate = {}

      accnt.classes_to_moderate.each do |mc|

        class_name = mc.name.split('::')[-1]
        existing_moderations[class_name] = {}

        if mc == Comment
          # Assumes Commentable_type is Point!!!
          # select all comments of points of active proposals
          qry = "SELECT c.id, c.user_id FROM comments c, points pnt, proposals prop WHERE prop.account_id=#{accnt.id} AND prop.active=1 AND prop.id=pnt.proposal_id AND c.commentable_id=pnt.id"
        elsif mc == Proposal
          qry = "SELECT id, user_id, name from proposals where account_id=#{accnt.id}"
        elsif mc == Point
          qry = "SELECT pnt.id, pnt.user_id FROM points pnt, proposals prop WHERE prop.account_id=#{accnt.id} AND prop.active=1 AND prop.id=pnt.proposal_id AND pnt.published=1"
        end
        objects = ActiveRecord::Base.connection.select(qry)

        objs_to_moderate[class_name] = objects
        objs = objs_to_moderate[class_name].map{|x| x["id"]}.compact

        records = Moderation.where(:moderatable_type => mc.name, :account_id => accnt.id)
        if objs.length > 0
          records = records.where("moderatable_id in (#{objs.join(',')})")
          records.select([:id, :moderatable_id]).each do |mod|
            existing_moderations[class_name][mod.moderatable_id] = mod
          end
        end

        existing_moderations[class_name] = existing_moderations[class_name].values
        content_to_moderate += objs_to_moderate[class_name].count - existing_moderations[class_name].count

      end

      #######

      if content_to_moderate > 0
        # send to all users with moderator status
        moderators = []
        accnt.users.where('roles_mask > 0').each do |u|
          if u.has_any_role? :moderator #, :admin, :superadmin
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