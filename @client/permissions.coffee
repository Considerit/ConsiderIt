############################################################
###################### PERMISSIONS #########################
#
# We support two different methods of handling permissions.
#    1. Use the AccessControlled mixinAccess for putting a 
#       barrier on a url/Page.
#    2. For finer grained control, like for whether to show 
#       a button, use the permissions API (permit and 
#       recourse) as needed.
#
# Unfortunately we have to replicate server logic for some
# permissions checks. We try to keep these checks in this 
# file and in:
#       @server/permissions.rb 
# on the server, to manage this unfortunate circumstance. 
# If you're changing the logic in one place, you may need 
# to do so in the other as well. However, not all server 
# logic needs to be here and vice versa.
#

require './browser_location' # for loadPage
require './customizations'


####
# Failure cases ENUM
# This needs to be synchronized with server (see @server/permissions.rb)
# Failure cases should be less than 0.
Permission = 
  PERMITTED: 1
  DISABLED : -1  # no one can take this action
  UNVERIFIED_EMAIL : -2 # can take action once email is verified 
  NOT_LOGGED_IN : -3 # not sure if action can be taken
  INSUFFICIENT_INFORMATION : -5 # this user hasn't divulged enough 
                                # information to take this action
  INSUFFICIENT_PRIVILEGES: -4 # we know this user can't do this



#######################
## Permission Definitions

# permit accepts an action parameter and a list of relevant objects
# for checking whether that action is permitted.
# 
# It returns a value from Permission indicating the result of the 
# permission check.
permit = (action) ->
  current_user = fetch '/current_user'

  switch action
    when 'create proposal'
      subdomain = fetch '/subdomain'

      if !current_user.is_admin && !matchEmail(subdomain.roles.proposer)
        return Permission.INSUFFICIENT_PRIVILEGES 
      return Permission.NOT_LOGGED_IN if !current_user.logged_in

    when 'update proposal', 'delete proposal'
      return Permission.NOT_LOGGED_IN if !current_user.logged_in

      proposal = fetch arguments[1]
      if !current_user.is_admin && (proposal.key == 'new_proposal' || !matchEmail(proposal.roles.editor) )
        return Permission.INSUFFICIENT_PRIVILEGES

    when 'publish opinion'
      proposal = fetch arguments[1]
      subdomain = fetch '/subdomain'

      return Permission.DISABLED if !proposal.active
      return Permission.NOT_LOGGED_IN if !current_user.logged_in

      if !current_user.is_admin && !matchSomeRole(proposal.roles, ['editor', 'writer', 'opiner'])
        return Permission.INSUFFICIENT_PRIVILEGES 

      required_info = _.pluck _.where(customization('auth.user_questions'), {required: true}), 'tag' 
      existing_required_info = _.intersection required_info, _.keys(current_user.tags)

      if existing_required_info.length != required_info.length
        return Permission.INSUFFICIENT_INFORMATION

    when 'update opinion'
      proposal = fetch arguments[1]
      opinion = fetch arguments[2]

      return Permission.INSUFFICIENT_PRIVILEGES if opinion.user != fetch('/current_user').user
        

    when 'create point'
      proposal = fetch arguments[1]
      return Permission.DISABLED if !proposal.active
      if !current_user.is_admin && !matchSomeRole(proposal.roles, ['editor', 'writer'])
        if !current_user.logged_in
          return Permission.NOT_LOGGED_IN  
        else 
          return Permission.INSUFFICIENT_PRIVILEGES 

    when 'update point'
      # Is an author allowed to edit a point after someone else has included it?
      point = fetch arguments[1]
      if !current_user.is_admin && point.user != fetch('/current_user').user
        return Permission.INSUFFICIENT_PRIVILEGES

    when 'delete point'
      point = fetch arguments[1]
      if !current_user.is_admin
        if point.user != fetch('/current_user').user
          return Permission.INSUFFICIENT_PRIVILEGES

        # Allow the point author to delete this point before it is published.
        # After it gets published, however, it can influence other people, so the author shouldn't be able to delete.
        # They can just remove it from their list if they don't believe it anymore. 
        if point.includers.length > 1 || (point.includers.length == 1 && point.includers[0] != current_user.user)
          return Permission.DISABLED

    when 'create comment'
      proposal = fetch arguments[1]
      return Permission.DISABLED if !proposal.active
      return Permission.NOT_LOGGED_IN if !current_user.logged_in 

      if !current_user.is_admin && !matchSomeRole(proposal.roles, ['editor', 'writer', 'commenter'])
        return Permission.INSUFFICIENT_PRIVILEGES 

    when 'update comment'
      comment = fetch arguments[1]
      if !current_user.is_admin && comment.user != fetch('/current_user').user
        return Permission.INSUFFICIENT_PRIVILEGES

    when 'request factcheck'
      proposal = fetch arguments[1]
      return Permission.DISABLED if !proposal.assessment_enabled || !proposal.active
      return Permission.NOT_LOGGED_IN if !current_user.logged_in 

    else
      console.error "Unrecognized action to permit: #{action}"

  return Permission.PERMITTED

