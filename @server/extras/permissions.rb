############################################################
###################### PERMISSIONS #########################
#
# Server permissions
#
# Unfortunately, much of this logic has to be replicated 
# on the client. See 
#         @client/permissions.coffee
# If you're changing the logic
# in one place, you may need to do so in the other as
# well. However, not all server logic needs to be here
# and vice versa.
#


# Permission cases ENUM
# This needs to be synchronized with client (see @client/permissions.coffee).
# Failure cases should be less than 0.
module Permission
  PERMITTED = 1
  DISABLED = -1 # no one can take this action
  UNVERIFIED_EMAIL = -2 # can take action once email is verified 
  NOT_LOGGED_IN = -3 # not sure if action can be taken
  INSUFFICIENT_PRIVILEGES = -4 # we know this user can't do this

end

module Permitted
  def self.matchEmail(permission_list, user=nil)
    user ||= current_user
    return true if permission_list.index('*')
    return true if permission_list.index(user.key)
    return true if permission_list.index(user.email)
    permission_list.each do |email_or_key| 
      if email_or_key.index('*')
        allowed_domain = email_or_key.split('@')[1]
        next if !user.email
        return true if user.email.split('@')[1] == allowed_domain
      end
    end
    return false
  end

  def self.matchSomeRole(roles, accepted_roles, user=nil)
    user ||= current_user

    accepted_roles.each do |role|
      return true if matchEmail(roles[role], user)
    end
    return false
  end


end

class PermissionDenied < StandardError
  attr_reader :reason, :key
  def initialize(reason, key = nil)
    @reason = reason
    @key = key
  end
end



# TODO: 
#   extend interface to allow for passing user and subdomain so that
#   permit interface can be used for offline processing, such as 
#   the notifications subsystem.
def permit(action, object = nil, user = nil)

  user ||= current_user
  if object && object.class.name == 'Subdomain'
    subdomain = object
  else 
    subdomain = current_subdomain
  end

  return Permission::PERMITTED if user.super_admin

  case action
  when 'create subdomain'
    return Permission::NOT_LOGGED_IN if !user.registered

  when 'update subdomain'
    return Permission::NOT_LOGGED_IN if !user.registered
    return Permission::INSUFFICIENT_PRIVILEGES if !user.is_admin?(subdomain)

  when 'delete subdomain'
    return Permission::NOT_LOGGED_IN if !user.registered
    return Permission::INSUFFICIENT_PRIVILEGES if !user.is_admin?(subdomain)
    return Permission::UNVERIFIED_EMAIL if !user.verified  

  when 'create proposal'
    return Permission::NOT_LOGGED_IN if !user.registered
    if !user.is_admin?(subdomain) && !Permitted::matchEmail(subdomain.user_roles['proposer'], user)
      return Permission::INSUFFICIENT_PRIVILEGES 
    end

  when 'read proposal', 'access forum'
    if !user.is_admin?(subdomain) && !Permitted::matchSomeRole(subdomain.user_roles, ['visitor'], user) 
      if !user.registered
        return Permission::NOT_LOGGED_IN 
      else
        return Permission::INSUFFICIENT_PRIVILEGES 
      end
    elsif !subdomain.user_roles['visitor'].index('*')
      if !user.registered
        return Permission::NOT_LOGGED_IN 
      elsif !user.verified
        return Permission::UNVERIFIED_EMAIL
      end
    end

  when 'update proposal', 'delete proposal'
    proposal = object

    can_read = permit('read proposal', object)
    return can_read if can_read < 0

    return Permission::NOT_LOGGED_IN if !user.registered

    if !user.is_admin?(subdomain) && !Permitted::matchEmail(proposal.user_roles['editor'], user)
      return Permission::INSUFFICIENT_PRIVILEGES
    end

  when 'set category'
    list_key = "list/#{object}"
    customizations = subdomain.customization_json()
    if customizations.has_key?(list_key) && customizations[list_key].has_key?("list_permit_new_items")
      allowed = customizations[list_key]["list_permit_new_items"]
    else
      allowed = permit('create proposal')
    end

    if !allowed 
      return Permission::INSUFFICIENT_PRIVILEGES
    end

  when 'read opinion'
    opinion = object
    return permit 'read proposal', opinion.proposal

  when 'publish opinion'
    proposal = object
    return Permission::DISABLED if !proposal.active
    return Permission::NOT_LOGGED_IN if !user.registered
    if !user.is_admin?(subdomain) && !Permitted::matchSomeRole(proposal.user_roles, ['editor', 'writer', 'opiner'], user)
      return Permission::INSUFFICIENT_PRIVILEGES
    end

  when 'update opinion', 'delete opinion'
    opinion = object
    
    can_read = permit 'read opinion', opinion
    return can_read if can_read < 0
    return Permission::INSUFFICIENT_PRIVILEGES if user.id != opinion.user_id

  when 'read point'
    point = object

    if user.id != point.user_id && !user.is_admin?(subdomain)
      return Permission::DISABLED if point.published && !(point.moderation_status.nil? || point.moderation_status != 0)
    end

  when 'create point'
    proposal = object
    return Permission::DISABLED if !proposal.active

    if !user.is_admin?(subdomain) && !Permitted::matchSomeRole(proposal.user_roles, ['editor', 'writer'], user)
      if !user.registered
        return Permission::NOT_LOGGED_IN  
      else 
        return Permission::INSUFFICIENT_PRIVILEGES 
      end
    end

  when 'update point'
    point = object
    if !user.is_admin?(subdomain) && user.id != point.user_id
      return Permission::INSUFFICIENT_PRIVILEGES 
    end

  when 'delete point'
    point = object
    if !user.is_admin?(subdomain)
      return Permission::INSUFFICIENT_PRIVILEGES if user.id != point.user_id
      return Permission::DISABLED if point.inclusions.count > 1
    end

  when 'read comment'
    comment = object
    return permit('read point', comment.point)

  when 'create comment'
    comment = object
    point = comment.point
    proposal = point.proposal

    return Permission.DISABLED if !proposal.active
    return Permission::NOT_LOGGED_IN if !user.registered
  
    if !user.is_admin?(subdomain) && !Permitted::matchSomeRole(proposal.user_roles, ['editor', 'writer', 'commenter'], user)
      return Permission::INSUFFICIENT_PRIVILEGES
    end

  when 'update comment', 'delete comment'
    comment = object
    can_read = permit 'read comment', comment
    return can_read if can_read < 0

    if !user.is_admin?(subdomain) && user.id != comment.user_id
      return Permission::INSUFFICIENT_PRIVILEGES 
    end

  when 'update user'
    if !user.is_admin?(subdomain)
      return Permission::INSUFFICIENT_PRIVILEGES 
    end

  when 'moderate content'
    return Permission::NOT_LOGGED_IN if !user.registered
    return Permission::INSUFFICIENT_PRIVILEGES if !user.has_any_role?([:admin, :superadmin, :moderator])
    return Permission::UNVERIFIED_EMAIL if !user.verified  

  when 'update all translations'
    return Permission::INSUFFICIENT_PRIVILEGES if !user.super_admin
  else
    raise "Undefined Permission: #{action}"
  end



  # puts "#{user.name} is permitted to #{action}"

  return Permission::PERMITTED
end