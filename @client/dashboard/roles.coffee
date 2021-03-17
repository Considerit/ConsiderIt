require '../customizations'
require '../form'
require '../shared'



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
    },{
      hide: true,
      name: 'participant', 
      label: 'Participants', 
      description: "", 
      wildcard: 
        label: 'Any registered user who can observe can participate'
        default: true
    },
    {
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
      else if role.name == 'participant'
        proposal.roles[role.name] = subdomain.roles['participant'].slice()
      else
        proposal.roles[role.name].push '*'

  proposal.roles['editor'].push "/user/#{current_user.id}" 
                        #default proposal author as editor




window.styles += """
  .ROLES_label {
    font-size: 20px;
    font-weight: bold;
    margin-bottom: 8px;
    display: block;
  }
"""

SubdomainRoles = ReactiveComponent
  displayName: 'SubdomainRoles'

  render : -> 
    subdomain = fetch '/subdomain'

    roles =  
      admin:
        name: 'admin'
        label: 'Forum Hosts'
        description: 'Can configure everything related to this forum.'
      proposer:
        hide: false
        name: 'proposer'
        label: 'Proposers' 
        description: 'Can add new proposals.'
        wildcard: 
          label: 'Any registered user can post new proposals. Can be overridden on a list-by-list basis.'
          default: true
      participant:
        hide: false
        name: 'participant'
        label: 'Participants'
        description: 'Can participate by dragging opinion sliders and adding pro / con comments to proposals.'
        wildcard: 
          label: 'Any registered user can participate.'
          default: true
      visitor:
        name: 'visitor'
        label: 'People who can access forum'
        description: 'If unchecked, you have a private forum. Invite specific people to join below.'
        wildcard: 
          label: 'Public forum. Anyone with a link can see all proposals.'
          default: true

    # Default roles for a new subdomain are currently hardcoded on the server
    # at subdomain_controller#create

    DIV 
      id: 'ROLES'

      DIV 
        className: 'ROLES_section'

        LABEL
          className: 'ROLES_label'

          'Who are the hosts of this forum?'

        DIV 
          className: 'ROLES_text'
          style: 
            marginBottom: 24

          'Hosts can configure everything related to this forum, and moderate content.'

        UsersWithRole 
          key: 'admin'
          target: subdomain
          role: roles.admin

        AddRolesAndInvite 
          key: 'admin_roles_and_invite'
          target: subdomain
          role: roles.admin
          add_button: 'Add new hosts'

      RadioWildcardRolesSection
        role: roles.proposer
        section_label: 'Who can create new proposals for others to consider?'
        open_label: 'Anyone who registers an account can add new proposals.'
        restricted_label: 'This is a <b>framed forum</b> where only some people can create new proposals, but anyone else can drag opinion sliders and comment on those proposals. Hosts can override this limitation on a list-by-list basis to allow open ideation in specific places.'
        add_button: 'Add new proposers'

      RadioWildcardRolesSection
        role: roles.participant
        section_label: 'Who can participate by dragging opinion sliders and adding pro / con comments to proposals?'
        open_label: 'Anyone who registers an account can give their opinion about the proposals.'
        restricted_label: 'This is a <b>read-only forum</b> where only some people can participate but everyone can see the conversation.'
        add_button: 'Add new participants'

      RadioWildcardRolesSection
        role: roles.visitor
        section_label: 'Who can access this forum?'
        open_label: 'This is an <b>open forum</b> where anyone with the link can access the forum.'
        restricted_label: 'This is a <b>private forum</b> for invited participants only.'
        add_button: 'Add new visitors'
        
window.styles += """
  
  .ROLES_section {
    margin-bottom: 44px;
    position: relative;
  }

  .ROLES_section .ROLES_label {
    margin-bottom: 18px;
    display: block;
  }

  .ROLES_section .radio_group {
    margin-bottom: 30px;    
  }
  .ROLES_section .radio_group label b {
    font-style: italic;
  }


"""

RadioWildcardRolesSection = (opts) ->
  role = opts.role
  subdomain = fetch '/subdomain'

  DIV 
    className: 'ROLES_section'

    LABEL
      className: 'ROLES_label'

      opts.section_label

    DIV 
      className: 'ROLES_text'
      onChange: (e) =>
        if e.target.id == "forum_open_#{role.name}"
          subdomain.roles[role.name] = ['*']
        else 
          subdomain.roles[role.name] = []
        save subdomain

      DIV 
        className: 'radio_group'

        INPUT 
          id: "forum_open_#{role.name}"
          type: 'radio'
          name: "radio_#{role.name}"
          checked: subdomain.roles[role.name].indexOf('*') > -1
        
        LABEL
          htmlFor: "forum_open_#{role.name}"
          dangerouslySetInnerHTML: __html: opts.open_label

      DIV 
        className: 'radio_group'      
        INPUT 
          id: "forum_restricted_#{role.name}"
          type: 'radio'
          name: "radio_#{role.name}"
          checked: subdomain.roles[role.name].indexOf('*') == -1

        LABEL
          htmlFor: "forum_restricted_#{role.name}"
          dangerouslySetInnerHTML: __html: opts.restricted_label

    if subdomain.roles[role.name].indexOf('*') == -1
      [
        UsersWithRole 
          key: 'admin'
          target: subdomain
          role: role

        AddRolesAndInvite 
          key: 'admin_roles_and_invite'
          target: subdomain
          role: role
          add_button: opts.add_button
      ]

# AddRolesAndInvite is the block at the bottom of roles editing that controls
# adding new roles and sending out invites
AddRolesAndInvite = ReactiveComponent
  displayName: 'Invite'

  render: ->
    target = fetch @props.target
    users = fetch '/users'

    @local.added ?= []

    processNewFolks = =>
      $filter = document.getElementById('filter')
      candidates = $filter.value
      if candidates
        candidates = candidates.split(',')
        for candidate_email in candidates
          candidate_email = candidate_email.trim()
          if candidate_email.indexOf(' ') < 0 && 
              candidate_email.indexOf('@') > 0 && 
              candidate_email.indexOf('.') > 0
            @local.added.push candidate_email
        save @local
      $filter.value = ''


    filtered_users = _.filter users.users, (u) => 
                        target.roles[@props.role.name].indexOf(u.key) < 0 && 
                        @local.added.indexOf(u.key) < 0 &&
                         (!@local.filtered || 
                          "#{u.name} <#{u.email}>".indexOf(@local.filtered) > -1)


    DIV 
      style: 
        position: 'relative'
        padding: if @local.expanded then '18px 24px'
        border: if @local.expanded then '1px solid #ccc' else '1px solid transparent'



      if !@local.expanded 
        BUTTON 
          className: 'btn'
          onClick: => 
            @local.expanded = true 
            save @local 

          @props.add_button

      else


        SPAN null, 
          DropMenu
            options: filtered_users
            open_menu_on: 'activation'

            selection_made_callback: (user) =>
              @local.added.push user.key
              processNewFolks()
              @local.filtered = null
              save @local

            render_anchor: (menu_showing) =>
              INPUT 
                id: 'filter'
                type: 'text'
                style: {fontSize: 18, width: 350, padding: '3px 6px'}
                autoComplete: 'off'
                placeholder: "Name or email..."
                
                onChange: => 
                  @local.filtered = document.getElementById('filter').value
                  save @local
                
                onKeyDown: (e) =>
                  # enter key pressed...
                  if e.which == 13
                    e.preventDefault()
                    processNewFolks()

            render_option: (user) ->
              [
                SPAN 
                  style: 
                    fontWeight: 600
                  user.name 

                SPAN
                  style: 
                    opacity: .7
                    paddingLeft: 8

                  user.email  
              ]
   
            wrapper_style: 
              display: 'inline-block'
            menu_style: 
              backgroundColor: '#ddd'
              border: '1px solid #ddd'

            option_style: 
              padding: '4px 12px'
              fontSize: 18
              cursor: 'pointer'
              display: 'block'

            active_option_style:
              backgroundColor: '#eee'

          if @local.filtered && @local.filtered.length > 0 
            BUTTON 
              onClick: => 
                processNewFolks()
              onKeyDown: (e) => 
                if e.which == 13
                  e.target.click()
                  e.preventDefault()

              style: 
                display: 'inline-block'
              '+'





      # Show everyone queued for being added/invited to a role
      if @local.added.length > 0 && @local.expanded
        DIV 
          style:
            marginTop: 18

          for user_key, idx in @local.added

            UserWithRole user_key, (user_key) => 
              @local.added = _.without @local.added, user_key
              save @local


      # Email invite area
      DIV 
        style: 
          marginTop: 20
          display: if !@local.expanded then 'none'
        INPUT 
          type: 'checkbox'
          id: 'send_email_invite'
          name: 'send_email_invite'
          className: 'bigger'
          style: 
            position: 'relative'
            top: 1
            marginRight: 14
          onClick: =>
            @local.send_email_invite = !@local.send_email_invite
            save @local
          onKeyDown: (e) => 
            if e.which == 13 || e.which == 32 # ENTER or SPACE
              e.target.click()
              e.preventDefault()

        LABEL 
          htmlFor: 'send_email_invite'
          'Send email invitation'

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
          display: if !@local.expanded then 'none'
          marginTop: 12

        BUTTON
          className: 'btn'
          style: 
            backgroundColor: focus_color()


          onKeyDown: (e) => 
            if e.which == 13 || e.which == 32 # ENTER or SPACE
              e.target.click()
              e.preventDefault()

          onClick: (e) => 

            if @local.added.length > 0
              role = @props.role.name 
              target.roles[role] = target.roles[role].concat @local.added

              if @local.send_email_invite
                if !target.invitations
                  target.invitations = []

                invitation = {role: role, keys_or_emails: @local.added}
                invitation.message = $('#custom_email_message').val()              
                target.invitations.push invitation
              
              @local.added = []
              save target
              save @local

          @props.add_button


        BUTTON 
          className: 'like_link'
          style: 
            color: '#888'
            marginLeft: 12
            position: 'relative'
            top: 2

          onKeyDown: (e) => 
            if e.which == 13 || e.which == 32 # ENTER or SPACE
              e.target.click()
              e.preventDefault()
          onClick: => 
            @local.expanded = false
            save @local
          'cancel'


UsersWithRole = ReactiveComponent
  displayName: 'UsersWithRole'

  render : -> 
    target = fetch @props.target
    role = @props.role

    DIV 
      style: 
        marginLeft: -4
        marginBottom: 12
      
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

  DIV 
    key: user_key
    style:
      display: 'inline-block'
      padding: '6px 4px 6px 12px'
      fontSize: 13
      backgroundColor: '#ddd' #'rgb(217, 227, 244)'
      color: 'black'
      borderRadius: 8
      margin: 4

    DIV
      style: 
        display: 'inline-block'
      if user_key && user_key[0] == '/'
        user = fetch user_key
        SPAN null,
          if user.avatar_file_name
            Avatar 
              key: user_key
              hide_tooltip: true
              style: 
                width: if user.name then 35 else 20
                height: if user.name then 35 else 20
                marginRight: 12
          DIV 
            style: 
              display: 'inline-block'
            if user.name 
              DIV 
                style: 
                  fontSize: 16
                user.name 
            DIV 
              style: 
                color: if user.name then '#888'
              user.email

      else
        user_key

    BUTTON # remove user from role
      'aria-label': "Remove #{user?.name or user_key} from role"
      style: 
        cursor: 'pointer'
        marginLeft: 8
        border: 'none'
        backgroundColor: 'transparent'
        verticalAlign: 'top'
      onClick: -> on_remove_from_role(user_key) if on_remove_from_role
      'x'


## Export...
window.SubdomainRoles = SubdomainRoles

      