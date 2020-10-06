require './customizations'
require './form'
require './shared'



proposal_roles = -> 
  pro_label = get_point_label 'pro'
  con_label = get_point_label 'con'

  all = [ 
    {
      name: 'editor', 
      label: 'Editors', 
      description: 'Can modify the description of the proposal, as well as ' + \
                   'write, comment, and opine.', 
      wildcard: 
        label: 'Any registered user can edit'
        default: false
    },
    {
      hide: true,
      name: 'writer', 
      label: 'Writers', 
      description: "Can write #{pro_label} and #{con_label} points that are " + \
                   "shared with others. Any writer can comment and opine.", 
      wildcard: 
        label: 'Any registered user who can observe can write'
        default: true
    },{
      hide: true,
      name: 'commenter', 
      label: 'Commenters', 
      description: "Can comment on #{pro_label} and #{con_label} points.", 
      wildcard: 
        label: 'Any registered user who can observe can comment'
        default: true
    },{
      hide: true,
      name: 'opiner', 
      label: 'Opiners', 
      description: 'Can drag the slider and build a list of other people\'s Pros/Cons, but can\'t write new Pros, Cons or Comments.'
      wildcard: 
        label: 'Any registered user who can observe can opine'
        default: true
    },{
      hide: true,
      name: 'observer', 
      label: 'Observers', 
      description: 'Can access this proposal. But that\'s it.', 
      wildcard: 
        label: "Public. Anyone can view"
        default: true
    }
  ]

  all = _.compact all
  all

ProposalRoles = ReactiveComponent
  displayName: 'ProposalRoles'

  render : -> 

    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'

    proposal = fetch @props.key


    # initialize default roles for a new proposal
    if !proposal.roles
      InitializeProposalRoles(proposal)

    SpecifyRoles proposal, proposal_roles()

window.InitializeProposalRoles = (proposal) -> 
  current_user = fetch '/current_user'
  subdomain = fetch '/subdomain'

  proposal.roles = {}
  for role in proposal_roles()
    proposal.roles[role.name] = []
    if role.wildcard && role.wildcard.default
      if role.name == 'observer' 
        # by default, proposals can be accessed by the same folks as the subdomain
        proposal.roles[role.name] = subdomain.roles['visitor'].slice()
      else
        proposal.roles[role.name].push '*'

  proposal.roles['editor'].push "/user/#{current_user.id}" 
                        #default proposal author as editor

SubdomainRoles = ReactiveComponent
  displayName: 'SubdomainRoles'

  render : -> 
    subdomain = fetch '/subdomain'

    roles = [ 
      {
        name: 'admin', 
        label: 'Administrators', 
        description: 'Can configure everything related to this forum.', 
      }, 
      {
        hide: true,
        name: 'moderator', 
        label: 'Moderators', 
        description: 'Can moderate user content. Will receive emails for content needing moderation.', 
      },{
        hide: false,
        name: 'proposer', 
        label: 'Proposers', 
        description: 'Can add new proposals.', 
        wildcard: {label: 'Any registered user can post new proposals', default: true}},
      {
        name: 'visitor', 
        label: 'People who can access forum', 
        description: 'If set to private forum, invite specific people to join below.', 
        wildcard: {label: 'Public forum. Anyone with a link can see all proposals.', default: true}} 
    ]

    roles = _.compact roles

    # Default roles for a new subdomain are currently hardcoded on the server
    # at subdomain_controller#create

    DIV null, 
      DashHeader name: 'User Roles'
      DIV style: {width: HOMEPAGE_WIDTH(), margin: 'auto'},
        SpecifyRoles subdomain, roles


SpecifyRoles = (target, roles) ->  
  DIV null,
    for role in roles when !role.hide
      DIV 
        key: role.name
        style: 
          marginTop: 24

        H2 style: {fontSize: 18, position: 'relative'}, 
          I 
            className: "fa #{role.icon}"
            style: 
              position: 'absolute'
              top: 2
              left: -35
              fontSize: 24
          role.label
        
        SPAN style: {fontSize: 14}, role.description

        UsersWithRole 
          key: role.name
          target: target
          role: role
    
    DIV 
      style: 
        marginLeft: -35
        marginTop: 12

      AddRolesAndInvite 
        key: 'roles_and_invite'
        roles: roles
        target: target