matchEmail = (permission_list) -> 
  user = fetch '/current_user'
  return true if '*' in permission_list
  return true if user.user in permission_list
  for email_or_key in permission_list
    if email_or_key.indexOf('*') > -1
      if user.email
        allowed_domain = email_or_key.split('@')[1]
        return true if user.email.split('@')[1] == allowed_domain
  return false

matchSomeRole = (roles, accepted_roles) ->
  for role in accepted_roles
    return true if matchEmail(roles[role])
  return false

window.recourse = (permission, goal) ->
  goal = goal || 'access this page'
  
  switch permission

    when Permission.INSUFFICIENT_PRIVILEGES
      loadPage '/'

    when Permission.NOT_LOGGED_IN
      reset_key 'auth', {form: 'login', goal: goal}

    when Permission.UNVERIFIED_EMAIL
      reset_key 'auth', {form: 'verify email', goal: goal}

      current_user = fetch '/current_user'
      current_user.trying_to = 'send_verification_token'
      save current_user


####
# AccessControlled
#
# Mixin that implements a check for whether this user can access
# this Page (a component that this is mixed into). 
#
# The server has to respond with
# a keyed object w/ permission_denied set for the component's key 
# for this mixin to be useful.
#
# Note that the component needs to explicitly call the accessGranted method
# in its render function. With something like:
#     return SPAN(null) if !@accessGranted()
#
AccessControlled = 
  accessGranted: -> 
    current_user = fetch '/current_user'

    ####
    # HACK: Clear out statebus if current_user changed. See comment below.
    local_but_not_component_unique = fetch "local-#{@page.key}"
    access_attrs = ['verified', 'logged_in', 'email']
    if local_but_not_component_unique._last_current_user && @data().permission_denied
      if @_relevant_current_user_values_have_changed(access_attrs)
        delete @data().permission_denied
        arest.serverFetch @page.key
    ####


    if @data().permission_denied && @data().permission_denied < 0
      # Let's recover, depending on the recourse the server dictates
      recourse @data().permission_denied

    #######
    # Hack! The server will return permission_denied on the page, e.g.: 
    # 
    #   { key: '/page/dashboard/moderate', permission_denied: 'login required' }
    # 
    # Here's a problem: 
    # What happens if the user logs in? Or if they verify their email?
    # We will need to refetch that page on the server so we can proceed 
    # with the proper data and without the access denied error.
    #
    # My solution here is to store relevant values of /current_user the last time
    # an access denied error was registered. Then everytime one of those attributes
    # changes (i.e. when the user might be able to access), we'll issue a server
    # fetch on the page.
    #
    if @_relevant_current_user_values_have_changed(access_attrs)
      local_but_not_component_unique._last_current_user = _.map access_attrs, (attr) -> current_user[attr] 
      save local_but_not_component_unique

    #
    # This hack will be unnecessary by having a server that pushes out changes to 
    # subscribed keys. In that world, the server logs a dependency for a client 
    # on an access-controlled resource. If the client ever gains the proper 
    # authorization, the server can just push down the data.

    return !@data().permission_denied || @data().permission_denied > 0
  
  _relevant_current_user_values_have_changed: (access_attrs) ->
    current_user = fetch '/current_user' 
    last_values = fetch "local-#{@page.key}"

    reduced_user = _.map access_attrs, (attr) -> current_user[attr] 
    for el,idx in reduced_user
      if !last_values._last_current_user || el != last_values._last_current_user[idx]
        return true
    return false


#######################
## Exports

window.AccessControlled = AccessControlled
window.permit = permit
window.Permission = Permission




