namespace :migrations do

   # - prefer LVG
   #    - lose avatar & tags of users being incorporated
   # - copy over third party auth uids too
   # - update user fields of all objects (copy from user/opinion absorb)
   # - delete old users
   # - split out roles
   #    - extract roles and put them on the subdomain object

  task :untenant_users => :environment do
    def update_active_in(user, target_user)
      if !target_user.active_in 
        target_user.active_in = JSON.dump ["#{user.account_id}"]
      else
        active_accounts = JSON.parse(target_user.active_in)
        if !active_accounts.include?("#{user.account_id}")
          active_accounts.push("#{user.account_id}")
          target_user.active_in = JSON.dump active_accounts
        end
      end
      target_user.save

    end

    def update_role(user, target_user)
      begin 
        account = Account.find(user.account_id)
      rescue
        pp 'ERROR, couldnt get account', user
        return
      end
      
      if !account.roles
        account.roles = JSON.dump({moderator: [], evaluator: [], admin: []})
      end

      roles = JSON.parse(account.roles)

      if ['tkriplean@gmail.com', 'toomim@gmail.com', 'kminiter@gmail.com'].include?(user.email)
        target_user.super_admin = true
      end

      user_key = "/user/#{target_user.id}"

      if (user.roles_mask == 32 || user.roles_mask == 36) && !roles['evaluator'].include?(user_key)
        roles['evaluator'].push user_key
      end

      if [10,30,12,28].include?(user.roles_mask) && !['admin@livingvotersguide.org', 'eekim@eekim.com'].include?(user.email)  && !roles['moderator'].include?(user_key)
        roles['moderator'].push user_key
      end

      if [2,10,30].include?(user.roles_mask) && !['admin@livingvotersguide.org'].include?(user.email) && !roles['admin'].include?(user_key)
        roles['admin'].push user_key
      end

      # pp account.identifier, email, roles
      account.roles = JSON.dump roles
      account.save

      update_active_in user, target_user

      target_user.save

    end


    u = User.group('email').count
    duplicated_emails = u.keys.reject {|e| u[e] == 1 || !e}
    pp duplicated_emails

    duplicated_emails.each do |email|
      lvg_user = User.where(:account_id => 1, :email => email).first
      if lvg_user
        canonical_user = lvg_user
      else
        canonical_user = User.find_by_email(email)
      end

      User.where(:email => email).each do |user|
        next if user.id == canonical_user.id
        next if Account.where(:id => user.account_id).count == 0

        pp "Updating #{email} fields"
        # update users fields to canonical
        for table in [Point, Proposal, Inclusion, Opinion, Follow, Comment, Follow, Moderation, PageView ] 
          table.where(:user_id => user.id).update_all(user_id: canonical_user.id)
        end
        Log.where(:who => user.id).update_all(who: canonical_user.id)

        # copy third party auth uids to canonical if not conflicting
        [:google_uid, :twitter_uid, :facebook_uid].each do |uid|
          if !canonical_user[uid] && user[uid]
            canonical_user[uid] = user[uid] 
            pp 'Added canonical', uid, email
          end
        end

        # extract roles to subdomain
        if user.roles_mask > 0 
          update_role(user, canonical_user)
        end

        canonical_user.save
        user.destroy
        #pp canonical_user



      end
    end

    # update roles for everyone!
    User.where('roles_mask > 0').each do |user|
      update_role(user, user)
    end

    User.where(:registration_complete => true).find_each do |user|
      update_active_in user, user
    end

  end
end