# AddRolesAndInvite is the block at the bottom of roles editing that controls
# adding new roles and sending out invites
AddRolesAndInvite = ReactiveComponent
  displayName: 'Invite'

  render: ->
    target = fetch @props.target
    users = fetch '/users'

    console.log {roles: @props.roles}

    if !@local.role
      @local.added = []
      @local.role = @props.roles[0]
      save @local


    processNewFolks = =>
      $filter = $(@getDOMNode()).find('#filter')
      candidates = $filter.val()
      $filter.val('')
      if candidates
        candidates = candidates.split(',')
        for candidate_email in candidates
          candidate_email = candidate_email.trim()
          if candidate_email.indexOf(' ') < 0 && 
              candidate_email.indexOf('@') > 0 && 
              candidate_email.indexOf('.') > 0
            @local.added.push candidate_email
        save @local


    other_roles = @props.roles
    DIV 
      style: 
        position: 'relative'
        backgroundColor: '#f2f2f2'
        padding: '18px 24px'


      SELECT 
        id: 'select_role'
        type: 'text'
        name: 'select_role'
        defaultValue: 0
        onChange: (event) =>
          role = other_roles[event.target.value]
          @local.role = role 
          save @local

        style: 
          fontSize: 18
          marginBottom: 18
          display: 'inline-block'


        for role,idx in other_roles 
          if !role.hide
            do (role, idx) => 
              OPTION
                value: idx
                "Add #{role.label}"


      # Show everyone queued for being added/invited to a role
      if @local.added.length > 0
        DIV null,
          for user_key, idx in @local.added

            UserWithRole user_key, (user_key) => 
              @local.added = _.without @local.added, user_key
              save @local

      # Text input for adding new people to a role
      DIV 
        ref: 'autocomplete'
        onKeyDown: (e) => 
          if e.which == 27 && @local.selecting # ESC
            @local.selecting = false 
            save @local

        INPUT 
          id: 'filter'
          type: 'text'
          style: {fontSize: 18, width: 350, padding: '3px 6px'}
          autoComplete: 'off'
          placeholder: "Name or email..."
          onChange: => 
            @local.filtered = $(@getDOMNode()).find('#filter').val()
            save(@local)
          onKeyPress: (e) => 
            # enter key pressed...
            if e.which == 13
              e.preventDefault()
              processNewFolks()

          onFocus: (e) => 
            @local.selecting = true
            save(@local)
            e.stopPropagation()
            $(document).on 'click.roles', (e) =>
              if e.target.id != 'filter'
                processNewFolks()                
                @local.selecting = false
                @local.filtered = null
                save @local
                $(document).off('click.roles')
            return false

        # Dropdown, autocomplete menu for adding existing users
        if @local.selecting
          available_users = _.filter users.users, (u) => 
              target.roles[@local.role.name].indexOf(u.key) < 0 && 
              @local.added.indexOf(u.key) < 0 &&
               (!@local.filtered || 
                "#{u.name} <#{u.email}>".indexOf(@local.filtered) > -1)
          if available_users.length > 0
            UL 
              style: 
                width: 500
                position: 'absolute'
                zIndex: 99
                listStyle: 'none'
                backgroundColor: '#fff'
                border: '1px solid #eee'

              for user,idx in available_users
                LI 
                  className: 'invite_menu_item'
                  style: 
                    padding: '2px 12px'
                    fontSize: 18
                    cursor: 'pointer'
                    borderBottom: '1px solid #fafafa'
                  key: idx

                  onClick: do(user) => (e) => 
                    @local.added.push user.key
                    save @local
                    e.stopPropagation()
                  onTouchEnd: do(user) => (e) => 
                    @local.added.push user.key
                    save @local
                    e.stopPropagation()
                  onKeyDown: do(user) => (e) => 
                    if e.which == 13 # ENTER
                      @local.added.push user.key
                      save @local
                      e.stopPropagation()
                      e.preventDefault()

                  "#{user.name} <#{user.email}>"

      # Email invite area
      DIV style: {marginTop: 20},
        INPUT 
          type: 'checkbox'
          id: 'send_email_invite'
          name: 'send_email_invite'
          onClick: =>
            @local.send_email_invite = !@local.send_email_invite
            save @local

        LABEL htmlFor: 'send_email_invite', 'Send email invitation'

        if @local.send_email_invite
          DIV style: {marginLeft: 20, marginTop: 10},
            AutoGrowTextArea 
              id: 'custom_email_message'
              name: 'custom_email_message'
              placeholder: '(optional) custom message'
              style: {width: '90%', fontSize: 18, padding: '8px 14px'}

      # Submit button
      BUTTON
        style: 
          backgroundColor: focus_color()
          color: 'white'
          padding: '8px 14px'
          fontSize: 16
          display: 'inline-block'
          cursor: 'pointer'
          borderRadius: 8
          marginTop: 12
          border: 'none'

        onClick: (e) => 

          if @local.added.length > 0

            target.roles[@local.role.name] = target.roles[@local.role.name].concat @local.added

            if @local.send_email_invite
              if !target.invitations
                target.invitations = []

              invitation = {role: @local.role.name, keys_or_emails: @local.added}
              invitation.message = $('#custom_email_message').val()              
              target.invitations.push invitation
            
            @local.added = []
            save target
            save @local

        'Done. Add these roles.'


