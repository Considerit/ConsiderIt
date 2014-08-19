namespace :tenants do
  desc "Based on tenant info from Proposals, Points, Opinions, update account_id on all associated records"  
  task :update_associated => :environment do
    Account.find_each do |accnt|
      accnt.proposals.each do |prop|
        prop.inclusions.update_all(:account_id => accnt.id)
        prop.point_listings.update_all(:account_id => accnt.id)
        prop.domain_maps.update_all(:account_id => accnt.id) 

      end

      accnt.points.each do |pnt|
        pnt.comments.update_all(:account_id => accnt.id)        
        pnt.comments.each do |comment|
          comment.reflect_bullets.update_all(:account_id => accnt.id)
          #comment.reflect_bullet_revisions.update_all(:account_id => accnt.id)
          comment.reflect_bullets.each do |brev|
            brev.revisions.update_all(:account_id => accnt.id)
            #if brev.user && brev.user.account_id.nil?
            #  User.update(brev.user_id, :account_id => accnt.id)
            #end
            brev.highlights.update_all(:account_id => accnt.id) 
            brev.responses.update_all(:account_id => accnt.id)
           
          end
        end
      end
    end
  end

  task :duplicate_users_with_multiple_tenant_activity => :environment do
    tables = [Proposal,Point,Comment,Reflect::ReflectBulletRevision,Inclusion,Opinion]
    tables_to_update = [
      'proposals', 'positions', 'points', 'inclusions', 'reflect_bullet_revisions', 'reflect_response_revisions',
      'point_listings', 'comments', 'activities']

    User.find_each do |u|
      accounts = []
      tables.each do |tbl|
        result = tbl.select('DISTINCT account_id').where(:user_id => u.id)
        if result.length > 0
          distinct_ids = result.map {|x| x.account_id}.compact
          accounts |= distinct_ids
        end
      end

      if accounts.length == 0
        next
      end

      ActiveRecord::Base.connection.execute("update users u set account_id=#{accounts[0]} where id=#{u.id}")
      if accounts.length > 1

        accounts[1..accounts.length].each do |accnt|
          # duplicate user and insert
          # update all actions and dependents to reflect new user_id (actions, points, comments...)
          pp "Creating User #{u.name}<#{u.email}> for account #{accnt}"
          new_user = u.dup
          new_user.account_id = accnt
          new_user.skip_confirmation!
          new_user.save!

          tables_to_update.each do |tbl|
            ActiveRecord::Base.connection.execute("UPDATE #{tbl} SET user_id=#{new_user.id} WHERE user_id=#{u.id} AND account_id=#{accnt}")
          end

        end

      end

    end

  end


end