require './customizations'
require './form'
require './shared'


pro_label = customization('point_labels.pro')
con_label = customization('point_labels.con')

all_roles = [ 
  {
    name: 'editor', 
    label: 'Editors', 
    description: 'Can modify the description of the proposal, as well as ' + \
                 'write, comment, and opine.', 
    icon: 'fa-edit', 
    wildcard: 
      label: 'Any registered user who can observe can edit'
      default: false
  },{
    name: 'writer', 
    label: 'Writers', 
    description: "Can write #{pro_label} and #{con_label} points that are " + \
                 "shared with others. Any writer can comment and opine.", 
    icon: 'fa-th-list', 
    wildcard: 
      label: 'Any registered user who can observe can write'
      default: true
  },{
    name: 'commenter', 
    label: 'Commenters', 
    description: "Can comment on #{pro_label} and #{con_label} points.", 
    icon: 'fa-comment', 
    wildcard: 
      label: 'Any registered user who can observe can comment'
      default: true
  },{
    name: 'opiner', 
    label: 'Opiners', 
    description: 'Can drag the slider and build a list of other people\'s Pros/Cons, but can\'t write new Pros, Cons or Comments.'
    icon: 'fa-bar-chart', 
    wildcard: 
      label: 'Any registered user who can observe can opine'
      default: true
  },{
    name: 'observer', 
    label: 'Observers', 
    description: 'Can access this proposal. But that\'s it.', 
    icon: 'fa-eye', 
    wildcard: 
      label: "Public. Anyone can view"
      default: true
  }
]

all_roles = _.compact all_roles


ProposalRoles = ReactiveComponent
  displayName: 'ProposalRoles'

  render : -> 

    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'

    proposal = fetch @props.key


    # initialize default roles for a new proposal
    if !proposal.roles
      InitializeProposalRoles(proposal)

    SpecifyRoles proposal, all_roles

window.InitializeProposalRoles = (proposal) -> 
  current_user = fetch '/current_user'
  subdomain = fetch '/subdomain'

  proposal.roles = {}
  for role in all_roles
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
        description: 'Can configure everything related to this site, including all of the below.', 
        icon: 'fa-wrench'
      }, 
      {
        name: 'moderator', 
        label: 'Moderators', 
        description: 'Can moderate user content. Will receive emails for content needing moderation.', 
        icon: 'fa-fire-extinguisher'
      },
      if subdomain.assessment_enabled then {
        name: 'evaluator', 
        label: 'Fact checkers', 
        description: 'Can validate claims. Will receive emails when a fact-check is requested.', 
        icon: 'fa-flag-checkered'} else null,
      {
        name: 'proposer', 
        label: 'Proposers', 
        description: 'Can add new proposals.', 
        icon: 'fa-lightbulb-o', 
        wildcard: {label: 'Any registered visitor can post new proposals', default: true}},
      {
        name: 'visitor', 
        label: 'Visitors', 
        description: 'Default users who can view proposals.', 
        icon: 'fa-android', 
        wildcard: {label: 'Proposals are public by default.', default: true}} 
    ]

    roles = _.compact roles

    # Default roles for a new subdomain are currently hardcoded on the server
    # at subdomain_controller#create

    DIV null, 
      DashHeader name: 'User Roles'
      DIV style: {width: BODY_WIDTH(), margin: 'auto'},
        SpecifyRoles subdomain, roles


SpecifyRoles = (target, roles) ->  
  DIV null,
    for role,idx in roles
      DIV 
        key: role.name
        style: 
          marginTop: 24

        H1 style: {fontSize: 18, position: 'relative'}, 
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


    DIV 
      style: 
        position: 'relative'
        backgroundColor: '#E7F2FF'
        padding: '18px 24px'
      STYLE null, 
        ".invite_menu_item:hover{background-color: #414141; color: white}"

      # Show (and optionally change) the role currently being modified 
      # by the invite component
      DIV 
        style: 
          fontWeight: 500
          fontSize: 18
          marginBottom: 6
          display: 'inline-block'
        DIV 
          id: 'select_new_role'
          style: 
            backgroundColor: 'rgba(100,100,150,.1)'
            padding: '8px 12px'
            borderRadius: 8
            cursor: 'pointer'
          onClick: =>
            $(document).on 'click.select_new_role', (e) =>
              if e.target.id != 'select_new_role'
                @local.select_new_role = false
                save(@local)
                $(document).off('click.select_new_role')

            @local.select_new_role = true
            save @local 
          I 
            className: "fa #{@local.role.icon}"
            style: 
              displayName: 'inline-block'
              margin: '0 8px 0 0'
          "Add #{@local.role.label}"
          I style: {marginLeft: 8}, className: "fa fa-caret-down"

        if @local.select_new_role
          UL 
            style: 
              width: 500
              position: 'absolute'
              zIndex: 99
              listStyle: 'none'
              backgroundColor: '#fff'
              border: '1px solid #eee'

            for role,idx in @props.roles
              if role.name != @local.role.name
                LI 
                  className: 'invite_menu_item'
                  style: 
                    padding: '2px 12px'
                    fontSize: 18
                    cursor: 'pointer'
                    borderBottom: '1px solid #fafafa'
                  key: idx
                  onClick: do(role) => (e) => 
                    @local.role = role
                    #@local.added = []
                    save @local
                    e.stopPropagation()

                  I 
                    className: "fa #{role.icon}"
                    style: 
                      displayName: 'inline-block'
                      margin: '0 8px 0 0'
                  "Add #{role.label}"

      # Show everyone queued for being added/invited to a role
      if @local.added.length > 0
        DIV null,
          for user_key, idx in @local.added

            UserWithRole user_key, (user_key) => 
              @local.added = _.without @local.added, user_key
              save @local

      # Text input for adding new people to a role
      DIV null,
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
      DIV
        style: 
          backgroundColor: focus_blue
          color: 'white'
          padding: '8px 14px'
          fontSize: 16
          display: 'inline-block'
          cursor: 'pointer'
          borderRadius: 8
          marginTop: 12

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
      backgroundColor: 'rgb(217, 227, 244)'
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

    SPAN # remove user from role
      style: {cursor: 'pointer', marginLeft: 8}
      onClick: -> on_remove_from_role(user_key) if on_remove_from_role
      'x'


## Export...
window.SubdomainRoles = SubdomainRoles
window.ProposalRoles = ProposalRoles

      