UsersWithRole = ReactiveComponent
  displayName: 'UsersWithRole'

  render : -> 
    target = fetch @props.target
    role = @props.role

    DIV style: {marginLeft: -4},
      
      #####
      # Show the wildcard checkbox, if configured
      # If no wildcard configured, and no one has 
      # the role, state that no one has the role
      if role.wildcard
        DIV null,
          INPUT 
            id: "wildcard-#{role.name}"
            name: "wildcard-#{role.name}"
            type: 'checkbox'
            defaultChecked: target.roles[role.name].indexOf('*') > -1
            onChange: -> 
              if $("#wildcard-#{role.name}").is(':checked')
                target.roles[role.name].push '*'
              else
                target.roles[role.name] = _.without target.roles[role.name], '*'

              save target


          LABEL htmlFor: "wildcard-#{role.name}", role.wildcard.label

      else if !target.roles[role.name] || target.roles[role.name].length == 0
        DIV style: {fontStyle: 'italic', margin: 4}, 'None'
      #########


      if target.roles[role.name]
        for user_key in target.roles[role.name]
          if user_key != '*'

            UserWithRole user_key, (user_key) => 
              target.roles[role.name] = _.without target.roles[role.name], user_key
              if target.invitations
                for invite in target.invitations
                  if invite.role == role.name
                    invite.keys_or_emails = _.without invite.keys_or_emails, user_key
              save target


UserWithRole = (user_key, on_remove_from_role) ->

  SPAN 
    key: user_key
    style:
      display: 'inline-block'
      padding: '6px 12px'
      fontSize: 13
      backgroundColor: '#ddd' #'rgb(217, 227, 244)'
      color: 'black'
      borderRadius: 8
      margin: 4

    SPAN null, 
      if user_key && user_key[0] == '/'
        user = fetch user_key
        SPAN null,
          if user.avatar_file_name
            Avatar 
              key: user_key
              hide_tooltip: true
              style: 
                width: 20
                height: 20
                marginRight: 5
          if user.name 
            user.name 
          else 
            user.email
      else
        user_key

    BUTTON # remove user from role
      'aria-label': "Remove #{user?.name or user_key} from role"
      style: {cursor: 'pointer', marginLeft: 8, border: 'none', 'backgroundColor': 'transparent'}
      onClick: -> on_remove_from_role(user_key) if on_remove_from_role
      'x'


## Export...
window.SubdomainRoles = SubdomainRoles
window.ProposalRoles = ProposalRoles

      