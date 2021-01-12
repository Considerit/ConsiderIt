module Invitations
  def process_and_send_invitations(roles, invitations, target)

    
    invitations.each do |invite|
      message = invite['message'] && invite['message'].length > 0 ? invite['message'] : nil
      users_with_role = roles[invite['role']]

      invites = invite['keys_or_emails']
      if !invites
        invites = []
      end

      invites.each do |user_or_email|
        next if user_or_email.index('*') # wildcards; no invitations!!
          
        if user_or_email[0] == '/'
          invitee = User.find(key_id(user_or_email))

        else 
          # check to make sure this user doesn't already have an account... 
          invitee = User.find_by_email(user_or_email)
          if !invitee
            # every invited & fully specified email address who doesn't yet have an account will have one created for them
            invitee = User.create!({
              :name => user_or_email.split('@')[0],
              :email => user_or_email,
              :registered => true,
              :complete_profile => true,
              :password => SecureRandom.base64(15).tr('+/=lIO0', 'pqrsxyz')[0,20] #temp password
            })

            # replace email address with the user's key in the roles hash

            users_with_role[users_with_role.index(user_or_email)] = "/user/#{invitee.id}" 
          end

        end
        invitee.add_to_active_in        
        UserMailer.invitation(current_user, invitee, target, invite['role'], current_subdomain, message).deliver_later

      end
    end

    roles
  end
end
